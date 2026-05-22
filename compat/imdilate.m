function BW2 = imdilate(BW, se)
    % imdilate: Binary dilation. SE may be a strel struct or a logical mask.
    nhood = local_nhood(se);
    BW2 = conv2(double(logical(BW)), double(nhood), 'same') > 0;
end

function nhood = local_nhood(se)
    if isstruct(se) && isfield(se, 'Neighborhood')
        nhood = se.Neighborhood;
    elseif islogical(se) || isnumeric(se)
        nhood = logical(se);
    else
        error('compat:imdilate:badSE', 'Unsupported structuring element.');
    end
end
