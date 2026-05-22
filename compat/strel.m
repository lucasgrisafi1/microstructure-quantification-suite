function se = strel(shape, r)
    % strel: Disk structuring element. Other shapes not implemented.
    if ~strcmpi(shape, 'disk')
        error('compat:strel:unsupported', ...
            'Only ''disk'' is implemented in the compat layer.');
    end
    [x, y] = meshgrid(-r:r, -r:r);
    nhood = (x.^2 + y.^2) <= r^2;
    se = struct('Neighborhood', logical(nhood), 'isCompatStrel', true);
end
