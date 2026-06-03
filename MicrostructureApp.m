classdef MicrostructureApp < matlab.apps.AppBase
    % MICROSTRUCTUREAPP  Interactive GUI for the Microstructure Quantification Suite.
    %
    % A single-window App Designer style interface that drives the full
    % analysis pipeline (load -> calibrate -> preprocess -> segment ->
    % analyze -> publication figure) on a micrograph and reports the grain
    % morphology statistics (count, D10/D50/D90, eccentricity, orientation).
    %
    % USAGE
    %   >> MicrostructureApp        % launch the GUI
    %
    % Then: click "Load Image...", set the scale-bar calibration (pixels and
    % microns), optionally adjust the crop fraction / threshold, and click
    % "Run Analysis". The 4-panel figure renders in the right pane and the
    % metrics appear in the results box. "Save Outputs" writes the figure,
    % the per-grain CSV, and the serialized state to the output/ folder.
    %
    % This class is self-contained: on startup it puts the project folders
    % (pipeline/, utils/, compat/) on the MATLAB path automatically, so it
    % can be launched from anywhere as long as the file sits in the project
    % root next to AnalysisState.m.
    %
    % See also: AnalysisState, main_script, generate_publication_figure.

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure              matlab.ui.Figure
        TitleLabel            matlab.ui.control.Label
        LoadImageButton       matlab.ui.control.Button
        FileNameLabel         matlab.ui.control.Label
        ScalePxLabel          matlab.ui.control.Label
        ScalePxField          matlab.ui.control.NumericEditField
        ScaleUmLabel          matlab.ui.control.Label
        ScaleUmField          matlab.ui.control.NumericEditField
        CropLabel             matlab.ui.control.Label
        CropField             matlab.ui.control.NumericEditField
        ThresholdLabel        matlab.ui.control.Label
        ThresholdField        matlab.ui.control.NumericEditField
        RunAnalysisButton     matlab.ui.control.Button
        SaveOutputsButton     matlab.ui.control.Button
        ResultsLabel          matlab.ui.control.Label
        ResultsArea           matlab.ui.control.TextArea
        UIAxes                matlab.ui.control.UIAxes
    end

    % Internal application state
    properties (Access = private)
        ImageRaw                % Loaded raw image (matrix)
        ImagePath = ''          % Full path of the loaded image
        ImageFilename = ''      % Just the filename
        State                   % AnalysisState after a successful run
        HasResult = false       % True once Run Analysis succeeds
    end

    methods (Access = private)

        % Put the project folders on the MATLAB path so the pipeline
        % functions (and AnalysisState) resolve no matter where the app
        % was launched from.
        function ensureProjectPath(app)
            thisFile = which(class(app));
            if isempty(thisFile)
                thisFile = mfilename('fullpath');
            end
            root = fileparts(thisFile);
            if ~isempty(root)
                addpath(genpath(root));
            end
        end

        % Refresh the right-hand image pane.
        function showImage(app, img, ttl)
            try
                imshow(img, 'Parent', app.UIAxes);
            catch
                image(app.UIAxes, img);
                app.UIAxes.DataAspectRatio = [1 1 1];
                app.UIAxes.YDir = 'reverse';
            end
            app.UIAxes.XTick = [];
            app.UIAxes.YTick = [];
            title(app.UIAxes, ttl, 'Interpreter', 'none');
        end

    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.ensureProjectPath();
            app.ResultsArea.Value = { ...
                'Ready.', '', ...
                '1. Load a micrograph (Load Image...).', ...
                '2. Enter the scale bar: pixels measured + microns labelled.', ...
                '3. Set crop fraction (keeps top fraction of rows; trims', ...
                '   the scale-bar strip). Threshold 0 = automatic (Otsu).', ...
                '4. Click Run Analysis.'};
            app.SaveOutputsButton.Enable = 'off';
        end

        % Button pushed function: LoadImageButton
        function LoadImageButtonPushed(app, ~)
            [file, path] = uigetfile( ...
                {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.gif;*.bmp', ...
                 'Image Files (*.png,*.jpg,*.tif,*.gif,*.bmp)'}, ...
                'Select a microstructure image');
            if isequal(file, 0)
                return;   % user cancelled
            end
            full = fullfile(path, file);
            try
                img = imread(full);
            catch ME
                uialert(app.UIFigure, ME.message, 'Could not read image');
                return;
            end
            app.ImageRaw      = img;
            app.ImagePath     = full;
            app.ImageFilename = file;
            app.HasResult     = false;
            app.SaveOutputsButton.Enable = 'off';

            app.showImage(img, sprintf('Loaded: %s', file));
            app.FileNameLabel.Text = file;
            app.ResultsArea.Value = { ...
                sprintf('Loaded image: %s', file), ...
                sprintf('Size: %d x %d', size(img, 1), size(img, 2)), ...
                '', 'Set calibration, then click Run Analysis.'};
        end

        % Button pushed function: RunAnalysisButton
        function RunAnalysisButtonPushed(app, ~)
            if isempty(app.ImageRaw)
                uialert(app.UIFigure, ...
                    'Load an image first (Load Image...).', 'No image');
                return;
            end

            app.ensureProjectPath();
            d = uiprogressdlg(app.UIFigure, 'Title', 'Running analysis', ...
                'Indeterminate', 'on', 'Message', 'Starting pipeline...');
            cleanup = onCleanup(@() delete(d));

            try
                scale_px = app.ScalePxField.Value;
                scale_um = app.ScaleUmField.Value;
                cropf    = app.CropField.Value;
                thresh   = app.ThresholdField.Value;

                if scale_px <= 0 || scale_um <= 0
                    error('Scale (px) and Scale (um) must both be positive.');
                end
                if cropf <= 0 || cropf > 1
                    error('Crop fraction must be in the range (0, 1].');
                end

                state = AnalysisState();
                state.image_raw = app.ImageRaw;
                if size(state.image_raw, 3) == 3
                    state.image_raw = rgb2gray(state.image_raw);
                end
                state.image_filename = app.ImageFilename;

                % Crop the scale-bar strip from the bottom if requested
                if cropf < 1.0
                    h = size(state.image_raw, 1);
                    state.image_raw = state.image_raw(1:round(h * cropf), :);
                end

                d.Message = 'Calibrating scale...';
                state = calibrate_scale(state, scale_px, scale_um);

                d.Message = 'Preprocessing...';
                state = preprocess_image(state);

                d.Message = 'Segmenting grains...';
                if thresh > 0
                    state = segment_grains(state, thresh);
                else
                    state = segment_grains(state);   % Otsu auto
                end

                d.Message = 'Analyzing morphology...';
                state = analyze_morphology(state);

                d.Message = 'Rendering figure...';
                state = generate_publication_figure(state);

                % Capture the rendered 4-panel figure and close the popup
                figImg = state.figure_image;
                if isfield(state.figure_handles, 'fig') && ...
                        ~isempty(state.figure_handles.fig) && ...
                        isgraphics(state.figure_handles.fig)
                    close(state.figure_handles.fig);
                end

                app.State     = state;
                app.HasResult = true;
                app.SaveOutputsButton.Enable = 'on';

                if ~isempty(figImg)
                    app.showImage(figImg, 'Analysis (4-panel figure)');
                end

                m = state.morphology_stats;
                app.ResultsArea.Value = { ...
                    sprintf('Image            : %s', state.image_filename), ...
                    sprintf('Calibration      : %.4f um/pixel', state.calibration_factor), ...
                    sprintf('Threshold        : %.3f (%s)', ...
                        state.segmentation_params.threshold_value, ...
                        ternary(thresh > 0, 'manual', 'Otsu auto')), ...
                    '----------------------------------------', ...
                    sprintf('Grain count      : %d', m.grain_count), ...
                    sprintf('D10 / D50 / D90  : %.2f / %.2f / %.2f um', m.D10, m.D50, m.D90), ...
                    sprintf('Eccentricity     : %.3f +/- %.3f', m.mean_eccentricity, m.std_eccentricity), ...
                    sprintf('Orientation      : %.1f +/- %.1f deg', m.mean_orientation, m.std_orientation), ...
                    sprintf('Mean grain area  : %.2f um^2', m.mean_area_um2), ...
                    sprintf('Total grain area : %.2f um^2', m.total_area_um2), ...
                    '----------------------------------------', ...
                    'Done. Click Save Outputs to export.'};

            catch ME
                app.ResultsArea.Value = { 'ERROR during analysis:', ME.message };
                uialert(app.UIFigure, ME.message, 'Analysis failed');
            end
        end

        % Button pushed function: SaveOutputsButton
        function SaveOutputsButtonPushed(app, ~)
            if ~app.HasResult
                uialert(app.UIFigure, 'Run an analysis first.', 'Nothing to save');
                return;
            end
            root = fileparts(which(class(app)));
            if isempty(root); root = pwd; end
            out_dir = fullfile(root, 'output');
            if ~isfolder(out_dir); mkdir(out_dir); end

            [~, name] = fileparts(app.ImageFilename);
            if isempty(name); name = 'analysis'; end
            fig_path   = fullfile(out_dir, [name '_figure.png']);
            csv_path   = fullfile(out_dir, [name '_grains.csv']);
            state_path = fullfile(out_dir, [name '_state.mat']);

            try
                if ~isempty(app.State.figure_image)
                    imwrite(app.State.figure_image, fig_path);
                end
                writetable(app.State.grain_properties, csv_path);
                save_state(app.State, state_path);

                app.ResultsArea.Value = { 'Saved outputs to output/:', ...
                    ['  ' name '_figure.png'], ...
                    ['  ' name '_grains.csv'], ...
                    ['  ' name '_state.mat'] };
            catch ME
                uialert(app.UIFigure, ME.message, 'Save failed');
            end
        end
    end

    % Component initialization
    methods (Access = private)

        function createComponents(app)

            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1000 640];
            app.UIFigure.Name = 'Microstructure Quantification Suite';

            app.TitleLabel = uilabel(app.UIFigure);
            app.TitleLabel.Position = [20 600 320 26];
            app.TitleLabel.FontSize = 15;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Text = 'Microstructure Quantification Suite';

            app.LoadImageButton = uibutton(app.UIFigure, 'push');
            app.LoadImageButton.ButtonPushedFcn = createCallbackFcn(app, @LoadImageButtonPushed, true);
            app.LoadImageButton.Position = [20 560 140 28];
            app.LoadImageButton.Text = 'Load Image...';

            app.FileNameLabel = uilabel(app.UIFigure);
            app.FileNameLabel.Position = [170 560 150 28];
            app.FileNameLabel.Text = '(no image loaded)';

            app.ScalePxLabel = uilabel(app.UIFigure);
            app.ScalePxLabel.HorizontalAlignment = 'right';
            app.ScalePxLabel.Position = [10 515 110 22];
            app.ScalePxLabel.Text = 'Scale bar (px)';
            app.ScalePxField = uieditfield(app.UIFigure, 'numeric');
            app.ScalePxField.Position = [130 515 90 22];
            app.ScalePxField.Value = 190.5;
            app.ScalePxField.Limits = [0 Inf];

            app.ScaleUmLabel = uilabel(app.UIFigure);
            app.ScaleUmLabel.HorizontalAlignment = 'right';
            app.ScaleUmLabel.Position = [10 480 110 22];
            app.ScaleUmLabel.Text = 'Scale bar (um)';
            app.ScaleUmField = uieditfield(app.UIFigure, 'numeric');
            app.ScaleUmField.Position = [130 480 90 22];
            app.ScaleUmField.Value = 100;
            app.ScaleUmField.Limits = [0 Inf];

            app.CropLabel = uilabel(app.UIFigure);
            app.CropLabel.HorizontalAlignment = 'right';
            app.CropLabel.Position = [10 445 110 22];
            app.CropLabel.Text = 'Crop fraction';
            app.CropField = uieditfield(app.UIFigure, 'numeric');
            app.CropField.Position = [130 445 90 22];
            app.CropField.Value = 0.88;
            app.CropField.Limits = [0 1];

            app.ThresholdLabel = uilabel(app.UIFigure);
            app.ThresholdLabel.HorizontalAlignment = 'right';
            app.ThresholdLabel.Position = [10 410 110 22];
            app.ThresholdLabel.Text = 'Threshold (0=auto)';
            app.ThresholdField = uieditfield(app.UIFigure, 'numeric');
            app.ThresholdField.Position = [130 410 90 22];
            app.ThresholdField.Value = 0;
            app.ThresholdField.Limits = [0 1];

            app.RunAnalysisButton = uibutton(app.UIFigure, 'push');
            app.RunAnalysisButton.ButtonPushedFcn = createCallbackFcn(app, @RunAnalysisButtonPushed, true);
            app.RunAnalysisButton.Position = [20 365 140 30];
            app.RunAnalysisButton.FontWeight = 'bold';
            app.RunAnalysisButton.Text = 'Run Analysis';

            app.SaveOutputsButton = uibutton(app.UIFigure, 'push');
            app.SaveOutputsButton.ButtonPushedFcn = createCallbackFcn(app, @SaveOutputsButtonPushed, true);
            app.SaveOutputsButton.Position = [170 365 140 30];
            app.SaveOutputsButton.Text = 'Save Outputs';

            app.ResultsLabel = uilabel(app.UIFigure);
            app.ResultsLabel.Position = [20 330 200 22];
            app.ResultsLabel.FontWeight = 'bold';
            app.ResultsLabel.Text = 'Results';

            app.ResultsArea = uitextarea(app.UIFigure);
            app.ResultsArea.Position = [20 30 300 295];
            app.ResultsArea.Editable = 'off';
            app.ResultsArea.FontName = 'Consolas';

            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Microstructure Image');
            app.UIAxes.XTick = [];
            app.UIAxes.YTick = [];
            app.UIAxes.Position = [340 30 640 590];

            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        function app = MicrostructureApp
            createComponents(app)
            registerApp(app, app.UIFigure)
            runStartupFcn(app, @startupFcn)
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure)
        end
    end
end

% Small inline helper (local function) for a conditional string.
function out = ternary(cond, a, b)
    if cond
        out = a;
    else
        out = b;
    end
end
