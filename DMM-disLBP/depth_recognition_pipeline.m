% Depth Maps-Based Action Recognition
% Acknowledgement: DMM-disLBP is based on two existing methods:
% DMM-LBP and discriminative LBP. So we borrowed many codes and functions 
% from their codes, which can be downloaded as follows:
% DMM-LBP: https://sites.google.com/site/chenresearchsite/publications
% disLBP: http://www.ee.oulu.fi/~gyzhao/
clear all
clc
dbstop if error
addpath(genpath('DMM-disLBP/code'))
addpath(genpath('DMM-disLBP/data'))

%% Setting
NumAct = 20;          % number of actions in each subset
row = 240;
col = 320;
num_subject = 10;    % maximum number of subjects for one action
num_experiment = 3;  % maximum number of experiments performed by one subject

frame_remove = 2;    % remove the first and last a few frame (static posture)
                                       
fix_size_front = [102;54]; fix_size_side = [102;75]; fix_size_top = [75;54];

%% Depth Motion Map
disp(['Creating Depth Motion Map...'])
load DMM-disLBP/data/Action3D_sample_list
front = cell(length(sample_list),1);
side = cell(length(sample_list),1);
top = cell(length(sample_list),1);

subject_label = zeros(length(sample_list),1);
actions_label = zeros(length(sample_list),1);

for i = 1:length(sample_list)
        
    depth_name = sprintf('DMM-disLBP/data/Action3D-bak/%s_sdepth.mat',sample_list{i});
    
    if exist(depth_name,'file')        
        
        load(depth_name);
        depth = depth(:,:,frame_remove+1:end-frame_remove);       
        [front{i}, side{i}, top{i}] = depth_projection(depth);
      
        front{i} = resize_feature(front{i},fix_size_front);
        side{i}  = resize_feature(side{i},fix_size_side);
        top{i}   = resize_feature(top{i},fix_size_top);

        clear depth     
        
        %%%% record subject index
        subject_label(i) = str2double(sample_list{i}(6:7));
        %%%% record sample label
        actions_label(i) = str2double(sample_list{i}(2:3));
    end
                      
end
% save('DMM-disLBP/MSRAction3D_experiments/DMM.mat','front','side','top');
% save('DMM-disLBP/MSRAction3D_experiments/label.mat','subject_label','actions_label');
% data = load('DMM-disLBP/MSRAction3D_experiments/DMM.mat');
% front = data.front;
% side = data.side;
% top = data.top;
% data = load('DMM-disLBP/MSRAction3D_experiments/label.mat');
% subject_label = data.subject_label;
% actions_label = data.actions_label;

%% LEARNING PHASE 
disp(['Performing disLBP...'])
%   learn the most discriminantive subset of patterns by considering feature robustness, 
%          feature discriminant power, and feature representation capability 
% training samples
train_index = [1, 3, 5, 7, 9]; % training subject numbers
tr_subject_ind = ismember(subject_label,train_index);
tr_action = actions_label(tr_subject_ind);
tr_number = sum(tr_subject_ind);

tr_front = front(tr_subject_ind);
tr_side = side(tr_subject_ind);
tr_top = top(tr_subject_ind);

% LBP parameters
num_point = 4; % number of sampling points
radius = 1;
mapping = getmapping(num_point,'u2');  %UniformLBP

f_row_blk = 4;
f_col_blk = 2;

s_row_blk = 4;
s_col_blk = 3;

t_row_blk = 3;
t_col_blk = 2;

Total_Dominant_Type_front = [];
Total_Dominant_Type_side = [];
Total_Dominant_Type_top = [];

disp('Conducting Learning Stage...');
%  This parameter controls how many dominant patterns will be selected from
%   each individual image, default is 0.9, means the subset of patterns
%   which can occupy 90% amount all the possible patterns will be selected
Thres_Val = 0.9;

