function out = im2uint8(img)
    % im2uint8: Convert image to uint8.
    if isa(img, 'uint8')
        out = img;
    elseif isa(img, 'uint16')
        out = uint8(double(img) / 65535 * 255);
    elseif islogical(img)
        out = uint8(img) * 255;
    elseif isfloat(img)
        out = uint8(min(max(img, 0), 1) * 255);
    else
        out = uint8(img);
    end
end
