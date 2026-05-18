classdef AnalysisState
    % AnalysisState: Container for microstructure analysis workflow
    % Holds image data, calibration, and intermediate results
    % No methods; purely a data container with properties

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
        preprocessing_params   % Struct: parameters used

        % ===== SEGMENTATION =====
        segmentation_mask      % Binary image (logical, white=grain, black=boundary)
        segmentation_params    % Struct: threshold method, morphological ops

        % ===== MORPHOLOGY ANALYSIS =====
        morphology_stats       % Struct: D10, D50, D90, mean_eccentricity, etc.
        grain_properties       % Table: per-grain measurements

        % ===== VISUALIZATION =====
        figure_handles         % Struct: figure, axes, image references
        figure_image           % RGB image matrix (4-panel figure)

        % ===== METADATA =====
        processing_log         % Cell array: log of steps performed
    end

    methods
        function obj = AnalysisState()
            % Constructor: initialize empty state
            obj.is_calibrated = false;
            obj.processing_log = {};
        end
    end
end
