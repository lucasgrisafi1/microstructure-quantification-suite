function [L, N] = bwlabel(BW, conn)
    % bwlabel: Connected-component labelling. conn = 4 or 8 (default 8).
    if nargin < 2, conn = 8; end
    BW = logical(BW);
    [m, n] = size(BW);
    L = zeros(m, n);

    % Two-pass union-find
    parent = zeros(m * n, 1, 'uint32');
    next_label = uint32(0);

    function r = find_root(x)
        r = x;
        while parent(r) ~= r
            r = parent(r);
        end
        while parent(x) ~= r
            nxt = parent(x);
            parent(x) = r;
            x = nxt;
        end
    end

    function union(a, b)
        ra = find_root(a);
        rb = find_root(b);
        if ra ~= rb
            if ra < rb, parent(rb) = ra; else, parent(ra) = rb; end
        end
    end

    % First pass: assign provisional labels
    for r = 1:m
        for c = 1:n
            if BW(r, c)
                neigh = uint32([]);
                if c > 1 && L(r, c-1) > 0
                    neigh(end+1) = uint32(L(r, c-1)); %#ok<AGROW>
                end
                if r > 1 && L(r-1, c) > 0
                    neigh(end+1) = uint32(L(r-1, c)); %#ok<AGROW>
                end
                if conn == 8
                    if r > 1 && c > 1 && L(r-1, c-1) > 0
                        neigh(end+1) = uint32(L(r-1, c-1)); %#ok<AGROW>
                    end
                    if r > 1 && c < n && L(r-1, c+1) > 0
                        neigh(end+1) = uint32(L(r-1, c+1)); %#ok<AGROW>
                    end
                end

                if isempty(neigh)
                    next_label = next_label + 1;
                    parent(next_label) = next_label;
                    L(r, c) = double(next_label);
                else
                    min_n = min(neigh);
                    L(r, c) = double(min_n);
                    for k = 1:length(neigh)
                        union(min_n, neigh(k));
                    end
                end
            end
        end
    end

    % Second pass: relabel using roots, compacted to 1..N
    label_map = zeros(double(next_label), 1);
    new_label = 0;
    for r = 1:m
        for c = 1:n
            if L(r, c) > 0
                root = double(find_root(uint32(L(r, c))));
                if label_map(root) == 0
                    new_label = new_label + 1;
                    label_map(root) = new_label;
                end
                L(r, c) = label_map(root);
            end
        end
    end
    N = new_label;
end
