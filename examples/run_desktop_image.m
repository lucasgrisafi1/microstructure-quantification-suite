% run_desktop_image.m
% Run the full pipeline on an image sitting on your Desktop.
% Replaces the old scratch scripts (untitled3.m / MicrosStructueAnalyze.m),
% which duplicated this workflow with hardcoded personal paths.
%
% Usage: edit the config block, then run from project1_microstructure/.

addpath(genpath(fileparts(fileparts(mfilename('fullpath')))));

% ===== EDIT PER IMAGE =====
filename      = 'my_micrograph.png';   % file on your Desktop
scale_px      = 190.5;                 % scale bar length in pixels
scale_um      = 100;                   % scale bar length in micrometers
crop_fraction = 0.88;                  % keep top X of the image; 1.0 = no crop
% ==========================

% Try both common Desktop locations (portable — no hardcoded user paths)
desktops = { ...
    fullfile(getenv('USERPROFILE'), 'Desktop'), ...
    fullfile(getenv('USERPROFILE'), 'OneDrive', 'Desktop'), ...
    fullfile(getenv('HOME'), 'Desktop')};
image_path = '';
for k = 1:numel(desktops)
    candidate = fullfile(desktops{k}, filename);
    if isfile(candidate); image_path = candidate; break; end
end
if isempty(image_path)
    error('Could not find %s on Desktop. Checked: %s', filename, ...
        strjoin(desktops, ' | '));
end
fprintf('Found image at: %s\n', image_path);

state = AnalysisState();
state = load_image(state, image_path);

if crop_fraction < 1.0
    [h, ~] = size(state.image_raw);
    state.image_raw = state.image_raw(1:round(h * crop_fraction), :);
end

state = calibrate_scale(state, scale_px, scale_um);
state = preprocess_image(state);
state = segment_grains(state);     % options: threshold, 'Polarity', 'Watershed'
state = analyze_morphology(state);
state = generate_publication_figure(state);

disp(state.morphology_stats)
head(state.grain_properties, 10)

if ~isfolder('output'); mkdir('output'); end
[~, name] = fileparts(image_path);
imwrite(state.figure_image, fullfile('output', [name '_figure.png']));
writetable(state.grain_properties, fullfile('output', [name '_grains.csv']));
save_state(state, fullfile('output', [name '_state.mat']));
fprintf('Done. Outputs in output/%s_*.{png,csv,mat}\n', name);
