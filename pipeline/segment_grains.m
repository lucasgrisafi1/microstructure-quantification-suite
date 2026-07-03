function state = segment_grains(state, varargin)
    % SEGMENT_GRAINS  Threshold + morphological cleanup to produce a grain mask.
    %
    % SYNTAX
    %   state = segment_grains(state)                   % Otsu's method
    %   state = segment_grains(state, 'otsu')           % explicit Otsu
    %   state = segment_grains(state, threshold)        % manual threshold [0,1]
    %   state = segment_grains(state, method, 'Name', value, ...)
    %
    % INPUTS
    %   state            (AnalysisState) - must have image_processed populated.
    %   threshold_method (optional) - 'otsu' (default) OR a scalar in [0, 1]
    %                                 to override Otsu's choice (higher =
    %                                 stricter, fewer pixels become foreground).
    %
    % NAME-VALUE OPTIONS
    %   'Polarity'  - 'auto' (default) | 'bright' | 'dark'. Whether grains are
    %                 brighter or darker than the boundaries. 'auto' inverts
    %                 the mask when the foreground fraction is < 0.35 (grains
    %                 are normally the majority phase; thin boundaries the
    %                 minority). Without this, dark-grain micrographs silently
    %                 measured the BOUNDARY network instead of the grains.
    %   'Watershed' - true (default) | false. Distance-transform watershed to
    %                 split touching grains (only runs when the Image
    %                 Processing Toolbox functions exist; logged either way).
    %                 Without it, contacting grains merge into one region and
    %                 D50/D90 are overestimated.
    %   'MinArea'   - minimum object size in px (default 50).
    %
    % OUTPUTS
    %   state - segmentation_mask (logical, same size as image_processed),
    %           segmentation_params populated; processing_log appended.
    %
    % EXAMPLE
    %   state = segment_grains(state);                        % auto everything
    %   state = segment_grains(state, 0.7, 'Polarity', 'dark');
    %
    % See also: preprocess_image, analyze_morphology.

    if isempty(state.image_processed)
        error('image_processed is empty. Preprocess image first.');
    end

    img = state.image_processed;

    % ---- Parse arguments ----
    threshold_method = 'otsu';
    opts = struct('Polarity', 'auto', 'Watershed', true, 'MinArea', 50);
    args = varargin;
    if ~isempty(args)
        a1 = args{1};
        if isnumeric(a1) || ...
                ((ischar(a1) || isstring(a1)) && ~isfield(opts, char(a1)))
            threshold_method = a1;
            args(1) = [];
        end
    end
    for k = 1:2:numel(args)
        name = char(args{k});
        if ~isfield(opts, name)
            error('Unknown option ''%s''.', name);
        end
        opts.(name) = args{k+1};
    end

    % ---- Threshold (validated) ----
    if (ischar(threshold_method) || isstring(threshold_method))
        if ~strcmpi(char(threshold_method), 'otsu')
            error('Unknown threshold method ''%s''. Use ''otsu'' or a scalar in [0,1].', ...
                char(threshold_method));
        end
        threshold = graythresh(img);
    else
        if ~isscalar(threshold_method) || ~isreal(threshold_method) || ...
                threshold_method < 0 || threshold_method > 1
            error('Manual threshold must be a real scalar in [0, 1].');
        end
        threshold = double(threshold_method);
    end

    % Scale threshold to the image's actual dynamic range (was hardcoded
    % *255, which silently broke uint16 input).
    maxval = double(intmax(class(img)));
    mask = double(img) > (threshold * maxval);

    % ---- Polarity ----
    polarity = lower(char(opts.Polarity));
    inverted = false;
    switch polarity
        case 'bright'
            % keep as-is
        case 'dark'
            mask = ~mask;
            inverted = true;
        case 'auto'
            if mean(mask(:)) < 0.35
                mask = ~mask;
                inverted = true;
            end
        otherwise
            error('Polarity must be ''auto'', ''bright'', or ''dark''.');
    end

    % ---- Morphological cleanup ----
    min_area = opts.MinArea;
    mask = bwareaopen(mask, min_area);
    mask = imfill(mask, 'holes');
    se = strel('disk', 2);
    mask = imopen(mask, se);
    mask = imclose(mask, se);
    mask = logical(mask);

    % ---- Watershed separation of touching grains ----
    watershed_applied = false;
    if opts.Watershed && exist('watershed', 'file') && ...
            exist('bwdist', 'file') && exist('imhmin', 'file')
        D = -bwdist(~mask);
        D = imhmin(D, 2);        % suppress shallow minima -> less over-segmentation
        D(~mask) = Inf;
        L = watershed(D);
        mask(L == 0) = false;    % cut along ridge lines
        mask = bwareaopen(mask, min_area);
        watershed_applied = true;
    end

    state.segmentation_mask = mask;
    state.segmentation_params = struct(...
        'threshold_method', threshold_method, ...
        'threshold_value', threshold, ...
        'small_object_threshold', min_area, ...
        'polarity', polarity, ...
        'polarity_inverted', inverted, ...
        'watershed_applied', watershed_applied);

    state.processing_log{end+1} = sprintf(...
        '[%s] Segmented: threshold=%.3f, inverted=%d, watershed=%d', ...
        datetime('now', 'Format', 'HH:mm:ss'), threshold, inverted, watershed_applied);
end
