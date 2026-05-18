classdef AnalysisState
    % AnalysisState: Container for microstructure analysis workflow
    % Holds image data, calibration, and intermediate results
    % Pure data container; all analysis functions operate on this state.
    %
    % PROPERTY LIFECYCLE:
    %   INPUT: Populated by load_image()
    %   CALIBRATION: Populated by calibrate_scale()
    %   PREPROCESSING: Populated by preprocess_image()
    %   SEGMENTATION: Populated by segment_grains()
    %   MORPHOLOGY: Populated by analyze_morphology()
    %   VISUALIZATION: Populated by generate_publication_figure()
    %   METADATA: Updated throughout

    properties
        % ===== INPUT =====
        image_raw              % Original image (uint8 or uint16, 2D grayscale)
        image_filename         % String: filename for reference/logging

        % ===== CALIBRATION =====
        calibration_factor     % Scalar: microns/pixel
        reference_scale_px     % Scalar: pixels measured in ImageJ
        reference_scale_um     % Scalar: microns labeled on scale bar
        is_calibrated          % Boolean: true after calibrate_scale() succeeds

        % ===== PREPROCESSING =====
        image_processed        % Preprocessed image (uint8, same size as image_raw)
        preprocessing_method   % String: method applied (e.g., "adaptive_histogram_eq")
        preprocessing_params   % Struct with fields: method

        % ===== SEGMENTATION =====
        segmentation_mask      % Binary image (logical, white=grain, black=boundary)
        segmentation_params    % Struct with fields: threshold_method, threshold_value, small_object_threshold

        % ===== MORPHOLOGY ANALYSIS =====
        morphology_stats       % Struct with fields: grain_count, D10, D50, D90, mean_eccentricity, std_eccentricity, mean_orientation, std_orientation, mean_area_um2, total_area_um2
        grain_properties       % Table: rows=grains, columns=grain_id, area_pixels, area_um2, eccentricity, orientation, equivalent_diameter, major_axis_um, minor_axis_um

        % ===== VISUALIZATION =====
        % NOTE: figure_handles and figure_image are stripped before serialization via saveobj()
        figure_handles         % Struct: figure, axes (h1, ax1, ax2, ax3, ax4)
        figure_image           % RGB image matrix (uint8 array from getframe)

        % ===== METADATA =====
        processing_log         % Cell array: log of steps performed
    end

    methods
        function obj = AnalysisState()
            % Constructor: initialize empty state with safe defaults

            % Basic initialization
            obj.is_calibrated = false;
            obj.image_filename = '';

            % Initialize struct properties (prevents "field does not exist" errors)
            obj.preprocessing_params = struct('method', []);
            obj.segmentation_params = struct(...
                'threshold_method', [], ...
                'threshold_value', [], ...
                'small_object_threshold', []);
            obj.morphology_stats = struct(...
                'grain_count', [], ...
                'D10', [], ...
                'D50', [], ...
                'D90', [], ...
                'mean_eccentricity', [], ...
                'std_eccentricity', [], ...
                'mean_orientation', [], ...
                'std_orientation', [], ...
                'mean_area_um2', [], ...
                'total_area_um2', []);
            obj.figure_handles = struct();

            % Initialize table property (empty table with correct variable names)
            obj.grain_properties = table();

            % Initialize log
            obj.processing_log = {};
        end
    end

    methods (Hidden)
        function s = saveobj(obj)
            % saveobj: Prepare object for serialization
            % Strips non-serializable figure handles and images
            s = obj;
            s.figure_handles = [];  % Cannot save figure object handles
            s.figure_image = [];    % Don't serialize large RGB matrices
        end
    end

    methods (Static, Hidden)
        function obj = loadobj(s)
            % loadobj: Restore object from serialized form
            % Figure handles and images will be empty after loading
            obj = s;
        end
    end
end
