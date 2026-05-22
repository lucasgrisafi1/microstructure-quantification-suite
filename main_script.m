% main_script.m
% Quick orchestrator for the Microstructure Quantification Suite.
%
% Run from MATLAB after `cd`-ing into project1_microstructure/.
% Loads the default sample image, runs the full pipeline, prints the
% headline metrics, and saves figure + state + CSV to output/.
%
% Edit the configuration block below to point at a different image
% or change the calibration.

clear; clc;
addpath(genpath(pwd));

% ===== CONFIG =====
image_path     = 'tests/Micrograph175.jpg';   % default sample
scale_px       = 190.5;                       % scale-bar length in pixels
scale_um       = 100;                         % scale-bar length in microns
crop_fraction  = 0.88;                        % keep top 88% of rows (cuts scale bar)
threshold      = [];                          % [] = Otsu auto; or e.g. 0.7
output_dir     = 'output';
% ==================

fprintf('=== Microstructure Quantification Suite ===\n\n');

if ~isfile(image_path)
    error(['Image not found: %s\n\nUpdate ''image_path'' at the top of ' ...
        'main_script.m to point at your micrograph.'], image_path);
end

% ----- Pipeline -----
state = AnalysisState();
state = load_image(state, image_path);
fprintf('[1/6] Loaded: %s\n', state.image_filename);

if crop_fraction < 1.0
    [h, ~] = size(state.image_raw);
    state.image_raw = state.image_raw(1:round(h * crop_fraction), :);
end

state = calibrate_scale(state, scale_px, scale_um);
fprintf('[2/6] Calibrated: %.4f um/pixel\n', state.calibration_factor);

state = preprocess_image(state);
fprintf('[3/6] Preprocessed: %s\n', state.preprocessing_method);

if isempty(threshold)
    state = segment_grains(state);
else
    state = segment_grains(state, threshold);
end
fprintf('[4/6] Segmented (threshold=%.3f)\n', ...
    state.segmentation_params.threshold_value);

state = analyze_morphology(state);
fprintf('[5/6] Analyzed: %d grains\n', state.morphology_stats.grain_count);

state = generate_publication_figure(state);
fprintf('[6/6] Figure generated\n');

% ----- Print headline metrics -----
m = state.morphology_stats;
fprintf('\n========== RESULTS ==========\n');
fprintf('Image             : %s\n',     state.image_filename);
fprintf('Grain count       : %d\n',     m.grain_count);
fprintf('D10 / D50 / D90   : %.2f / %.2f / %.2f um\n', m.D10, m.D50, m.D90);
fprintf('Mean eccentricity : %.3f +/- %.3f\n', m.mean_eccentricity, m.std_eccentricity);
fprintf('Mean orientation  : %.1f +/- %.1f deg\n', m.mean_orientation, m.std_orientation);
fprintf('Mean grain area   : %.2f um^2\n', m.mean_area_um2);
fprintf('=============================\n');

% ----- Save outputs -----
if ~isfolder(output_dir); mkdir(output_dir); end
[~, name] = fileparts(image_path);
fig_path   = fullfile(output_dir, [name '_figure.png']);
state_path = fullfile(output_dir, [name '_state.mat']);
csv_path   = fullfile(output_dir, [name '_grains.csv']);

imwrite(state.figure_image, fig_path);
writetable(state.grain_properties, csv_path);
save_state(state, state_path);

fprintf('\nSaved:\n  %s\n  %s\n  %s\n', fig_path, csv_path, state_path);
fprintf('Pipeline complete.\n');
