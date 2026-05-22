cd 'C:\Users\lucas\OneDrive\Documents\Claude\Projects\Summer_2026 Lock In\project1_microstructure'
addpath(genpath(pwd));

% ===== EDIT PER IMAGE =====
filename      = '155.gif';            % file on your Desktop
scale_px      = 260;                  % scale bar length in pixels
scale_um      = 300;                    % scale bar length in micrometers
crop_fraction = 0.88;                   % keep top X of the image; 1.0 = no crop
% ==========================

% Try both common Desktop locations
desktops = { ...
    fullfile(getenv('USERPROFILE'), 'Desktop'), ...
    fullfile(getenv('USERPROFILE'), 'OneDrive', 'Desktop') };
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
state = segment_grains(state);     % add 2nd arg e.g. 0.7 to override threshold
state = analyze_morphology(state);
state = generate_publication_figure(state);

disp(state.morphology_stats)
head(state.grain_properties, 10)

if ~isfolder('output'); mkdir('output'); end
[~, name] = fileparts(image_path);
imwrite(state.figure_image, fullfile('output', [name '_figure.png']));
writetable(state.grain_properties, fullfile('output', [name '_grains.csv']));
save_state(state, fullfile('output', [name '_state.mat']));
fprintf('Done. Outputs: output/%s_figure.png, _grains.csv, _state.mat\n', name);