function save_state(state, filename)
    % save_state: Save AnalysisState to .mat file
    % Input: state (AnalysisState), filename (string)

    if ~endsWith(filename, '.mat')
        filename = [filename, '.mat'];
    end

    save(filename, 'state', '-v7.3');
    fprintf('State saved to: %s\n', filename);
end
