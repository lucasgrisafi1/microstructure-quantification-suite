function regions = regionprops(BW, varargin)
    % regionprops: minimal subset.
    %   Properties supported: Area, Centroid, Eccentricity, Orientation,
    %                         MajorAxisLength, MinorAxisLength, BoundingBox.
    %   Accepts either a binary mask or an already-labelled image.

    if islogical(BW)
        L = bwlabel(BW);
    else
        L = double(BW);
    end
    N = max(L(:));
    if N == 0
        regions = struct('Area', {}, 'Centroid', {}, 'Eccentricity', {}, ...
            'Orientation', {}, 'MajorAxisLength', {}, ...
            'MinorAxisLength', {}, 'BoundingBox', {});
        return;
    end

    regions(N, 1) = struct( ...
        'Area', 0, 'Centroid', [0 0], 'Eccentricity', 0, ...
        'Orientation', 0, 'MajorAxisLength', 0, ...
        'MinorAxisLength', 0, 'BoundingBox', [0 0 0 0]);

    for k = 1:N
        [rows, cols] = find(L == k);
        area = numel(rows);
        regions(k).Area = area;

        cx = mean(cols);
        cy = mean(rows);
        regions(k).Centroid = [cx, cy];

        x = cols - cx;
        y = rows - cy;
        % Central moments + IPT-style 1/12 pixel-area correction
        uxx = mean(x.^2) + 1/12;
        uyy = mean(y.^2) + 1/12;
        uxy = mean(x .* y);

        common = sqrt((uxx - uyy)^2 + 4 * uxy^2);
        major_axis = 2 * sqrt(2) * sqrt(uxx + uyy + common);
        minor_axis = 2 * sqrt(2) * sqrt(max(uxx + uyy - common, 0));
        regions(k).MajorAxisLength = major_axis;
        regions(k).MinorAxisLength = minor_axis;

        % Orientation in degrees, [-90, 90], measured CCW from x-axis.
        if uyy > uxx
            num = uyy - uxx + common;
            den = 2 * uxy;
        else
            num = 2 * uxy;
            den = uxx - uyy + common;
        end
        if num == 0 && den == 0
            theta = 0;
        else
            theta = (180 / pi) * atan(num / den);
        end
        regions(k).Orientation = theta;

        if major_axis > 0
            regions(k).Eccentricity = sqrt(1 - (minor_axis / major_axis)^2);
        else
            regions(k).Eccentricity = 0;
        end

        regions(k).BoundingBox = [min(cols) - 0.5, min(rows) - 0.5, ...
            max(cols) - min(cols) + 1, max(rows) - min(rows) + 1];
    end
end
