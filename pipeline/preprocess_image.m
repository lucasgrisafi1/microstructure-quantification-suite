function state = preprocess_image(state, varargin)
    % PREPROCESS_IMAGE  Enhance contrast prior to segmentation.
    %
    % SYNTAX
    %   state = preprocess_image(state)
    %   state = preprocess_image(state, method)
    %
    % INPUTS
    %   state   (AnalysisState) - must have image_raw populated.
    %   method  (char, optional) - 'auto' (default), 'clahe', or 'stretch'.
    %           'auto' selects from image statistics (see Notes); the other
    %           two force the corresponding method.
    %
    % OUTPUTS
    %   state - image_processed (uint8), preprocessing_method,
    %           preprocessing_params populated; processing_log appended.
    %
    % EXAMPLE
    %   state = preprocess_image(state);
    %   imshow(state.image_processed);
    %
    % NOTES
    %   Branch heuristic: coefficient-of-variation squared on image_raw.
    %     high variance (> 0.1)  -> SEM-like      -> CLAHE (adapthisteq)
    %     low  variance (<= 0.1) -> optical-like  -> 2%/98% contrast stretch
    %                                                + light Gaussian blur
    %   RGB inputs are converted to grayscale via rgb2gray.
    %
    % See also: calibrate_scale, segment_grains.

    if isempty(state.image_raw)
        error('image_raw is empty. Load image first.');
    end

    % Parse optional method argument (previously accepted but silently
    % ignored — the auto heuristic always won; now honored)
    requested = 'auto';
    if ~isempty(varargin)
        requested = lower(char(varargin{1}));
    end
    if ~ismember(requested, {'auto', 'clahe', 'stretch'})
        error('Unknown method ''%s''. Use ''auto'', ''clahe'', or ''stretch''.', requested);
    end

    % Convert to grayscale if not already
    img = state.image_raw;
    if size(img, 3) == 3
        img = rgb2gray(img);
    end

    % Detect image type (simple heuristic based on variance)
    var_norm = var(double(img(:))) / (mean(double(img(:)))^2);  % Coefficient of variation squared

    use_clahe = strcmp(requested, 'clahe') || ...
        (strcmp(requested, 'auto') && var_norm > 0.1);

    % Apply preprocessing
    if use_clahe  % SEM-like (high variance) or forced
        % CLAHE (Contrast Limited Adaptive Histogram Equalization)
        img_processed = adapthisteq(img, 'ClipLimit', 0.03, 'NumTiles', [8 8]);
        method = 'adaptive_histogram_eq (SEM)';
    else  % Likely optical microscopy
        % Standard contrast stretching
        img_double = double(img);
        p2 = prctile(img_double(:), 2);
        p98 = prctile(img_double(:), 98);
        img_processed = uint8(255 * (img_double - p2) / (p98 - p2 + eps));
        img_processed = imgaussfilt(img_processed, 1);  % Light Gaussian blur
        method = 'contrast_stretch + blur (optical)';
    end

    % Store results
    state.image_processed = img_processed;
    state.preprocessing_method = method;
    state.preprocessing_params = struct('method', method);

    % Log
    state.processing_log{end+1} = sprintf('[%s] Preprocessed: %s', ...
        datetime('now', 'Format', 'HH:mm:ss'), method);
end
