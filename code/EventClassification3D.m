datapath='Z:\DataSet\EventDetection3\'; 
fds = fileDatastore(datapath,'ReadFcn',@LoadImages,'IncludeSubfolders',true, 'FileExtensions','.tif');
data = readall(fds);
augmentation = true;
data_normalizarion = true;

for i = 1:size(data, 1)
    
    if data_normalizarion
        X(:,:,:,i) = (data{i}-min(data{i}(:)))/max(data{i}(:));
    else
        X(:,:,:,i) = data{i};
    end
end

X = permute(X, [2,3,1,4]);% h,w,t,#
%%
perm = randperm(2000,20);
for i = 1:size(X,3)

    for j = 1:20
        subplot(4,5,j);
        imshow(X(:,:,i,perm(j)), 'DisplayRange',[0,1], 'InitialMagnification', 400);
    end
    drawnow
end
%%
% pay attention to 100 here, it is the sample number per class
Y = categorical(cat(1, ones(1000,1), zeros(3000,1)));

if augmentation
    X = cat(4,X,permute(X,[2,1,3,4]));
    Y = cat(1,Y,Y);
end
% shuffle
p = randperm(size(X,4));
X = X(:,:,:,p);
Y = Y(p);
%split 
X_train = X(:,:,:,1:7800);
Y_train = Y(1:7800);
X_val = X(:,:,:,7801:end);
Y_val = Y(7801:end);

% figure;
% perm = randperm(200,20);
% for i = 1:20
%     subplot(4,5,i);
%     imshow(fds.Files{perm(i)},'DisplayRange',[0 1600]);
% end

layers_3d =  [ ...
    image3dInputLayer([20 20 40 1])
    convolution3dLayer(5,16,'Stride',4)
    reluLayer
    maxPooling3dLayer(2,'Stride',4)
    fullyConnectedLayer(10)
    softmaxLayer
    classificationLayer];

layers = [
    imageInputLayer([20 20 40])
    
    convolution2dLayer(3,8,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
%     maxPooling2dLayer(2,'Stride',2)
%     
%     convolution2dLayer(3,32,'Padding','same')
%     batchNormalizationLayer
%     reluLayer
    
    fullyConnectedLayer(2)
    softmaxLayer
    classificationLayer];

options = trainingOptions('sgdm', ...
    'InitialLearnRate',0.001, ...
    'MaxEpochs',1, ...
    'Shuffle','every-epoch', ...
    'ValidationData',{X_val, Y_val}, ...
    'ValidationFrequency',2, ...
    'Verbose',1, ...
    'Plots','training-progress');


net = trainNetwork(X_train,Y_train,layers,options);

YPred = classify(net,X_val);
YValidation = Y_val;

accuracy = sum(YPred == YValidation)/numel(YValidation);


function all_images = LoadImages(source_path)
    try

        imges = dir([source_path '*.tif']);
        imge_num = length(imges);
        shapes = size(imread([imges(1).folder '/' imges(1).name]));
        all_images = zeros(imge_num, shapes(1), shapes(2));

        for i = 1:imge_num
            img = imread([imges(i).folder '/' imges(i).name]);
            all_images(i,:,:) = img;

        end
    catch

        info = imfinfo(source_path);
        num_images = numel(info);
        all_images = zeros(num_images, info(1).Width, info(1).Height);

        for k = 1:num_images
            img = imread(source_path, k);
            all_images(k,:,:) = img;
            % ... Do something with image A ...
        end
    end
end


