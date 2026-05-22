function save_state(state, filename)
    % SAVE_STATE  Serialize an AnalysisState to a .mat file.
    %
    % SYNTAX
    %   save_state(state, filename)
    %
    % INPUTS
    %   state    (AnalysisState) - container to serialize.
    %   filename (char/string)   - target path; '.mat' appended if missing.
    %
    % NOTES
    %   - Saved with -v7.3 (HDF5) so large arrays serialize correctly.
    %   - AnalysisState.saveobj strips figure_handles and figure_image
    %     before writing (handles are non-portable).
    %
    % See also: load_state.

    if ~endsWith(filename, '.mat')
        filename = [filename, '.mat'];
    end

    save(filename, 'state', '-v7.3');
    fprintf('State saved to: %s\n', filename);
end
