function state = analyze_morphology(state, varargin)
    % ANALYZE_MORPHOLOGY  Per-grain measurements + ensemble statistics.
    %
    % SYNTAX
    %   state = analyze_morphology(state)
    %   state = analyze_morphology(state, 'ExcludeBorder', false)
    %
    % INPUTS
    %   state - AnalysisState with segmentation_mask populated AND
    %           is_calibrated == true (calibration_factor used for unit
    %           conversion).
    %
    % NAME-VALUE OPTIONS
    %   'ExcludeBorder' - true (default). Grains clipped by the image edge
    %                     have truncated areas; including them biases the
    %                     size distribution downward. They are excluded from
    %                     per-grain stats but counted at half weight in the
    %                     ASTM density (Jeffries method, ASTM E112).
    %
    % OUTPUTS
    %   state.grain_properties (table) one row per interior grain:
    %     grain_id, area_pixels, area_um2, eccentricity, orientation,
    %     equivalent_diameter, major_axis_um, minor_axis_um, aspect_ratio.
    %   state.morphology_stats (struct):
    %     grain_count, border_grain_count, D10, D50, D90,
    %     mean/std eccentricity, mean/std orientation (axial circular stats),
    %     orientation_alignment (0=random, 1=perfectly aligned),
    %     mean_area_um2, total_area_um2, astm_grain_size_G.
    %   processing_log appended.
    %
    % NOTES
    %   - Orientation is AXIAL data on [-90, 90] deg (a grain at +89 deg is
    %     nearly identical to one at -89 deg). Arithmetic mean/std are
    %     meaningless for such data, so circular statistics on doubled
    %     angles are used instead.
    %   - ASTM G (planimetric/Jeffries): N_A = (N_interior + N_border/2)/A,
    %     A in mm^2; G = 3.321928*log10(N_A) - 2.954.
    %
    % See also: segment_grains, generate_publication_figure.

    if isempty(state.segmentation_mask)
        error('segmentation_mask is empty. Segment grains first.');
    end
    if ~state.is_calibrated
        error('Not calibrated. Call calibrate_scale first.');
    end

    exclude_border = true;
    for k = 1:2:numel(varargin)
        if strcmpi(varargin{k}, 'ExcludeBorder')
            exclude_border = logical(varargin{k+1});
        else
            error('Unknown option ''%s''.', char(varargin{k}));
        end
    end

    mask = state.segmentation_mask;
    L = bwlabel(mask);
    n_total = max(L(:));
    if n_total == 0
        error('No regions found in segmentation mask. Check segmentation.');
    end

    % ---- Identify grains touching the image border ----
    border_labels = unique([L(1, :), L(end, :), L(:, 1)', L(:, end)']);
    border_labels = border_labels(border_labels > 0);
    n_border = numel(border_labels);

    if exclude_border && n_border > 0 && n_border < n_total
        interior = L;
        interior(ismember(L, border_labels)) = 0;
        regions = regionprops(logical(interior), ...
            'Area', 'Eccentricity', 'Orientation', 'MajorAxisLength', 'MinorAxisLength');
    else
        if exclude_border && n_border >= n_total
            warning('All %d grains touch the border; keeping them all.', n_total);
            n_border = 0;
        end
        regions = regionprops(mask, ...
            'Area', 'Eccentricity', 'Orientation', 'MajorAxisLength', 'MinorAxisLength');
    end

    n_grains = length(regions);
    cf = state.calibration_factor;   % um/px

    grain_table = table();
    grain_table.grain_id = (1:n_grains)';
    grain_table.area_pixels = [regions.Area]';
    grain_table.area_um2 = grain_table.area_pixels * cf^2;
    grain_table.eccentricity = [regions.Eccentricity]';
    grain_table.orientation = [regions.Orientation]';
    grain_table.equivalent_diameter = 2 * sqrt(grain_table.area_um2 / pi);
    grain_table.major_axis_um = [regions.MajorAxisLength]' * cf;
    grain_table.minor_axis_um = [regions.MinorAxisLength]' * cf;
    grain_table.aspect_ratio = grain_table.major_axis_um ./ ...
        max(grain_table.minor_axis_um, eps);

    % ---- Axial circular statistics for orientation ----
    % Double the angles to map the +/-90 deg axial wrap onto a full circle.
    theta2 = deg2rad(2 * grain_table.orientation);
    C = mean(cos(theta2));  S = mean(sin(theta2));
    R = sqrt(C^2 + S^2);                          % resultant length (alignment)
    mean_orient = rad2deg(atan2(S, C)) / 2;       % axial circular mean, [-90, 90]
    circ_std = rad2deg(sqrt(max(-2 * log(max(R, eps)), 0))) / 2;

    stats = struct();
    stats.grain_count = n_grains;
    stats.border_grain_count = n_border;
    stats.D10 = prctile(grain_table.equivalent_diameter, 10);
    stats.D50 = prctile(grain_table.equivalent_diameter, 50);
    stats.D90 = prctile(grain_table.equivalent_diameter, 90);
    stats.mean_eccentricity = mean(grain_table.eccentricity);
    stats.std_eccentricity = std(grain_table.eccentricity);
    stats.mean_orientation = mean_orient;
    stats.std_orientation = circ_std;
    stats.orientation_alignment = R;
    stats.mean_area_um2 = mean(grain_table.area_um2);
    stats.total_area_um2 = sum(grain_table.area_um2);

    % ---- ASTM E112 grain size number (Jeffries planimetric) ----
    image_area_mm2 = numel(mask) * (cf * 1e-3)^2;
    if exclude_border
        N_A = (n_grains + 0.5 * n_border) / image_area_mm2;   % interior + half border
    else
        N_A = (n_grains - 0.5 * n_border) / image_area_mm2;   % table already includes border grains
    end
    stats.astm_grain_size_G = 3.321928 * log10(N_A) - 2.954;

    state.grain_properties = grain_table;
    state.morphology_stats = stats;

    state.processing_log{end+1} = sprintf(...
        '[%s] Analyzed: %d grains (%d border excluded), D50=%.2f um, ASTM G=%.1f', ...
        datetime('now', 'Format', 'HH:mm:ss'), n_grains, n_border, ...
        stats.D50, stats.astm_grain_size_G);
end
