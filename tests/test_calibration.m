function test_calibration()
    % Test calibration function
    addpath(genpath('..'))

    % Test 1: Basic calibration
    state = AnalysisState();
    state.image_raw = uint8(rand(256, 256) * 255);
    state = calibrate_scale(state, 256, 25);

    assert(abs(state.calibration_factor - (25/256)) < 1e-10, 'Factor mismatch');
    assert(state.is_calibrated == true, 'Flag not set');
    assert(state.reference_scale_px == 256, 'Scale px mismatch');
    assert(state.reference_scale_um == 25, 'Scale um mismatch');
    disp('✓ Test 1: Basic calibration passed');

    % Test 2: Negative scale (should error)
    try
        state = calibrate_scale(state, -256, 25);
        error('Should have thrown error for negative scale');
    catch ME
        assert(contains(ME.message, 'positive'), 'Wrong error message');
        disp('✓ Test 2: Negative scale error handled');
    end

    % Test 3: Log is updated
    assert(~isempty(state.processing_log), 'Log not populated');
    assert(contains(state.processing_log{end}, 'Calibrated'), 'Log entry mismatch');
    disp('✓ Test 3: Logging works');

    disp('All calibration tests passed');
end
