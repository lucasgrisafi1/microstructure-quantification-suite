function BW2 = bwareaopen(BW, P, conn)
    % bwareaopen: Remove connected components with area < P pixels.
    if nargin < 3, conn = 8; end
    BW = logical(BW);
    [L, N] = bwlabel(BW, conn);
    BW2 = false(size(BW));
    if N == 0, return; end
    counts = accumarray(L(L > 0), 1, [N, 1]);
    keep = find(counts >= P);
    BW2 = ismember(L, keep);
end
