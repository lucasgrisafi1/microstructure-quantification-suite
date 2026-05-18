function test_morphology()
    addpath(genpath('..'))
    
    state = AnalysisState();
    state.is_calibrated = true;
    state.calibration_factor = 0.01;
    
    mask = false(256, 256);
    mask(50:100, 50:100) = true;
    mask(150:200, 150:200) = true;
    state.segmentation_mask = mask;
    
    state = analyze_morphology(state);
    
    assert(isfield(state.morphology_stats, 'grain_count'), 'Missing grain_count');
    assert(isfield(state.morphology_stats, 'D50'), 'Missing D50');
    assert(state.morphology_stats.grain_count == 2, 'Grain count mismatch');
    disp('✓ Test 1: Basic morphology analysis passed');
    
    assert(height(state.grain_properties) == 2, 'Grain table size mismatch');
    assert(all(state.grain_properties.area_pixels > 0), 'Invalid area values');
    disp('✓ Test 2: Grain properties table check passed');
    
    D10 = state.morphology_stats.D10;
    D50 = state.morphology_stats.D50;
    D90 = state.morphology_stats.D90;
    assert(D10 <= D50 && D50 <= D90, 'D10/D50/D90 ordering violated');
    disp('✓ Test 3: Percentile ordering check passed');
    
    assert(~isempty(state.processing_log), 'Log not populated');
    disp('✓ Test 4: Logging works');
    
    disp('All morphology tests passed');
end
