function state = calibrate_scale(state, ref_scale_px, ref_scale_um)
    % calibrate_scale: Compute pixel-to-micron conversion factor
    % Input: state (AnalysisState), ref_scale_px (pixels), ref_scale_um (microns)
    % Output: state with calibration_factor set

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
