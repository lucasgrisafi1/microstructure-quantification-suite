function state = generate_publication_figure(state)
    % generate_publication_figure: Create 4-panel publication figure.
    %
    % Panels:
    %   (A) Raw image
    %   (B) Preprocessed image
    %   (C) Segmentation overlay (preprocessed image + boundary tint)
    %   (D) Labeled grains (label2rgb) + stats annotation
    %
    % Input:
    %   state - AnalysisState with image_raw, image_processed,
    %           segmentation_mask, and morphology_stats populated.
    % Output:
    %   state - With figure_handles (struct of figure + axes) and
    %           figure_image (RGB uint8 array from getframe) populated;
    %           processing_log appended.

    % ---- Validate pipeline completeness ----
    if isempty(state.image_raw)
        error('generate_publication_figure:no_raw', ...
            'image_raw is empty. Run load_image() first.');
    end
    if isempty(state.image_processed)
        error('generate_publication_figure:no_processed', ...
            'image_processed is empty. Run preprocess_image() first.');
    end
    if isempty(state.segmentation_mask)
        error('generate_publication_figure:no_mask', ...
            'segmentation_mask is empty. Run segment_grains() first.');
    end
    if isempty(state.morphology_stats) || ...
       isempty(state.morphology_stats.grain_count)
        error('generate_publication_figure:no_morphology', ...
            'morphology_stats is empty. Run analyze_morphology() first.');
    end

    % ---- Create figure (hidden during construction) ----
    fig = figure('Position', [100 100 1200 900], 'Visible', 'off', ...
        'Color', 'white', 'Name', 'Microstructure Analysis');

    % ===== Panel A: Raw image =====
    ax1 = subplot(2, 2, 1);
    imshow(state.image_raw, 'Parent', ax1);
    title(ax1, '(A) Raw Image', 'FontSize', 12, 'FontWeight', 'bold');
    if ~isempty(state.image_filename)
        xlabel(ax1, ['File: ', state.image_filename], ...
            'Interpreter', 'none', 'FontSize', 9);
    end

    % ===== Panel B: Preprocessed image =====
    ax2 = subplot(2, 2, 2);
    imshow(state.image_processed, 'Parent', ax2);
    method_str = state.preprocessing_method;
    if isempty(method_str)
        method_str = 'unspecified';
    end
    title(ax2, sprintf('(B) Preprocessed (%s)', method_str), ...
        'FontSize', 12, 'FontWeight', 'bold', 'Interpreter', 'none');

    % ===== Panel C: Segmentation overlay =====
    ax3 = subplot(2, 2, 3);
    img_gray = state.image_processed;
    if ~isa(img_gray, 'uint8')
        img_gray = im2uint8(mat2gray(img_gray));
    end
    boundary_tint = uint8(255 * ~state.segmentation_mask);
    img_overlay = cat(3, img_gray, img_gray, boundary_tint);
    imshow(img_overlay, 'Parent', ax3);
    title(ax3, sprintf('(C) Segmentation (n=%d grains)', ...
        state.morphology_stats.grain_count), ...
        'FontSize', 12, 'FontWeight', 'bold');

    % ===== Panel D: Labeled grains =====
    ax4 = subplot(2, 2, 4);
    labeled = bwlabel(state.segmentation_mask);
    labeled_color = label2rgb(labeled, 'hsv', 'k', 'shuffle');
    imshow(labeled_color, 'Parent', ax4);
    title(ax4, '(D) Labeled Grains', 'FontSize', 12, 'FontWeight', 'bold');

    % ---- Stats annotation (bottom-right of figure) ----
    stats = state.morphology_stats;
    stats_text = sprintf([ ...
        'Grain count: %d\n' ...
        'D10 = %.2f \\mum\n' ...
        'D50 = %.2f \\mum\n' ...
        'D90 = %.2f \\mum\n' ...
        'Eccentricity: %.2f \\pm %.2f\n' ...
        'Orientation: %.1f \\pm %.1f deg'], ...
        stats.grain_count, ...
        stats.D10, stats.D50, stats.D90, ...
        stats.mean_eccentricity, stats.std_eccentricity, ...
        stats.mean_orientation, stats.std_orientation);

    annotation(fig, 'textbox', [0.66 0.05 0.30 0.13], ...
        'String', stats_text, ...
        'FontSize', 10, ...
        'BackgroundColor', 'white', ...
        'EdgeColor', 'black', ...
        'FitBoxToText', 'on', ...
        'Interpreter', 'tex');

    % ---- Store handles + render to image ----
    state.figure_handles = struct( ...
        'fig', fig, 'ax1', ax1, 'ax2', ax2, 'ax3', ax3, 'ax4', ax4);

    drawnow;
    frame = getframe(fig);
    state.figure_image = frame.cdata;

    set(fig, 'Visible', 'on');

    % ---- Log ----
    state.processing_log{end+1} = sprintf( ...
        '[%s] Generated 4-panel publication figure (n=%d grains)', ...
        datetime('now', 'Format', 'HH:mm:ss'), stats.grain_count);
end
