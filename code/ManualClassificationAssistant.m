
%% % Parameters
tic;
% C:\Users\ZXY\Desktop\ASU\Lab\DivisionTrack\Z_estimation_examples_yunlei\20200817_Copy\data\2umPSNP20Xdilu\1_short2\
frames_path = 'C:\Users\ZXY\Desktop\ASU\Lab\DivisionTrack\Z_estimation_examples_yunlei\20200817_Copy\data\2umPSNP20Xdilu\1\';
no_event_path = 'Z:\DataSet\EventDetection\20200921_2\no_event';
event_path = 'Z:\DataSet\EventDetection\20200921_2\event';

high_threshold = 5;

%% load images and initialize filter operated images, detected particles
all_images = LoadImages(frames_path);% size (#frames,h,w)
log_images = zeros(size(all_images));

global all_images_bright_particles 
all_images_bright_particles = cell(1,size( all_images,1));


%% detection
TextProgressBar('Filtering the images: ');
leng = size(all_images,1);
for i = 1:size(all_images,1)
    TextProgressBar((i/leng)*100); 
    log_img = LogImage(all_images(i,:,:));
    log_images(i,:,:) = log_img;
    
    all_images_bright_particles(i) = {IdentifySpots(log_img, high_threshold)};
end
TextProgressBar('Done ');
%%

h = 20;
w = 20;
h2 = 40;
w2 = 40;
exit = false;
TextProgressBar('Particle classification: ');
%interval 10
for i = 255:50:size(all_images_bright_particles,2)
    TextProgressBar((i/leng)*100); 
    one_frame_particles = all_images_bright_particles{i};
    image = squeeze(all_images(i,:,:));
    image_h = size(image,1);
    image_w = size(image,2);
    for j = 1:size(one_frame_particles,1)
        x = ceil(one_frame_particles(j,2));
        y = ceil(one_frame_particles(j,1));
        if x-h2/2+1< 1 || x+h2/2> image_h || y-w2/2+1<1 || y+w2/2>image_w
            continue
        end
        %show particles
        single_particle = image(x-h/2+1:x+h/2, y-w/2+1:y+w/2);
        single_particle_surroundings = image(x-h2/2+1:x+h2/2, y-w2/2+1:y+w2/2);
        subplot(1,2,1)
        imshow(single_particle, 'DisplayRange',[min(single_particle(:)) max(single_particle(:))], 'InitialMagnification',1600);
        title(['The particle to be saved, frame' num2str(i)])
        subplot(1,2,2)
        f = imshow(single_particle_surroundings, 'DisplayRange',[min(single_particle(:)) max(single_particle(:))], 'InitialMagnification',400);
        title('The particle large ROI')
        movegui(f, 'east')
        %classification
        exit = ChooseClass(single_particle, no_event_path, event_path, i , j);
        
        drawnow;
        if exit
            break
        end
    end
    if exit
        break
    end
end
TextProgressBar('Done ');
%%

function exit = ChooseClass(single_particle, no_event_path, event_path, frame, j)

    img_class = questdlg('which class', ...
        'which class', ...
        'no event','event','exit','no event');
    % Handle response

    switch img_class
        case 'no event'
            imwrite(uint16(single_particle), [no_event_path '\' num2str(frame, '%04d') '_' num2str(j, '%04d')  '.tif'])
            exit = false;
        case 'event'
            imwrite(uint16(single_particle), [event_path '\' num2str(frame, '%04d') '_' num2str(j, '%04d')  '.tif'])
            exit = false;
        case 'exit'
            exit = true;
    end
end



function all_images = LoadImages(source_path)
    source_path
    imges = dir([source_path '*.tif']);
    imge_num = length(imges);
    [imges(1).folder '/' imges(1).name]
    shapes = size(imread([imges(1).folder '/' imges(1).name]));
    all_images = zeros(imge_num, shapes(1), shapes(2));

    for i = 1:imge_num
        img = imread([imges(i).folder '/' imges(i).name]);
        all_images(i,:,:) = img;

    end
end

function TextProgressBar(c)
% This function creates a text progress bar. It should be called with a 
% STRING argument to initialize and terminate. Otherwise the number correspoding 
% to progress in % should be supplied.
% INPUTS:   C   Either: Text string to initialize or terminate 
%                       Percentage number to show progress 
% OUTPUTS:  N/A
% Example:  Please refer to demo_textprogressbar.m
% Author: Paul Proteus (e-mail: proteus.paul (at) yahoo (dot) com)
% Version: 1.0
% Changes tracker:  29.06.2010  - First version
% Inspired by: http://blogs.mathworks.com/loren/2007/08/01/monitoring-progress-of-a-calculation/
%% Initialization
persistent strCR;           %   Carriage return pesistent variable
% Vizualization parameters
strPercentageLength = 10;   %   Length of percentage string (must be >5)
strDotsMaximum      = 10;   %   The total number of dots in a progress bar
%% Main 
if isempty(strCR) && ~ischar(c),
    % Progress bar must be initialized with a string
    error('The text progress must be initialized with a string');
elseif isempty(strCR) && ischar(c),
    % Progress bar - initialization
    fprintf('%s',c);
    strCR = -1;
elseif ~isempty(strCR) && ischar(c),
    % Progress bar  - termination
    strCR = [];  
    fprintf([c '\n']);
elseif isnumeric(c)
    % Progress bar - normal progress
    c = floor(c);
    percentageOut = [num2str(c) '%%'];
    percentageOut = [percentageOut repmat(' ',1,strPercentageLength-length(percentageOut)-1)];
    nDots = floor(c/100*strDotsMaximum);
    dotOut = ['[' repmat('.',1,nDots) repmat(' ',1,strDotsMaximum-nDots) ']'];
    strOut = [percentageOut dotOut];
    
    % Print it on the screen
    if strCR == -1,
        % Don't do carriage return during first run
        fprintf(strOut);
    else
        % Do it during all the other runs
        fprintf([strCR strOut]);
    end
    
    % Update carriage return
    strCR = repmat('\b',1,length(strOut)-1);
    
else
    % Any other unexpected input
    error('Unsupported argument type');
end
end

function img_log = LogImage(image,hsize,sigma)
%function LogImage: filter the image with the Laplacian of Gaussian filter.
%Input    image                : array, m1*m2
%         hsize                : filter size
%         sigma                : standard deviation
%Refer to matlab doc fspecial for the details.
%Output:  img_log              : array, m1*m2, filtered image
    img = double(squeeze(image));
    if nargin<2
        hsize = [12,12];
    end
    
    if nargin<3
        sigma = 4.0;
    end
    
    Log_filter = -fspecial('log', hsize, sigma); % fspecial creat predefined filter.Return a filter.
                                       
    img_log = imfilter(img, Log_filter, 'symmetric', 'conv');
 
end 

function imgxy = IdentifySpots(img, thresh)
% Extract locations from image
% | Version | Author | Date     | Commit
% | 0.1     | ZhouXY | 18.07.19 | The init version
% | 0.2     | H.F.   | 18.09.05 |
% | 1.0     | ZhouXY | 20.07.05 | Reconstruction
% To Do: Binarize image with locally adaptive thresholding or only take
% threshold but keep graydrade
%We use function LocateSpotCentre_b1 here, which is outside the main file.

% Choose the threshold of image
img_thresh = imbinarize(img,thresh);

% Find connected components in binary image
CC = bwconncomp(img_thresh, 6); % should use 8 connected for 2d image

% Due to cellfun limit, size of img must be a cell form, all inout arguments must be cell form  
s = size(img_thresh);
SizeCell = cell(1,numel(CC.PixelIdxList));
SizeCell(1:end) = {s};

CenterTypeCell = cell(1,numel(CC.PixelIdxList));
CenterTypeCell(1:end) = {'Centroid'};

ImgCell = cell(1,numel(CC.PixelIdxList));
ImgCell(1:end) = {img};

% Find out the centre of worm
[imgy, imgx] = cellfun(@LocateSpotCentre_b1, CC.PixelIdxList, SizeCell, CenterTypeCell, ImgCell);

% center = cell2mat(center);
% center = real(center);

% size(centers)
% [x, y] = ind2sub(s, centers); % Transfer linear index to subscript
% imgx = y;
% imgy = x;

imgxy = cat(2,imgx',imgy');
%imgy = s(2)-imgy; % What is mean? invert the image 
end

    % Return linear index of centroid  
% | Version | Author | Date     | Commit
% | 0.1     | ZhouXY | 18.07.19 | The init version
% | 0.2     | ZhouXY | 20.02.12 | Add 2d Gaussian fitting
% Calculate cell centre
%'Centroid' or '2DGaussian'
% img is a n*m mtricx

function [x,y] = LocateSpotCentre_b1(idx, s, CenterType, img_source)
%img_source = gpuArray(img_source);
format long;
%     DetermineCenter = 'Centeroid';
    switch CenterType
        case 'Centroid'
%             n = s(1);
%             [x,y] = ind2sub(s,idx);
%             leng = length(idx);
%             location = round(sum(x))/leng + n*round(sum(y)/leng-1);
%             % pay attention to round(), it's critical

%             n = s(1);
            [x,y] = ind2sub(s,idx);
            leng = length(idx);
            location = [sum(x)/leng, sum(y)/leng];
            x = sum(x)/leng;
            y = sum(y)/leng;
            
        case '2DGaussian'
            n = s(1);
            [x,y] = ind2sub(s,idx);
            x = (min(x):max(x));
            y = (min(y):max(y));
            Intensities = img_source(x,y);
            [X, Y] = meshgrid(x,y);
            XYdata = zeros(size(X,1),size(Y,2),2);
            XYdata(:,:,1) = X;
            XYdata(:,:,2) = Y;
            location = Gaussian2DFit(XYdata,Intensities);
            location = {location};
%             1/((2*pi)^(D/2)*sqrt(det(Sigma)))*exp(-1/2*(x-Mu)*Sigma^-1*(x-Mu)');
    end
end


function location = Gaussian2DFit(XYdata, Intensities)
    X = XYdata(:,:,1);
    Y = XYdata(:,:,2);
    %change X(1) Y(1) to centorid next time, more close to real location
    StartPoint = [(X(1)+X(end))/2, (Y(1)+Y(end))/2, 5, 5, 0, 1];% follow orders in Gaussian2DFunction, start points 
%     StartPoint = [X(1), Y(1), 5, 5, 0, 1]
    class(Intensities)
    Z = double(Intensities)'; % image intensities in real image
    class(Z)
    options = optimset('MaxFunEvals',20000, 'MaxIter', 2000);
%     options = optimset(options, 'MaxIter',100000,'Display','iter');
    [x,resnorm,residual,exitflag,output,lambda,jacobian] = lsqcurvefit(@Gaussian2DFunction, StartPoint, XYdata, Z, [], [], options);

    CI = nlparci(x,residual,'jacobian',jacobian);% confidence intervals for all arguments
    Confidence_Interval_x = CI(1,1:2);
    Confidence_Interval_y = CI(2,1:2);
    
    location = [x(1:2), Confidence_Interval_x, Confidence_Interval_y];
end

function fun_2D = Gaussian2DFunction(paras, xy)
    %  https://en.wikipedia.org/wiki/Gaussian_function
    % add theta(rotation) argument
    center_x = paras(1);
    center_y = paras(2);
    sigma_x = paras(3);
    sigma_y = paras(4);
    theta = paras(5);
    factor = paras(6);

    x = xy(:,:,1) - center_x;
    y = xy(:,:,2) - center_y;

    x_rot = x*cos(theta) - y*sin(theta);
    y_rot = x*sin(theta) + y*cos(theta);
    
    pre_fun = (x_rot/sigma_x).^2 + (y_rot/sigma_y).^2;
    fun_2D = factor*exp(-pre_fun/2);
    %  location = round(sum(x))/leng + n*round(sum(y)/leng-1);

end












