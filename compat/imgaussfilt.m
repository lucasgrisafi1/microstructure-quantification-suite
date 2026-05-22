function out = imgaussfilt(img, sigma)
    % imgaussfilt: Separable Gaussian blur.
    if nargin < 2, sigma = 0.5; end
    half = max(1, ceil(3 * sigma));
    x = -half:half;
    k1d = exp(-(x.^2) / (2 * sigma^2));
    k1d = k1d / sum(k1d);
    in_class = class(img);
    img_d = double(img);
    blurred = conv2(k1d, k1d, img_d, 'same');
    if strcmp(in_class, 'uint8')
        out = uint8(min(max(blurred, 0), 255));
    elseif strcmp(in_class, 'uint16')
        out = uint16(min(max(blurred, 0), 65535));
    else
        out = blurred;
    end
end
