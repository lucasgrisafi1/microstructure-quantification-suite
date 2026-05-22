# compat/ — Pure-MATLAB fallbacks for Image Processing Toolbox functions

This directory provides minimal implementations of Image Processing Toolbox
(and Statistics Toolbox) functions used by the pipeline, so the project runs
on a base MATLAB installation. The implementations are correctness-oriented,
not optimised for speed.

If you install the Image Processing Toolbox, remove this directory from your
path (or rename it) so the official, faster IPT versions are used instead.

Functions provided:
- `graythresh`        - Otsu's method (returns level in [0, 1])
- `bwlabel`           - 4/8-connected component labelling (two-pass union-find)
- `bwareaopen`        - Remove components smaller than N pixels
- `imfill(BW,'holes')`- Fill holes inside a binary mask
- `strel('disk', r)`  - Disk structuring element (returns struct)
- `imerode`           - Binary erosion (conv2-based)
- `imdilate`          - Binary dilation (conv2-based)
- `imopen`, `imclose` - Compositions of erosion/dilation
- `regionprops`       - Area, Centroid, Eccentricity, Orientation, Major/MinorAxisLength
- `label2rgb`         - Map label matrix to colour image
- `imshow`            - Thin wrapper around `image`/`imagesc` with axes setup
- `im2uint8`, `mat2gray` - Image type conversions
- `adapthisteq`       - Tile-based adaptive histogram equalisation (no clip-limit)
- `imgaussfilt`       - Gaussian blur via separable conv2
- `rgb2gray`          - ITU-R BT.601 luma weights
- `prctile`           - Linear-interpolation percentile (replaces Statistics Toolbox)

All functions are picked up automatically when the pipeline's tests call
`addpath(genpath('..'))` from the project root.
