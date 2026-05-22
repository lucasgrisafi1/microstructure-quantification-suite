# Microstructure Quantification Suite (Project 1)

MATLAB-based pipeline for automated analysis of SEM and optical microscopy images. Extracts grain morphology statistics (D10, D50, D90, eccentricity, orientation) from micrographs and renders a publication-ready 4-panel figure.

## Features

- **Automatic calibration** — pixel-to-micron conversion from a measured scale bar.
- **Adaptive preprocessing** — contrast enhancement appropriate for SEM vs. optical inputs (default: adaptive histogram equalization).
- **Robust segmentation** — Otsu thresholding plus morphological cleanup (area filter, hole fill, opening, closing).
- **Quantitative morphology** — per-grain properties (area, eccentricity, orientation, equivalent diameter, major/minor axis) plus ensemble statistics (grain count, D10/D50/D90, mean ± std for eccentricity and orientation, mean and total area).
- **Publication-ready figure** — 4-panel layout: raw / preprocessed / segmentation overlay / labeled grains, with stats annotation.
- **State checkpointing** — `save_state` / `load_state` round-trip the `AnalysisState` object at any pipeline step.
- **Validation harness** — synthetic DoITPoMS-style microstructures for offline regression testing.

## Project layout

```
project1_microstructure/
├── AnalysisState.m                  Data container class (input → calibration → preprocessing → segmentation → morphology → visualization)
├── pipeline/
│   ├── calibrate_scale.m            Compute calibration_factor (microns/pixel)
│   ├── preprocess_image.m           Adaptive histogram equalization
│   ├── segment_grains.m             Otsu + morphological cleanup
│   ├── analyze_morphology.m         regionprops → grain table + ensemble stats
│   └── generate_publication_figure.m 4-panel figure (raw, processed, overlay, labels)
├── tests/
│   ├── test_calibration.m
│   ├── test_preprocessing.m
│   ├── test_segmentation.m
│   ├── test_morphology.m
│   ├── test_publication_figure.m
│   ├── test_doitpoms_validation.m
│   ├── create_synthetic_doitpoms.m
│   └── validate_doitpoms_morphology.m
├── utils/
│   ├── load_image.m
│   ├── save_state.m
│   └── load_state.m
└── output/                          Checkpoints and rendered figures
```

## Usage

```matlab
addpath(genpath('.'));

state = AnalysisState();
state = load_image(state, 'examples/sample.tif');

% Scale bar: 256 pixels measured for a 25 micron bar
state = calibrate_scale(state, 256, 25);

state = preprocess_image(state);
state = segment_grains(state);
state = analyze_morphology(state);
state = generate_publication_figure(state);

% Save artefacts
if ~isfolder('output'); mkdir('output'); end
imwrite(state.figure_image, 'output/sample_4panel.png');
save_state(state, 'output/sample_final.mat');

% Inspect results
disp(state.morphology_stats)
head(state.grain_properties)
```

## Pipeline architecture

`AnalysisState` is a pure data container. Each pipeline function takes a state and returns a state — no globals, no hidden side effects. Properties are populated in lifecycle order:

1. **Input** — `image_raw`, `image_filename`
2. **Calibration** — `calibration_factor`, `reference_scale_px/um`, `is_calibrated`
3. **Preprocessing** — `image_processed`, `preprocessing_method`, `preprocessing_params`
4. **Segmentation** — `segmentation_mask`, `segmentation_params`
5. **Morphology** — `morphology_stats`, `grain_properties`
6. **Visualization** — `figure_handles`, `figure_image` (stripped on `save`, restored as empty on `load`)

Every step appends a timestamped entry to `processing_log`.

## Computed metrics

Per grain (`state.grain_properties` table):

| Column | Description |
| --- | --- |
| `grain_id` | Unique identifier (1..N) |
| `area_pixels` | Raw connected-component pixel count |
| `area_um2` | `area_pixels * calibration_factor^2` |
| `eccentricity` | 0 = circle, 1 = line segment |
| `orientation` | Major-axis angle in degrees, [-90, 90] |
| `equivalent_diameter` | Equivalent-area circular diameter (microns) |
| `major_axis_um` | Fitted-ellipse major axis (microns) |
| `minor_axis_um` | Fitted-ellipse minor axis (microns) |

Ensemble (`state.morphology_stats`): `grain_count`, `D10`, `D50`, `D90`, `mean_eccentricity`, `std_eccentricity`, `mean_orientation`, `std_orientation`, `mean_area_um2`, `total_area_um2`.

## Testing

```matlab
cd tests
test_calibration()
test_preprocessing()
test_segmentation()
test_morphology()
test_publication_figure()
test_doitpoms_validation()        % synthetic DoITPoMS sample
validate_doitpoms_morphology()    % full pipeline end-to-end
```

Network access to the real DoITPoMS dataset is not available in the sandbox, so the validation suite generates a synthetic microstructure with realistic grain morphology when no real sample is present.

## Calibration & units

All distance measurements are reported in microns. Set the calibration with `calibrate_scale(state, pixels, microns)` using a measurement taken from the scale bar (e.g., ImageJ line tool). The resulting `calibration_factor` is microns/pixel; areas are converted as `pixels^2 * calibration_factor^2`.

A typical default for high-resolution SEM is `0.01 µm/pixel` (10 nm/pixel at a 1.28 µm field of view, 256×256 pixels).

## Roadmap

- Day 5 (in progress): publication figure + this README ✓
- Day 6: example scripts, optional optical-microscopy walkthrough, final validation
- Future: crystallographic orientation mapping, grain-boundary characterization, multi-image batching
