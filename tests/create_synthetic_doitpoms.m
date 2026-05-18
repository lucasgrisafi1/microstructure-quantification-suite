function create_synthetic_doitpoms()
    % Create a synthetic microstructure image that mimics DoITPoMS samples
    % This generates a realistic grain-boundary structure for testing
    
    % Create 512x512 image with grayscale grains
    img = uint8(ones(512, 512) * 100);
    
    % Add synthetic grains with varying brightness
    grain_centers = [
        100, 100; 200, 150; 300, 100; 400, 120; 450, 180;
        120, 250; 250, 280; 350, 300; 480, 280;
        90, 380; 200, 420; 320, 400; 400, 420; 450, 380;
        150, 480; 280, 480; 380, 480
    ];
    
    % Add circular grains with smooth boundaries
    [yy, xx] = meshgrid(1:512, 1:512);
    for i = 1:size(grain_centers, 1)
        cx = grain_centers(i, 2);
        cy = grain_centers(i, 1);
        radius = 40 + randi(30);
        
        % Create gaussian-like grain with brightness variation
        dist = sqrt((xx - cx).^2 + (yy - cy).^2);
        grain_intensity = 150 + randi(80) - dist.^2 / (radius^2) * 50;
        
        mask = dist < radius;
        img(mask) = uint8(max(100, min(255, grain_intensity(mask))));
    end
    
    % Add some noise for realism
    noise = uint8(randn(512, 512) * 5);
    img = uint8(max(0, min(255, double(img) + double(noise))));
    
    % Save as TIF
    imwrite(img, 'sample_doitpoms.tif');
    disp('Synthetic DoITPoMS image created: sample_doitpoms.tif');
end

create_synthetic_doitpoms();
