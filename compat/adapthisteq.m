function out = adapthisteq(img, varargin)
    % adapthisteq: Tile-based adaptive histogram equalisation.
    %   Simplification of CLAHE: no clip limit, no bilinear interpolation
    %   between tiles. Sufficient for the microstructure pipeline.
    %
    % Accepts the same Name-Value parameters as IPT's adapthisteq
    % ('NumTiles', 'ClipLimit', 'Distribution') but only NumTiles affects
    % the output.

    if ~isa(img, 'uint8')
        img = im2uint8(mat2gray(img));
    end

    n_tiles = [8 8];
    for k = 1:2:numel(varargin)
        if strcmpi(varargin{k}, 'NumTiles')
            n_tiles = varargin{k + 1};
        end
    end

    [m, n] = size(img);
    tile_m = ceil(m / n_tiles(1));
    tile_n = ceil(n / n_tiles(2));
    out = zeros(m, n, 'uint8');

    for ti = 1:n_tiles(1)
        r0 = (ti - 1) * tile_m + 1;
        r1 = min(ti * tile_m, m);
        if r0 > m, continue; end
        for tj = 1:n_tiles(2)
            c0 = (tj - 1) * tile_n + 1;
            c1 = min(tj * tile_n, n);
            if c0 > n, continue; end
            tile = img(r0:r1, c0:c1);
            counts = histcounts(tile(:), 0:256);
            cdf = cumsum(counts) / max(sum(counts), 1);
            lut = uint8(cdf * 255);
            out(r0:r1, c0:c1) = lut(double(tile) + 1);
        end
    end
end
