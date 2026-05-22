function BW2 = imerode(BW, se)
    % imerode: Binary erosion (a pixel survives iff the entire SE neighborhood
    % around it is foreground). Uses conv2 over the complement.
    nhood = local_nhood(se);
    n_on = nnz(nhood);
    BW2 = conv2(double(logical(BW)), double(nhood), 'same') >= n_on - 0.5;
end

function nhood = local_nhood(se)
    if isstruct(se) && isfield(se, 'Neighborhood')
        nhood = se.Neighborhood;
    elseif islogical(se) || isnumeric(se)
        nhood = logical(se);
    else
        error('compat:imerode:badSE', 'Unsupported structuring element.');
    end
end
