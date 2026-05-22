function level = graythresh(img)
    % graythresh: Otsu's method. Returns threshold in [0, 1].
    if ~isa(img, 'uint8')
        img = im2uint8(mat2gray(img));
    end
    counts = histcounts(img(:), 0:256);
    p = counts(:) / sum(counts);
    omega = cumsum(p);
    mu = cumsum((0:255)' .* p);
    mu_t = mu(end);
    denom = omega .* (1 - omega);
    denom(denom == 0) = eps;
    sigma_b2 = (mu_t * omega - mu).^2 ./ denom;
    [~, idx] = max(sigma_b2);
    level = (idx - 1) / 255;
end
