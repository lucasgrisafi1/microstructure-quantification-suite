% run_sample.m
% One-shot analysis of tests/sample_doitpoms.jpg with the calibration
% measured by the user (100.7 pixels = 400 µm).

addpath(genpath('..'));

% ===== USER INPUT =====
image_path     = '../tests/Micrograph175.jpg';
scale_px       = 190.5;
scale_um       = 100;
crop_scalebar  = true;       % strip the bottom ~12% containing the "100 µm" label
crop_fraction  = 0.88;       % keep top 88% of rows (tweak if scale bar is bigger/smaller)
out_dir        = '../output';

% ===== LOAD + CROP =====
state = AnalysisState();
state = load_image(state, image_path);

if crop_scalebar
    [h, ~] = size(state.image_raw);
    keep_rows = 1:round(h * crop_fraction);
    state.image_raw = state.image_raw(keep_rows, :);
    fprintf('Cropped to %d rows (scale-bar strip removed)\n', numel(keep_rows));
end

% ===== PIPELINE =====
fprintf('Calibration: %.3f um/pixel\n', scale_um / scale_px);

state = calibrate_scale(state, scale_px, scale_um);
state = preprocess_image(state);
state = segment_grains(state);
state = analyze_morphology(state);
state = generate_publication_figure(state);

% ===== RESULTS =====
m = state.morphology_stats;
fprintf('\n========== RESULTS ==========\n');
fprintf('Feature count     : %d\n',     m.grain_count);
fprintf('Equivalent D10    : %.2f um\n', m.D10);
fprintf('Equivalent D50    : %.2f um\n', m.D50);
fprintf('Equivalent D90    : %.2f um\n', m.D90);
fprintf('Mean eccentricity : %.3f +/- %.3f\n', m.mean_eccentricity, m.std_eccentricity);
fprintf('Mean orientation  : %.1f +/- %.1f deg\n', m.mean_orientation,  m.std_orientation);
fprintf('Mean area         : %.2f um^2\n', m.mean_area_um2);
fprintf('Total area        : %.2f um^2\n', m.total_area_um2);
fprintf('=============================\n');

fprintf('\nTop 10 largest features by area:\n');
T = sortrows(state.grain_properties, 'area_um2', 'descend');
disp(head(T, 10));

% ===== SAVE =====
if ~isfolder(out_dir), mkdir(out_dir); end
fig_path   = fullfile(out_dir, 'sample_figure.png');
state_path = fullfile(out_dir, 'sample_state.mat');
csv_path   = fullfile(out_dir, 'sample_grains.csv');

imwrite(state.figure_image, fig_path);
save_state(state, state_path);
writetable(state.grain_properties, csv_path);

fprintf('\nSaved figure : %s\n', fig_path);
fprintf('Saved state  : %s\n', state_path);
fprintf('Saved CSV    : %s\n', csv_path);
fprintf('Done.\n');
