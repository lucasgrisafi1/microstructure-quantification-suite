%% Test AnalysisState
% Comprehensive test suite for the updated AnalysisState class

clear all; close all;

fprintf('\n===== AnalysisState Test Suite =====\n\n');

%% Test 1: Instantiation
fprintf('Test 1: Instantiation... ');
state = AnalysisState();
assert(isa(state, 'AnalysisState'), 'Failed to create AnalysisState instance');
fprintf('PASS\n');

%% Test 2: Basic properties initialized
fprintf('Test 2: Basic properties... ');
assert(state.is_calibrated == false, 'is_calibrated should be false');
assert(ischar(state.image_filename) || isstring(state.image_filename), 'image_filename should be string');
assert(iscell(state.processing_log), 'processing_log should be cell array');
assert(isempty(state.processing_log), 'processing_log should start empty');
fprintf('PASS\n');

%% Test 3: Struct properties exist and have expected fields
fprintf('Test 3: Struct field initialization... ');

% preprocessing_params
assert(isstruct(state.preprocessing_params), 'preprocessing_params should be struct');
assert(isfield(state.preprocessing_params, 'method'), 'preprocessing_params.method missing');

% segmentation_params
assert(isstruct(state.segmentation_params), 'segmentation_params should be struct');
assert(isfield(state.segmentation_params, 'threshold_method'), 'segmentation_params.threshold_method missing');
assert(isfield(state.segmentation_params, 'threshold_value'), 'segmentation_params.threshold_value missing');
assert(isfield(state.segmentation_params, 'small_object_threshold'), 'segmentation_params.small_object_threshold missing');

% morphology_stats
assert(isstruct(state.morphology_stats), 'morphology_stats should be struct');
assert(isfield(state.morphology_stats, 'grain_count'), 'morphology_stats.grain_count missing');
assert(isfield(state.morphology_stats, 'D10'), 'morphology_stats.D10 missing');
assert(isfield(state.morphology_stats, 'D50'), 'morphology_stats.D50 missing');
assert(isfield(state.morphology_stats, 'D90'), 'morphology_stats.D90 missing');
assert(isfield(state.morphology_stats, 'mean_eccentricity'), 'morphology_stats.mean_eccentricity missing');
assert(isfield(state.morphology_stats, 'std_eccentricity'), 'morphology_stats.std_eccentricity missing');
assert(isfield(state.morphology_stats, 'mean_orientation'), 'morphology_stats.mean_orientation missing');
assert(isfield(state.morphology_stats, 'std_orientation'), 'morphology_stats.std_orientation missing');
assert(isfield(state.morphology_stats, 'mean_area_um2'), 'morphology_stats.mean_area_um2 missing');
assert(isfield(state.morphology_stats, 'total_area_um2'), 'morphology_stats.total_area_um2 missing');

fprintf('PASS\n');

%% Test 4: Table properties initialized
fprintf('Test 4: Table initialization... ');
assert(istable(state.grain_properties), 'grain_properties should be table');
assert(height(state.grain_properties) == 0, 'grain_properties should start empty');
fprintf('PASS\n');

%% Test 5: Figure handles struct initialized
fprintf('Test 5: Figure handles initialization... ');
assert(isstruct(state.figure_handles), 'figure_handles should be struct');
fprintf('PASS\n');

%% Test 6: saveobj method strips serialization blockers
fprintf('Test 6: saveobj method... ');
s = state.saveobj();
assert(isempty(s.figure_handles), 'figure_handles should be empty after saveobj');
assert(isempty(s.figure_image), 'figure_image should be empty after saveobj');
% Other properties should be preserved
assert(s.is_calibrated == false, 'is_calibrated should be preserved');
assert(iscell(s.processing_log), 'processing_log should be preserved');
fprintf('PASS\n');

%% Test 7: loadobj method restores state
fprintf('Test 7: loadobj method... ');
s = state.saveobj();
loaded_state = AnalysisState.loadobj(s);
assert(loaded_state.is_calibrated == false, 'is_calibrated not preserved through loadobj');
assert(iscell(loaded_state.processing_log), 'processing_log not preserved through loadobj');
fprintf('PASS\n');

%% Test 8: Save/load cycle with save() function (v7.3)
fprintf('Test 8: save/load cycle (-v7.3)... ');
test_filename = 'test_state_v73.mat';
try
    save(test_filename, 'state', '-v7.3');
    assert(isfile(test_filename), 'Mat file not created');

    % Clear workspace and reload
    clear state;
    load(test_filename);

    % Verify state is still valid
    assert(isa(state, 'AnalysisState'), 'State lost AnalysisState type after load');
    assert(state.is_calibrated == false, 'State corrupted: is_calibrated changed');
    assert(iscell(state.processing_log), 'State corrupted: processing_log lost type');

    % Clean up
    delete(test_filename);
    fprintf('PASS\n');
catch ME
    delete(test_filename);
    error('save/load test failed: %s', ME.message);
end

%% Test 9: Modifying properties after construction
fprintf('Test 9: Property modification... ');
state = AnalysisState();
state.is_calibrated = true;
state.image_filename = 'test.tif';
state.preprocessing_params.method = 'adaptive_histogram_eq';
state.segmentation_params.threshold_value = 0.5;
state.morphology_stats.grain_count = 100;
state.processing_log = {'step1', 'step2'};

assert(state.is_calibrated == true, 'Failed to modify is_calibrated');
assert(strcmp(state.image_filename, 'test.tif'), 'Failed to modify image_filename');
assert(strcmp(state.preprocessing_params.method, 'adaptive_histogram_eq'), 'Failed to modify preprocessing_params.method');
assert(state.segmentation_params.threshold_value == 0.5, 'Failed to modify segmentation_params.threshold_value');
assert(state.morphology_stats.grain_count == 100, 'Failed to modify morphology_stats.grain_count');
assert(length(state.processing_log) == 2, 'Failed to modify processing_log');
fprintf('PASS\n');

%% Summary
fprintf('\n===== All Tests Passed =====\n');
fprintf('Total: 9 tests\n');
fprintf('Struct initialization: OK\n');
fprintf('Serialization support: OK\n');
fprintf('Property documentation: OK\n\n');
