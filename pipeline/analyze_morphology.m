function state = analyze_morphology(state)
    % ANALYZE_MORPHOLOGY  Per-grain measurements + ensemble statistics.
    %
    % SYNTAX
    %   state = analyze_morphology(state)
    %
    % INPUTS
    %   state - AnalysisState with segmentation_mask populated AND
    %           is_calibrated == true (calibration_factor used for unit
    %           conversion).
    %
    % OUTPUTS
    %   state.grain_properties (table) one row per connected component:
    %     grain_id, area_pixels, area_um2, eccentricity, orientation,
    %     equivalent_diameter, major_axis_um, minor_axis_um.
    %   state.morphology_stats (struct) ensemble metrics:
    %     grain_count, D10, D50, D90 (equivalent-diameter percentiles),
    %     mean/std eccentricity, mean/std orientation,
    %     mean_area_um2, total_area_um2.
    %   processing_log appended.
    %
    % EXAMPLE
    %   state = analyze_morphology(state);
    %   disp(state.morphology_stats)
    %   head(state.grain_properties, 5)
    %
    % NOTES
    %   - Underlying region properties come from regionprops:
    %     Area, Eccentricity, Orientation, MajorAxisLength, MinorAxisLength.
    %   - Equivalent diameter = 2 * sqrt(area_um2 / pi).
    %   - Errors if segmentation_mask is empty or calibration is missing.
    %
    % See also: segment_grains, generate_publication_figure.

    if isempty(state.segmentation_mask)
        error('segmentation_mask is empty. Segment grains first.');
    end
    
    if ~state.is_calibrated
        error('Not calibrated. Call calibrate_scale first.');
    end
    
    regions = regionprops(state.segmentation_mask, ...
        'Area', 'Eccentricity', 'Orientation', 'MajorAxisLength', 'MinorAxisLength');
    
    if isempty(regions)
        error('No regions found in segmentation mask. Check segmentation.');
    end
    
    n_grains = length(regions);
    grain_table = table();
    
    grain_table.grain_id = (1:n_grains)';
    grain_table.area_pixels = [regions.Area]';
    grain_table.area_um2 = grain_table.area_pixels * (state.calibration_factor^2);
    grain_table.eccentricity = [regions.Eccentricity]';
    grain_table.orientation = [regions.Orientation]';
    grain_table.equivalent_diameter = 2 * sqrt(grain_table.area_um2 / pi);
    grain_table.major_axis_um = [regions.MajorAxisLength]' * state.calibration_factor;
    grain_table.minor_axis_um = [regions.MinorAxisLength]' * state.calibration_factor;
    
    stats = struct();
    stats.grain_count = n_grains;
    stats.D10 = prctile(grain_table.equivalent_diameter, 10);
    stats.D50 = prctile(grain_table.equivalent_diameter, 50);
    stats.D90 = prctile(grain_table.equivalent_diameter, 90);
    stats.mean_eccentricity = mean(grain_table.eccentricity);
    stats.std_eccentricity = std(grain_table.eccentricity);
    stats.mean_orientation = mean(grain_table.orientation);
    stats.std_orientation = std(grain_table.orientation);
    stats.mean_area_um2 = mean(grain_table.area_um2);
    stats.total_area_um2 = sum(grain_table.area_um2);
    
    state.grain_properties = grain_table;
    state.morphology_stats = stats;
    
    state.processing_log{end+1} = sprintf('[%s] Analyzed: %d grains, D50=%.2f um', ...
        datetime('now', 'Format', 'HH:mm:ss'), stats.grain_count, stats.D50);
end
