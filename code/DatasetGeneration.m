clear all;
format long;
% Main function to generate single track dataset based on trackmate .csv
%
% | Version | Author | Date     | Commit
% | 0.1     | ZhouXY | 20.05.01 | The init version
% generate some empty folders, encountering boundaries, need to be fixed
tic;

dataset_root_path = 'C:\Users\ZXY\Desktop\ASU\Lab\CellClassfier\dataset_EvU\train\Urine\';
data0 = readtable(['D:\200122\Urine\Sample1\SSC\40fps\4\ImageJ_ZXY\Spots_in_tracks_statistics.csv']);
data01(:,1)= data0.TRACK_ID;
data01(:,2)= data0.POSITION_X; % x
data01(:,3)= data0.POSITION_Y; % y
data01(:,4)= data0.FRAME;

all_images = LoadImages('D:\200122\Urine\Sample1\SSC\40fps\4\');

% need to be improved
track_start = 1;
pre_ID = data01(1,1);
track_len = 0;
positions = [];

data_num = 0;


for i = 2:length(data01(:,1))
    if data01(i,1) == pre_ID
        track_len = track_len + 1;
        continue
    else
%         ZXY
        cutoff = 500;
        if track_len > cutoff
            positions = data01(track_start:track_start+cutoff-1,:);
            GenerateSingleTrackImages(dataset_root_path, positions, all_images);
%             GenerateSingleTrackImages_aug(dataset_root_path, positions, all_images);
            data_num = data_num+1;
            
            %delete later
%             ZXY
            if data_num>400
                break
            end
            
        end
        pre_ID = data01(i,1);
        track_start = i;
        track_len = 0;
    end
end

function GenerateSingleTrackImages_aug(dataset_path, pos, all_images)
    
    sample_path = [dataset_path,'ID',num2str(pos(1,1), '%06d')]
    sample_path_r090 = [dataset_path,'ID',num2str(pos(1,1), '%06d'),'_r090'];
    sample_path_r180 = [dataset_path,'ID',num2str(pos(1,1), '%06d'),'_r180'];
    sample_path_r270 = [dataset_path,'ID',num2str(pos(1,1), '%06d'),'_r270'];
    sample_path_T = [dataset_path,'ID',num2str(pos(1,1), '%06d'),'_T'];
    sample_path_T_r090 = [dataset_path,'ID',num2str(pos(1,1), '%06d'),'_T','_r090'];
    sample_path_T_r180 = [dataset_path,'ID',num2str(pos(1,1), '%06d'),'_T','_r180'];
    sample_path_T_r270 = [dataset_path,'ID',num2str(pos(1,1), '%06d'),'_T','_r270']
    
    mkdir(sample_path);
    mkdir(sample_path_r090);
    mkdir(sample_path_r180);
    mkdir(sample_path_r270);
    mkdir(sample_path_T);
    mkdir(sample_path_T_r090);
    mkdir(sample_path_T_r180);
    mkdir(sample_path_T_r270);
    
    for i = 1:length(pos(:,1))
        try
            img = squeeze(all_images(pos(i,4)+1,:,:));
            r = 4;
            x = floor(pos(i,2));
            y = floor(pos(i,3));
            single_particle = img(y-r:y+r+1,x-r:x+r+1);
            imwrite(uint16(single_particle), [sample_path '\'  num2str(i, '%06d')  '.tif']);
            
            single_particle_r090 = rot90(single_particle,1);
            imwrite(uint16(single_particle_r090), [sample_path_r090 '\'  num2str(i, '%06d')  '.tif']);
            
            single_particle_r180 = rot90(single_particle,2);
            imwrite(uint16(single_particle_r180), [sample_path_r180 '\'  num2str(i, '%06d')  '.tif']);
            
            single_particle_r270 = rot90(single_particle,3);
            imwrite(uint16(single_particle_r270), [sample_path_r270 '\'  num2str(i, '%06d')  '.tif']);
            
            single_particle_T = single_particle';
            imwrite(uint16(single_particle_T), [sample_path_T '\'  num2str(i, '%06d')  '.tif']);
            
            single_particle_T_r090 = rot90(single_particle',1);
            imwrite(uint16(single_particle_T_r090), [sample_path_T_r090 '\'  num2str(i, '%06d')  '.tif']);
            
            single_particle_T_r180 = rot90(single_particle',2);
            imwrite(uint16(single_particle_T_r180), [sample_path_T_r180 '\'  num2str(i, '%06d')  '.tif']);
            
            single_particle_T_r270 = rot90(single_particle',3);
            imwrite(uint16(single_particle_T_r270), [sample_path_T_r270 '\'  num2str(i, '%06d')  '.tif']);
            
            
        catch
            rmdir(sample_path,'s');
            rmdir(sample_path_r090,'s');
            rmdir(sample_path_r180,'s');
            rmdir(sample_path_r270,'s');
            rmdir(sample_path_T,'s');
            rmdir(sample_path_T_r090,'s');
            rmdir(sample_path_T_r180,'s');
            rmdir(sample_path_T_r270,'s');
            %break for loop for particle moves to boundaries
            break
        end
    end
end
function GenerateSingleTrackImages(dataset_path, pos, all_images)
    
    sample_path = [dataset_path,'S1R4_ID',num2str(pos(1,1), '%06d')]
    mkdir(sample_path);
    for i = 1:length(pos(:,1))
        try
            img = squeeze(all_images(pos(i,4)+1,:,:));
            r = 4;
            x = floor(pos(i,2));
            y = floor(pos(i,3));
            single_particle = img(y-r:y+r+1,x-r:x+r+1);
            single_particle = rot90(single_particle,1);
            imwrite(uint16(single_particle), [sample_path '\'  num2str(i, '%06d')  '.tif']);
        catch
            rmdir(sample_path,'s');
            %break for loop for particle moves to boundaries
            break
        end
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
