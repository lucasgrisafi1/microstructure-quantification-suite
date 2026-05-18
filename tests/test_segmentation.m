function test_segmentation()
    addpath(genpath('..'))
    
    state = AnalysisState();
    img = uint8(ones(256, 256) * 50);
    img(50:100, 50:100) = 200;
    img(150:200, 150:200) = 200;
    state.image_processed = img;
    
    state = segment_grains(state);
    
    assert(~isempty(state.segmentation_mask), 'Mask is empty');
    assert(isa(state.segmentation_mask, 'logical'), 'Mask should be logical');
    assert(isequal(size(state.segmentation_mask), size(img)), 'Size mismatch');
    disp('✓ Test 1: Segmentation passed');
    
    assert(sum(state.segmentation_mask(:)) > 0, 'Mask should have white pixels');
    disp('✓ Test 2: Mask content check passed');
    
    assert(~isempty(state.segmentation_params), 'Params not stored');
    assert(isfield(state.segmentation_params, 'threshold_value'), 'Threshold not stored');
    disp('✓ Test 3: Parameter storage passed');
    
    assert(~isempty(state.processing_log), 'Log not populated');
    disp('✓ Test 4: Logging works');
    
    disp('All segmentation tests passed');
end
