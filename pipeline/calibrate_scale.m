function state = calibrate_scale(state, ref_scale_px, ref_scale_um)
    % CALIBRATE_SCALE  Set pixel-to-micron conversion from scale-bar measurement.
    %
    % SYNTAX
    %   state = calibrate_scale(state, ref_scale_px, ref_scale_um)
    %
    % INPUTS
    %   state           (AnalysisState) - container holding image data
    %   ref_scale_px    (numeric > 0)   - measured scale-bar length in pixels
    %   ref_scale_um    (numeric > 0)   - labelled scale-bar length in microns
    %
    % OUTPUTS
    %   state - calibration_factor (um/px), reference_scale_px,
    %           reference_scale_um, is_calibrated populated;
    %           processing_log appended.
    %
    % EXAMPLE
    %   % Scale bar measured at 256 pixels for a 25 um label
    %   state = calibrate_scale(state, 256, 25);   % -> 0.0977 um/pixel
    %
    % NOTES
    %   - Inputs are validated as numeric and positive; errors otherwise.
    %   - All downstream micron measurements use this factor.
    %
    % See also: load_image, preprocess_image.

    if ~isnumeric(ref_scale_px) || ~isnumeric(ref_scale_um)
        error('Scale inputs must be numeric');
    end

    if ref_scale_px <= 0 || ref_scale_um <= 0
        error('Scale inputs must be positive');
    end

    % Compute calibration factor
    state.calibration_factor = ref_scale_um / ref_scale_px;
    state.reference_scale_px = ref_scale_px;
    state.reference_scale_um = ref_scale_um;
    state.is_calibrated = true;

    % Log
    state.processing_log{end+1} = sprintf('[%s] Calibrated: %.4f microns/pixel', ...
        datetime('now', 'Format', 'HH:mm:ss'), state.calibration_factor);
end
