function state = load_image(state, filepath)
    % load_image: Read image from file and populate state
    % Input: state (AnalysisState), filepath (string)
    % Output: state with image_raw and image_filename populated

    if ~isfile(filepath)
        error('File not found: %s', filepath);
    end

    % Read image
    img = imread(filepath);

    % Convert to grayscale if needed
    if size(img, 3) == 3
        img = rgb2gray(img);
    end

    % Ensure uint8 or uint16
    if ~isa(img, 'uint8') && ~isa(img, 'uint16')
        img = uint8(img);
    end

    % Populate state
    state.image_raw = img;
    [~, name, ext] = fileparts(filepath);
    state.image_filename = [name, ext];

    % Log
    state.processing_log{end+1} = sprintf('[%s] Loaded image: %s', ...
        datetime('now', 'Format', 'HH:mm:ss'), state.image_filename);
end
