function results = run_all_tests()
    % run_all_tests: Execute every unit test and report a summary.
    %
    % Returns
    %   results - struct array with fields: name, passed (logical), error
    %
    % Run from project1_microstructure/tests/ (or anywhere with the project
    % on the path; addpath is applied here for safety).

    addpath(genpath('..'));

    tests = { ...
        'test_calibration', ...
        'test_preprocessing', ...
        'test_segmentation', ...
        'test_morphology', ...
        'test_publication_figure', ...
        'test_doitpoms_validation' ...
    };

    results = struct('name', {}, 'passed', {}, 'error', {});

    fprintf('\n=== Running %d test suites ===\n\n', numel(tests));

    for k = 1:numel(tests)
        name = tests{k};
        fprintf('---- %s ----\n', name);
        try
            feval(name);
            results(end+1).name   = name; %#ok<AGROW>
            results(end).passed   = true;
            results(end).error    = '';
            fprintf('PASS: %s\n\n', name);
        catch ME
            results(end+1).name   = name; %#ok<AGROW>
            results(end).passed   = false;
            results(end).error    = ME.message;
            fprintf('FAIL: %s\n  %s\n\n', name, ME.message);
        end
    end

    n_pass = sum([results.passed]);
    n_fail = numel(results) - n_pass;

    fprintf('===================================\n');
    fprintf('Summary: %d passed, %d failed\n', n_pass, n_fail);
    fprintf('===================================\n');

    if n_fail > 0
        for k = 1:numel(results)
            if ~results(k).passed
                fprintf('  - %-30s %s\n', results(k).name, results(k).error);
            end
        end
        error('run_all_tests:failures', '%d test suite(s) failed.', n_fail);
    end
end