for i = 1:tr_number
    %    Layer 1: Extract dominant patterns from each image for Feature robustness
     [Dominant_Type_Hist_front] = LearnDominantTypeLBP(tr_front{i},f_row_blk, f_col_blk, radius,num_point,Thres_Val,mapping);
     [Dominant_Type_Hist_side] = LearnDominantTypeLBP(tr_side{i},s_row_blk, s_col_blk,radius,num_point,Thres_Val,mapping);
     [Dominant_Type_Hist_top] = LearnDominantTypeLBP(tr_top{i},t_row_blk, t_col_blk,radius,num_point,Thres_Val,mapping);
      
     if(i == 1||tr_action(i-1) ~= tr_action(i))  %Begin of a class
        Class_Dominant_ID_List_front = Dominant_Type_Hist_front;
        Class_Dominant_ID_List_side = Dominant_Type_Hist_side;
        Class_Dominant_ID_List_top = Dominant_Type_Hist_top;
                
     else
       %        Layer 2: Calculate class-specific dominant pattern sets 
       for j = 1:size(Dominant_Type_Hist_front,1)
             Class_Dominant_ID_List_front{j} = RemoveDominantOutlier(Class_Dominant_ID_List_front{j},Dominant_Type_Hist_front{j});
       end
       
       for j = 1:size(Dominant_Type_Hist_side,1)
             Class_Dominant_ID_List_side{j} = RemoveDominantOutlier(Class_Dominant_ID_List_side{j},Dominant_Type_Hist_side{j});
       end
        
       for j = 1:size(Dominant_Type_Hist_top,1)
             Class_Dominant_ID_List_top{j} = RemoveDominantOutlier(Class_Dominant_ID_List_top{j},Dominant_Type_Hist_top{j});
       end
                  
     end
     
     if(i == tr_number||tr_action(i+1)~= tr_action(i))  %End of a class
        %   Layer 3: Calculate the global dominant pattern sets of interest
         if(size(Total_Dominant_Type_front,1)==0)
            Total_Dominant_Type_front = Class_Dominant_ID_List_front;
            Total_Dominant_Type_side = Class_Dominant_ID_List_side;
            Total_Dominant_Type_top = Class_Dominant_ID_List_top;

         else
             for j = 1:size(Class_Dominant_ID_List_front,1)
                Total_Dominant_Type_front{j} = MergeDominantType(Total_Dominant_Type_front{j},Class_Dominant_ID_List_front{j});
             end
             
             for j = 1:size(Class_Dominant_ID_List_side,1)
                Total_Dominant_Type_side{j} = MergeDominantType(Total_Dominant_Type_side{j},Class_Dominant_ID_List_side{j});
             end
             
             for j = 1:size(Total_Dominant_Type_top,1)
                Total_Dominant_Type_top{j} = MergeDominantType(Total_Dominant_Type_top{j},Class_Dominant_ID_List_top{j});
             end
             
        end
     end
     
end

%%   TRAINING PHASE
disp('Conducting Training Stage...');

global_feature = [ ];

% Here begins the feature extraction stage
for i = 1:tr_number
    
    FrontHist = get_LBP_fea_global(tr_front{i}, f_row_blk, f_col_blk, radius, num_point, mapping);
    FrontHist = reshape(FrontHist,mapping.num,size(FrontHist,1)/mapping.num);
    
    feature_hist_front = [];
    for j = 1:size(Total_Dominant_Type_front,1) 
        feature_hist_front = [feature_hist_front;FrontHist(Total_Dominant_Type_front{j}+1,j)];
    end    
    
    SideHist = get_LBP_fea_global(tr_side{i}, s_row_blk, s_col_blk, radius, num_point, mapping);
    SideHist = reshape(SideHist,mapping.num,size(SideHist,1)/mapping.num);

    feature_hist_side = [];
    for j = 1:size(Total_Dominant_Type_side,1)
        feature_hist_side =  [feature_hist_side;SideHist(Total_Dominant_Type_side{j}+1,j)];
    end    
    
    TopHist = get_LBP_fea_global(tr_top{i}, t_row_blk, t_col_blk, radius, num_point, mapping);
    TopHist = reshape(TopHist,mapping.num,size(TopHist,1)/mapping.num);
   
    feature_hist_top = [];
    for j = 1:size(Total_Dominant_Type_top,1)
        feature_hist_top=  [feature_hist_top;TopHist(Total_Dominant_Type_top{j}+1,j)];
    end     
           
    feature_vector = [feature_hist_front;feature_hist_side;feature_hist_top];
    global_feature = [global_feature,feature_vector];
    
