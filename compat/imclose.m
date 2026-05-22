function BW2 = imclose(BW, se)
    % imclose: Dilate then erode.
    BW2 = imerode(imdilate(BW, se), se);
end
