function state = preprocess_image(state, varargin)
    % preprocess_image: Enhance contrast for grain boundary detection
    % Input: state (AnalysisState with image_processed), optional method ('adaptive_histogram_eq' or 'contrast_stretch')
    % Output: state with image_processed populated

    if isempty(state.image_raw)
        error('image_raw is empty. Load image first.');
    end

    % Parse optional method argument
    method = 'adaptive_histogram_eq';  % Default
    if ~isempty(varargin)
        method = varargin{1};
    end

    % Convert to grayscale if not already
    img = state.image_raw;
    if size(img, 3) == 3
        img = rgb2gray(img);
    end

    % Detect image type (simple heuristic based on variance)
    var_norm = var(double(img(:))) / (mean(double(img(:)))^2);  % Coefficient of variation squared

    % Apply preprocessing
    if var_norm > 0.1  % Likely SEM (high variance)
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
