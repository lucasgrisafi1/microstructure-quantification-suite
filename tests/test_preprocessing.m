function test_preprocessing()
    % Test preprocessing function
    addpath(genpath('..'))

    % Test 1: Preprocess high-variance image (SEM-like)
    state = AnalysisState();
    state.image_raw = uint8(rand(256, 256) * 255);  % High variance
    state.is_calibrated = true;

    state = preprocess_image(state);

    assert(~isempty(state.image_processed), 'image_processed is empty');
    assert(isequal(size(state.image_processed), size(state.image_raw)), 'Size mismatch');
    assert(isa(state.image_processed, 'uint8'), 'Output should be uint8');
    disp('✓ Test 1: High-variance preprocessing passed');

    % Test 2: Preprocess low-variance image (optical-like)
    state2 = AnalysisState();
    img_low_var = uint8(ones(256, 256) * 128 + randn(256, 256) * 5);  % Low variance
    state2.image_raw = img_low_var;

    state2 = preprocess_image(state2);

    assert(~isempty(state2.image_processed), 'image_processed is empty');
    assert(contains(state2.preprocessing_method, 'contrast_stretch'), 'Wrong method detected');
    disp('✓ Test 2: Low-variance preprocessing passed');

    % Test 3: Preprocessed image should be uint8
    assert(isa(state.image_processed, 'uint8'), 'Output should be uint8');
    disp('✓ Test 3: Output type check passed');

    % Test 4: Log is updated
    assert(~isempty(state.processing_log), 'Log not populated');
    disp('✓ Test 4: Logging works');

    disp('All preprocessing tests passed');
end
