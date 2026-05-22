function h_im = imshow(img, varargin)
    % imshow: Minimal replacement for IPT imshow.
    % Supports name-value 'Parent', axes argument; falls back to current axes.

    parent_idx = find(strcmpi(varargin, 'Parent'), 1);
    if ~isempty(parent_idx) && parent_idx < length(varargin)
        ax = varargin{parent_idx + 1};
    else
        ax = gca;
    end

    if islogical(img)
        img = uint8(img) * 255;
    end
    if isfloat(img) && (size(img, 3) == 1)
        img = im2uint8(mat2gray(img));
    end

    if size(img, 3) == 3
        h_im = image(img, 'Parent', ax);
    else
        h_im = image(img, 'Parent', ax);
        colormap(ax, gray(256));
        set(h_im, 'CDataMapping', 'scaled');
        clim_set(ax, [0 255]);
    end

    set(ax, 'YDir', 'reverse');
    axis(ax, 'image');
    axis(ax, 'off');

    if nargout == 0
        clear h_im;
    end
end

function clim_set(ax, lims)
    try
        clim(ax, lims);
    catch
        set(ax, 'CLim', lims);
    end
end
