function state = load_state(filename)
    % LOAD_STATE  Deserialize an AnalysisState from a .mat file.
    %
    % SYNTAX
    %   state = load_state(filename)
    %
    % INPUTS
    %   filename (char/string) - path to a .mat file produced by save_state.
    %                            '.mat' appended if missing.
    %
    % OUTPUTS
    %   state - the AnalysisState that was serialized. figure_handles and
    %           figure_image will be empty (stripped at save time);
    %           regenerate with generate_publication_figure if needed.
    %
    % EXAMPLE
    %   state = load_state('output/sample_state.mat');
    %   disp(state.morphology_stats)
    %
    % See also: save_state, generate_publication_figure.

    % Append extension BEFORE the existence check, otherwise a filename
    % passed without '.mat' always errors even when the file exists.
    if ~endsWith(filename, '.mat')
        filename = [filename, '.mat'];
    end

    if ~isfile(filename)
        error('File not found: %s', filename);
    end

    loaded = load(filename);
    state = loaded.state;
    fprintf('State loaded from: %s\n', filename);
end
