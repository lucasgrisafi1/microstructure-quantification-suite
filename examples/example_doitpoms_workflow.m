% example_doitpoms_workflow.m
% End-to-end demonstration of the microstructure analysis pipeline.
%
% USAGE
%   1. Place a micrograph at the IMAGE_PATH below (or update the path).
%      - The repo's create_synthetic_doitpoms.m can build a synthetic
%        sample if no real micrograph is available.
%   2. Update SCALE_PX and SCALE_UM with values measured from the scale bar
%      (e.g., using ImageJ's line tool).
%   3. Run this script from the examples/ directory.
%
% OUTPUTS (written to ../output/)
%   - analysis_figure.png    4-panel publication figure
%   - analysis_state.mat     Serialized AnalysisState

addpath(genpath('..'));

% ===== USER INPUT =====
image_path = '../tests/sample_doitpoms.tif';
scale_px   = 256;     % pixels measured across the scale bar
scale_um   = 1.28;    % microns labelled on the scale bar

% ----- Auto-create a synthetic sample if no real image is present -----
if ~isfile(image_path)
    fprintf('No micrograph at %s — generating a synthetic sample...\n', image_path);
    addpath('../tests');
    create_synthetic_doitpoms(image_path);
end

% ===== PIPELINE =====
fprintf('Starting microstructure analysis...\n\n');

state = AnalysisState();
fprintf('[1/6] Initialized AnalysisState\n');

state = load_image(state, image_path);
fprintf('[2/6] Loaded image: %s\n', state.image_filename);

state = calibrate_scale(state, scale_px, scale_um);
fprintf('[3/6] Calibrated: %.4f microns/pixel\n', state.calibration_factor);

state = preprocess_image(state);
fprintf('[4/6] Preprocessed: %s\n', state.preprocessing_method);

state = segment_grains(state);
fprintf('[5/6] Segmented (threshold=%.3f)\n', ...
    state.segmentation_params.threshold_value);

state = analyze_morphology(state);
fprintf('[6/6] Analyzed morphology: %d grains\n', ...
    state.morphology_stats.grain_count);

state = generate_publication_figure(state);

% ===== RESULTS =====
fprintf('\n===== RESULTS =====\n');
fprintf('Grain Count       : %d\n',    state.morphology_stats.grain_count);
fprintf('D10               : %.2f um\n', state.morphology_stats.D10);
fprintf('D50               : %.2f um\n', state.morphology_stats.D50);
fprintf('D90               : %.2f um\n', state.morphology_stats.D90);
fprintf('Mean eccentricity : %.3f +/- %.3f\n', ...
    state.morphology_stats.mean_eccentricity, ...
    state.morphology_stats.std_eccentricity);
fprintf('Mean orientation  : %.1f +/- %.1f deg\n', ...
    state.morphology_stats.mean_orientation, ...
    state.morphology_stats.std_orientation);
fprintf('Mean grain area   : %.2f um^2\n', state.morphology_stats.mean_area_um2);
fprintf('Total grain area  : %.2f um^2\n', state.morphology_stats.total_area_um2);

fprintf('\nFirst few grain rows:\n');
disp(head(state.grain_properties, 5));

% ===== SAVE =====
output_dir = '../output';
if ~isfolder(output_dir)
    mkdir(output_dir);
end

fig_path   = fullfile(output_dir, 'analysis_figure.png');
state_path = fullfile(output_dir, 'analysis_state.mat');

imwrite(state.figure_image, fig_path);
save_state(state, state_path);

fprintf('\nFigure saved to : %s\n', fig_path);
fprintf('State saved to  : %s\n', state_path);
fprintf('Done.\n');
