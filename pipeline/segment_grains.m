function state = segment_grains(state, varargin)
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
