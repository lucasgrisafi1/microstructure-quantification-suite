function p = prctile(x, percent, dim)
    % prctile: Linear-interpolation percentile (replaces Statistics Toolbox).
    if nargin < 3
        x = x(:);
        dim = 1;
    end
    x = sort(x, dim);
    n = size(x, dim);

    pos = max(1, min(n, percent / 100 * (n - 1) + 1));
    lo = floor(pos);
    hi = ceil(pos);
    frac = pos - lo;

    % Handle vector x only (sufficient for the pipeline)
    if isvector(x)
        x = x(:);
        if any(isnan(x))
            x = x(~isnan(x));
            n = length(x);
            if n == 0
                p = nan(size(percent));
                return;
            end
            pos = max(1, min(n, percent / 100 * (n - 1) + 1));
            lo = floor(pos);
            hi = ceil(pos);
            frac = pos - lo;
        end
        p = (1 - frac) .* x(lo) + frac .* x(hi);
        p = reshape(p, size(percent));
    else
        % Fall-back: along the requested dim
        sz = size(x);
        p = zeros([numel(percent), sz([1:dim-1, dim+1:end])]);
        idx = repmat({':'}, 1, ndims(x));
        for k = 1:numel(percent)
            idx{dim} = lo(k);
            xl = x(idx{:});
            idx{dim} = hi(k);
            xh = x(idx{:});
            p(k, :) = (1 - frac(k)) * xl(:)' + frac(k) * xh(:)';
        end
        p = reshape(p, [numel(percent), sz([1:dim-1, dim+1:end])]);
    end
end
