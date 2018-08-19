%  Skeleton-Based Human Action Recognition
%  Author: Haomiao Ni
%  Acknowledgement: Our main contribution is to propose an 
%  Adaptive Optimal Joint Selection Model to remove redunctant
%  joints. And then we leveraged a state-of-the-art apporach to 
%  describe the remaining key joints. So we borrowed some functions
%  and datas from the code of this apporach, which can be downloaded from
%  http://ravitejav.weebly.com/kbac.html
clear all
clc
dbstop if error

addpath(genpath('OJSDTJ-RBPL/code'))
addpath(genpath('OJSDTJ-RBPL/data'))

data_dir = 'OJSDTJ-RBPL/data';

n_frames = 72; % max frame
n_actions = 20;

exp_dir= 'OJSDTJ-RBPL/MSRAction3D_experiments';
OJSDTJ_dir = [exp_dir, '/OJSDTJ'];
DV_dir = [exp_dir, '/Decision-Values'];
if (exist(exp_dir, 'dir') ~= 7)
    mkdir(exp_dir);
    mkdir(OJSDTJ_dir);
    mkdir(DV_dir);
end
addpath(genpath(exp_dir));

% Setting parameters
opt_joint_thre = 0.99;

% Training and test subjects
tr_subjects = [1, 3, 5, 7, 9];
te_subjects = [2, 4, 6, 8, 10];

% labels
load([data_dir, '/labels'], 'action_labels', 'subject_labels');
tr_subject_ind = ismember(subject_labels, tr_subjects);
te_subject_ind = ismember(subject_labels, te_subjects);

% dataset
load([data_dir, '/action_sets'], 'action_sets');

% %% Optimal Joint Selection
% disp ('Optimal Joing Selecting');
% % Selecting joints based on their energy
% load([data_dir, '/body_model']);
% bones = body_model.bones;
% relative_body_part_pairs = body_model.relative_body_part_pairs;
% dominant_body_part_set = OJSDTJ(tr_subjects, data_dir, bones, relative_body_part_pairs, opt_joint_thre);
% 
% %% OJSDTJ-RBPL Feature Extraction
% disp('Extracting OJSDTJ-RBPL for each action sequence');
% for i = 1:n_actions
%     disp(['OJSDTJ-RBPL for action ', mat2str(i)]);
%     target_body_model.relative_body_part_pairs = relative_body_part_pairs(dominant_body_part_set{i}, :);
%     % Using a state-of-the-art approach to describe selected joints
%     OJSDTJ_Fea = generate_features(data_dir,  n_frames, target_body_model);
%     Fea_Name = ['/OJSDTJ-A', mat2str(i)];
%     save([OJSDTJ_dir, Fea_Name], 'OJSDTJ_Fea');
% end

%% Running recognition for each subset of MSRAction3D
for set = 1:3
    disp(['Processing set ', mat2str(set)])
    actions = unique(action_sets{set});
    n_actions = length(actions);
    subaction_ind = ismember(action_labels, actions);
    tr_ind = tr_subject_ind&subaction_ind;
    te_ind = te_subject_ind&subaction_ind;
    
    % one-vs-all ELM
    test_prediction_prob = zeros(n_actions,sum(te_ind));
    for i = 1:n_actions
        % get the labels of all samples
        target_action = actions(i);
        action_ind = (action_labels == target_action);
        temp_action_labels = 2*ones(size(action_labels));
        temp_action_labels(action_ind) = 1;
        % get the training labels and testing labels
        tr_labels = temp_action_labels(tr_ind);
        te_labels = temp_action_labels(te_ind);
        %% DTW
        disp(['temporal modeling for action ', mat2str(target_action)]);
        Fea_Name = ['/OJSDTJ-A', mat2str(target_action)];
        load([OJSDTJ_dir, Fea_Name]);
        DTW_Fea = get_warped_features(OJSDTJ_Fea, action_labels,...
            subject_labels, tr_subjects, target_action);
        % Normalization
        N = length(DTW_Fea);
        S = size(DTW_Fea{1});
        F = zeros(S(1)*S(2), N);
        for j = 1:N
            temp = DTW_Fea{j};
            F(:,j) = temp(:);
        end
        DTW_Fea = NormalizeFea(F,1);
        DTW_Fea = DTW_Fea';
     
        tr_feature = DTW_Fea(tr_ind,:);
        te_feature = DTW_Fea(te_ind,:);
        
        %% ELM
        train_data = [tr_labels tr_feature];
        test_data= [te_labels te_feature];
        
        [~, ~, test_prob] = elm_kernel(train_data, test_data, 1, 1000, 'lin_kernel', 10.5);
        test_prediction_prob(i, :) = test_prob(1,:);
    end
    DV_Name = ['/Skeletal-S', mat2str(set)];
    save([DV_dir, DV_Name], 'test_prediction_prob');
    [~, ind] = max(test_prediction_prob);
    final_predicted_labels = actions(ind);
    
    test_labels = action_labels(te_ind);
    total_accuracy = length(find( test_labels == final_predicted_labels'))...
        / sum(te_ind);
    disp(['Test accuracy for set ', mat2str(set), ' is ', mat2str(total_accuracy)])
    [max_prob,max_res] = max(test_prediction_prob);
end