function RGB = label2rgb(L, cmap_name, bg_color, order)
    % label2rgb: Map a label matrix to an RGB image.
    if nargin < 2, cmap_name = 'jet'; end
    if nargin < 3, bg_color = 'w'; end
    if nargin < 4, order = 'noshuffle'; end

    L = double(L);
    N = max(L(:));
    if N < 1
        cmap = zeros(0, 3);
    else
        if ischar(cmap_name) || isstring(cmap_name)
            cmap = feval(char(cmap_name), N);
        elseif isnumeric(cmap_name)
            cmap = cmap_name;
            if size(cmap, 1) < N
                cmap = repmat(cmap, ceil(N / size(cmap, 1)), 1);
                cmap = cmap(1:N, :);
            end
        else
            cmap = jet(N);
        end
        if strcmpi(order, 'shuffle')
            cmap = cmap(randperm(N), :);
        end
    end

    if ischar(bg_color) || isstring(bg_color)
        switch lower(char(bg_color))
            case 'k', bg_rgb = [0 0 0];
            case 'w', bg_rgb = [1 1 1];
            case 'r', bg_rgb = [1 0 0];
            case 'g', bg_rgb = [0 1 0];
            case 'b', bg_rgb = [0 0 1];
            case 'y', bg_rgb = [1 1 0];
            case 'm', bg_rgb = [1 0 1];
            case 'c', bg_rgb = [0 1 1];
            otherwise, bg_rgb = [1 1 1];
        end
    else
        bg_rgb = double(bg_color(:))';
    end

    [m, n] = size(L);
    R = bg_rgb(1) * ones(m, n);
    G = bg_rgb(2) * ones(m, n);
    B = bg_rgb(3) * ones(m, n);
    for k = 1:N
        mask = (L == k);
        R(mask) = cmap(k, 1);
        G(mask) = cmap(k, 2);
        B(mask) = cmap(k, 3);
    end
    RGB = uint8(cat(3, R, G, B) * 255);
end
