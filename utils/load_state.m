function state = load_state(filename)
    % load_state: Load AnalysisState from .mat file
    % Input: filename (string)
    % Output: state (AnalysisState)

    if ~isfile(filename)
        error('File not found: %s', filename);
    end

    if ~endsWith(filename, '.mat')
        filename = [filename, '.mat'];
    end

    loaded = load(filename);
    state = loaded.state;
    fprintf('State loaded from: %s\n', filename);
end
