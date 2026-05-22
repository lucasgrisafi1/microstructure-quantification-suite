function out = rgb2gray(rgb)
    % rgb2gray: ITU-R BT.601 luma conversion.
    if size(rgb, 3) ~= 3
        error('compat:rgb2gray:input', 'Expected an RGB image.');
    end
    r = double(rgb(:, :, 1));
    g = double(rgb(:, :, 2));
    b = double(rgb(:, :, 3));
    gray_d = 0.298936 * r + 0.587043 * g + 0.114021 * b;
    if isa(rgb, 'uint8')
        out = uint8(gray_d);
    elseif isa(rgb, 'uint16')
        out = uint16(gray_d);
    else
        out = gray_d;
    end
end
