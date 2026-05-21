function test_publication_figure()
    % test_publication_figure: Smoke tests for generate_publication_figure.
    %   1. Errors when pipeline is incomplete
    %   2. Produces figure_image and figure_handles on full pipeline
    %   3. Appends a processing_log entry
    %   4. figure_image has 3 color channels and matches expected size order

    addpath(genpath('..'))

    % ---- Test 1: errors on incomplete state ----
    state = AnalysisState();
    threw = false;
    try
        generate_publication_figure(state);
    catch ME
        threw = true;
        assert(contains(ME.identifier, 'generate_publication_figure'), ...
            'Expected generate_publication_figure: error identifier');
    end
    assert(threw, 'Expected an error when pipeline is incomplete');
    disp('✓ Test 1: Incomplete-state error raised');

    % ---- Build a minimal fully populated state ----
    state = AnalysisState();
    state.image_filename = 'synthetic.tif';
    img = uint8(repmat(linspace(0, 255, 256), 256, 1));
    state.image_raw = img;
    state.image_processed = img;
    state.preprocessing_method = 'adaptive_histogram_eq';

    mask = false(256, 256);
    mask(40:90,  40:90)  = true;
    mask(140:200, 140:200) = true;
    state.segmentation_mask = mask;

    state.is_calibrated = true;
    state.calibration_factor = 0.01;
    state = analyze_morphology(state);

    % ---- Test 2: figure generation succeeds ----
    state = generate_publication_figure(state);

    assert(~isempty(state.figure_image), 'figure_image not populated');
    assert(isstruct(state.figure_handles), 'figure_handles must be struct');
    assert(isfield(state.figure_handles, 'fig'), 'Missing fig handle');
    assert(isgraphics(state.figure_handles.fig), 'Figure handle invalid');
    disp('✓ Test 2: Figure produced with valid handles + image');

    % ---- Test 3: processing log entry appended ----
    last_log = state.processing_log{end};
    assert(contains(last_log, 'publication figure'), ...
        'Log entry missing for figure generation');
    disp('✓ Test 3: Processing log appended');

    % ---- Test 4: figure_image is RGB uint8 ----
    sz = size(state.figure_image);
    assert(numel(sz) == 3 && sz(3) == 3, 'figure_image must be HxWx3');
    assert(isa(state.figure_image, 'uint8'), 'figure_image must be uint8');
    disp('✓ Test 4: figure_image is uint8 RGB');

    % Cleanup
    close(state.figure_handles.fig);

    disp('All publication-figure tests passed');
end
