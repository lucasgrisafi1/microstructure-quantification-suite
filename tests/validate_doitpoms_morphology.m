function validate_doitpoms_morphology()
    addpath(genpath('..'))
    
    % Load or create synthetic DoITPoMS sample
    img_path = fullfile(pwd, 'sample_doitpoms.tif');
    
    if ~isfile(img_path)
        % Create synthetic image if not found
        fprintf('Creating synthetic DoITPoMS sample...\n');
        create_synthetic_doitpoms();
    end
    
    % Run full pipeline
    fprintf('Loading image...\n');
    state = AnalysisState();
    state = load_image(state, img_path);
    
    fprintf('Calibrating scale...\n');
    state = calibrate_scale(state, 256, 1.28);
    
    fprintf('Preprocessing image...\n');
    state = preprocess_image(state);
    
    fprintf('Segmenting grains...\n');
    state = segment_grains(state);
    
    fprintf('Analyzing morphology...\n');
    state = analyze_morphology(state);
    
    % Display results
    fprintf('\n=== Morphology Analysis Results ===\n');
    fprintf('Grain count: %d\n', state.morphology_stats.grain_count);
    fprintf('D10: %.2f um\n', state.morphology_stats.D10);
    fprintf('D50: %.2f um\n', state.morphology_stats.D50);
    fprintf('D90: %.2f um\n', state.morphology_stats.D90);
    fprintf('Mean eccentricity: %.3f\n', state.morphology_stats.mean_eccentricity);
    fprintf('Mean orientation: %.2f degrees\n', state.morphology_stats.mean_orientation);
    fprintf('Mean area: %.2f um^2\n', state.morphology_stats.mean_area_um2);
    fprintf('Total area: %.2f um^2\n', state.morphology_stats.total_area_um2);
    fprintf('=====================================\n\n');
    
    % Save checkpoint
    checkpoint_path = fullfile(pwd, '..', 'output', 'checkpoint_doitpoms_complete.mat');
    fprintf('Saving checkpoint to: %s\n', checkpoint_path);
    save_state(state, checkpoint_path);
    
    fprintf('Validation complete!\n');
end

validate_doitpoms_morphology();
