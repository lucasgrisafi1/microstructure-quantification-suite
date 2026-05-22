function out = mat2gray(img, lims)
    % mat2gray: Scale array values to [0, 1].
    img = double(img);
    if nargin < 2
        lims = [min(img(:)), max(img(:))];
    end
    lo = lims(1); hi = lims(2);
    span = hi - lo;
    if span <= 0
        out = zeros(size(img));
        return;
    end
    out = (img - lo) / span;
    out = min(max(out, 0), 1);
end
