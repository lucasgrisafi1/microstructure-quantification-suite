function BW2 = imfill(BW, mode)
    % imfill: Only the 'holes' mode is implemented.
    if nargin < 2 || ~ischar(mode) && ~isstring(mode) || ~strcmpi(mode, 'holes')
        error('compat:imfill:unsupported', ...
            'Only imfill(BW, ''holes'') is supported.');
    end
    BW = logical(BW);
    [m, n] = size(BW);
    bg = ~BW;

    % BFS flood-fill from any background pixel on the border
    visited = false(m, n);
    qmax = max(1, m * n);
    queue = zeros(qmax, 2);
    head = 1; tail = 0;

    for c = 1:n
        if bg(1, c) && ~visited(1, c)
            tail = tail + 1; queue(tail, :) = [1, c]; visited(1, c) = true;
        end
        if bg(m, c) && ~visited(m, c)
            tail = tail + 1; queue(tail, :) = [m, c]; visited(m, c) = true;
        end
    end
    for r = 1:m
        if bg(r, 1) && ~visited(r, 1)
            tail = tail + 1; queue(tail, :) = [r, 1]; visited(r, 1) = true;
        end
        if bg(r, n) && ~visited(r, n)
            tail = tail + 1; queue(tail, :) = [r, n]; visited(r, n) = true;
        end
    end

    nb = [-1 0; 1 0; 0 -1; 0 1];
    while head <= tail
        r = queue(head, 1); c = queue(head, 2);
        head = head + 1;
        for k = 1:4
            nr = r + nb(k, 1); nc = c + nb(k, 2);
            if nr >= 1 && nr <= m && nc >= 1 && nc <= n ...
                    && bg(nr, nc) && ~visited(nr, nc)
                visited(nr, nc) = true;
                tail = tail + 1; queue(tail, :) = [nr, nc];
            end
        end
    end

    holes = bg & ~visited;
    BW2 = BW | holes;
end
