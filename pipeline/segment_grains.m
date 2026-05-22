function state = segment_grains(state, varargin)
    % SEGMENT_GRAINS  Threshold + morphological cleanup to produce a grain mask.
    %
    % SYNTAX
    %   state = segment_grains(state)                   % Otsu's method
    %   state = segment_grains(state, 'otsu')           % explicit Otsu
    %   state = segment_grains(state, threshold)        % manual threshold [0,1]
    %
    % INPUTS
    %   state            (AnalysisState) - must have image_processed populated.
    %   threshold_method (optional) - 'otsu' (default) OR a scalar in [0, 1]
    %                                 to override Otsu's choice (higher =
    %                                 stricter, fewer pixels become foreground).
    %
    % OUTPUTS
    %   state - segmentation_mask (logical, same size as image_processed),
    %           segmentation_params (threshold_method, threshold_value,
    %           small_object_threshold) populated; processing_log appended.
    %
    % EXAMPLE
    %   state = segment_grains(state);          % automatic Otsu
    %   state = segment_grains(state, 0.7);     % manual threshold
    %
    % NOTES
    %   Morphological pipeline applied after thresholding:
    %     1. bwareaopen(mask, 50)   remove components smaller than 50 px
    %     2. imfill(mask, 'holes')  fill enclosed background regions
    %     3. imopen / imclose with disk(2)  smooth boundaries
    %   To kill more noise specks, edit the bwareaopen value below.
    %
    % See also: preprocess_image, analyze_morphology.

    if isempty(state.image_processed)
        error('image_processed is empty. Preprocess image first.');
    end
    
    img = state.image_processed;
    threshold_method = 'otsu';
    if ~isempty(varargin)
        threshold_method = varargin{1};
    end
    
    if strcmp(threshold_method, 'otsu')
        threshold = graythresh(img);
    else
        threshold = threshold_method;
    end
    
    mask = img > (threshold * 255);
    mask = bwareaopen(mask, 50);
    mask = imfill(mask, 'holes');
    se = strel('disk', 2);
    mask = imopen(mask, se);
    mask = imclose(mask, se);
    mask = logical(mask);
    
    state.segmentation_mask = mask;
    state.segmentation_params = struct(...
        'threshold_method', threshold_method, ...
        'threshold_value', threshold, ...
        'small_object_threshold', 50);
    
    state.processing_log{end+1} = sprintf('[%s] Segmented: threshold=%.3f', ...
        datetime('now', 'Format', 'HH:mm:ss'), threshold);
end
