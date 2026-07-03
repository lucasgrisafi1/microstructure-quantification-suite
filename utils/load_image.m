function state = load_image(state, filepath)
    % LOAD_IMAGE  Read a micrograph from disk into the analysis state.
    %
    % SYNTAX
    %   state = load_image(state, filepath)
    %
    % INPUTS
    %   state    (AnalysisState) - container to populate.
    %   filepath (char/string)   - absolute or relative path to the image.
    %                              Supported: .tif, .png, .jpg, .bmp, .gif
    %                              (anything imread accepts).
    %
    % OUTPUTS
    %   state - image_raw (uint8 or uint16 grayscale), image_filename
    %           populated; processing_log appended.
    %
    % EXAMPLE
    %   state = load_image(state, 'tests/sample_doitpoms.jpg');
    %
    % NOTES
    %   - RGB inputs are automatically converted to grayscale (rgb2gray).
    %   - Errors if the file does not exist.
    %
    % See also: calibrate_scale.

    if ~isfile(filepath)
        error('File not found: %s', filepath);
    end

    % Read image (second output = colormap for indexed formats, e.g. GIF)
    [img, cmap] = imread(filepath);

    % Indexed image (GIF/indexed PNG): map palette indices through the
    % colormap, then convert to grayscale. Without this, raw palette
    % indices would be misread as intensities.
    if ~isempty(cmap)
        g = 0.2989 * cmap(:,1) + 0.5870 * cmap(:,2) + 0.1140 * cmap(:,3);
        img = uint8(255 * g(double(img) + 1));
    end

    % Convert to grayscale if needed
    if size(img, 3) == 3
        img = rgb2gray(img);
    end

    % Ensure uint8 or uint16 with proper intensity scaling.
    % NOTE: plain uint8() on a double image in [0,1] would truncate
    % everything to 0/1 — rescale instead.
    if ~isa(img, 'uint8') && ~isa(img, 'uint16')
        img = uint8(255 * mat2gray(double(img)));
    end

    % Populate state
    state.image_raw = img;
    [~, name, ext] = fileparts(filepath);
    state.image_filename = [name, ext];

    % Log
    state.processing_log{end+1} = sprintf('[%s] Loaded image: %s', ...
        datetime('now', 'Format', 'HH:mm:ss'), state.image_filename);
end
