function test_doitpoms_validation()
    addpath(genpath('..'))
    
    % NOTE: This test requires sample_doitpoms.tif to be downloaded
    % from http://www.doitpoms.ac.uk/miclib/ and saved to tests/
    
    img_path = fullfile(pwd, 'sample_doitpoms.tif');
    if ~isfile(img_path)
        warning('DoITPoMS sample image not found. Skipping test.');
        return;
    end
    
    state = AnalysisState();
    state = load_image(state, img_path);
    state = calibrate_scale(state, 256, 1.28);
    state = preprocess_image(state);
    state = segment_grains(state);
    
    assert(~isempty(state.segmentation_mask), 'Segmentation failed');
    
    grain_fraction = sum(state.segmentation_mask(:)) / numel(state.segmentation_mask);
    assert(grain_fraction > 0.1 && grain_fraction < 0.9, ...
        sprintf('Grain fraction %.1f%% seems unreasonable', grain_fraction * 100));
    
    disp(sprintf('✓ DoITPoMS validation passed (grain fraction: %.1f%%)', grain_fraction * 100));
end