end

%   Normalization of each dimension of features 
Samples_Train = NormalizeFea(global_feature,1);

%%   TESTING PHASE
disp('Conducting Testing Stage...');
% test samples
test_index = [2, 4, 6, 8, 10]; % training subject numbers
te_subject_ind = ismember(subject_label,test_index);
te_action = actions_label(te_subject_ind);
te_number = sum(te_subject_ind);

te_front = front(te_subject_ind);
te_side = side(te_subject_ind);
te_top = top(te_subject_ind);

global_feature = [ ];

% Here begins the feature extraction stage
for i = 1:te_number
   FrontHist = get_LBP_fea_global(te_front{i}, f_row_blk, f_col_blk, radius, num_point, mapping);
    FrontHist = reshape(FrontHist,mapping.num,size(FrontHist,1)/mapping.num);
    
    feature_hist_front = [];
    for j = 1:size(Total_Dominant_Type_front,1) 
        feature_hist_front = [feature_hist_front;FrontHist(Total_Dominant_Type_front{j}+1,j)];
    end    
    
    SideHist = get_LBP_fea_global(te_side{i}, s_row_blk, s_col_blk, radius, num_point, mapping);
    SideHist = reshape(SideHist,mapping.num,size(SideHist,1)/mapping.num);

    feature_hist_side = [];
    for j = 1:size(Total_Dominant_Type_side,1)
        feature_hist_side =  [feature_hist_side;SideHist(Total_Dominant_Type_side{j}+1,j)];
    end    
    
    TopHist = get_LBP_fea_global(te_top{i}, t_row_blk, t_col_blk, radius, num_point, mapping);
    TopHist = reshape(TopHist,mapping.num,size(TopHist,1)/mapping.num);
   
    feature_hist_top = [];
    for j = 1:size(Total_Dominant_Type_top,1)
        feature_hist_top=  [feature_hist_top;TopHist(Total_Dominant_Type_top{j}+1,j)];
    end     
           
    feature_vector = [feature_hist_front;feature_hist_side;feature_hist_top];
    global_feature = [global_feature,feature_vector];
end

%  Normalization of each dimension of features 
Samples_Test = NormalizeFea(global_feature,1);

%%  CLASSIFICATION STAGE
train_data = [tr_action,Samples_Train'];
test_data = [te_action,Samples_Test'];

% save('DMM-disLBP/data/Action3DResult.mat','train_data','test_data');
% data = load('DMM-disLBP/data/Action3DResult.mat');
% train_data = data.train_data;
% test_data = data.test_data;

%%%%%% KELM Classification %%%%%%%
para_C = 1000; 
gamma = 10.5;
data = load('DMM-disLBP/data/action_sets.mat');
action_sets = data.action_sets;
n_action_sets = size(action_sets,2);
accuracy = cell(n_action_sets,1);

for set = 1:n_action_sets
        actions = unique(action_sets{set});
        tr_actions_ind = ismember(train_data(:,1),actions);
        te_actions_ind = ismember(test_data(:,1),actions);
        
        subset_train_data = train_data(tr_actions_ind,:);
        subset_test_data = test_data(te_actions_ind,:);
        
        [TrainingTime, TestingTime, TrainAC, TestAC, TY] = elm_kernel(subset_train_data, subset_test_data, 1, para_C, 'RBF_kernel',gamma);
        fprintf('Test Accuracy = %f\n', TestAC);
        save(['DMM-disLBP/MSRAction3D_experiments/Depth-S',num2str(set)], 'TY');
end

