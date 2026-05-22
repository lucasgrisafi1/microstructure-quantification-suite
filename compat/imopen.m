function BW2 = imopen(BW, se)
    % imopen: Erode then dilate.
    BW2 = imdilate(imerode(BW, se), se);
end
