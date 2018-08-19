% DFMSDV: Decision-Level Fusion Based on the Maximum Sum of 
% Decision Values
% Author: Haomiao Ni
% This code is used for fusing our OJSDTJ-RBPL and DMM-disLBP.
% The idea is to first add up decision values from these two methods
% and second output the maximum and utilize its indice for predicition. 
clear all
clc
addpath(genpath('OJSDTJ-RBPL/MSRAction3D_experiments/Decision-Values'))
addpath(genpath('DMM-disLBP/MSRAction3D_experiments'))
addpath(genpath('OJSDTJ-RBPL/data'))
action_sets = load('OJSDTJ-RBPL/data/action_sets');
action_sets = action_sets.action_sets;
load(['OJSDTJ-RBPL/data/labels'], 'action_labels', 'subject_labels');
te_subjects = [2, 4, 6, 8, 10];
te_subject_ind = ismember(subject_labels, te_subjects);
for set = 1:3
    actions = unique(action_sets{set});
    subaction_ind = ismember(action_labels, actions);
    te_ind = te_subject_ind&subaction_ind;
    
    skeletal_prob = load(['OJSDTJ-RBPL/MSRAction3D_experiments/Decision-Values/Skeletal-S',num2str(set)]);    
    skeletal_prob = skeletal_prob.test_prediction_prob;
    
    depth_prob = load(['DMM-disLBP/MSRAction3D_experiments/Depth-S',num2str(set)]);
    depth_prob = depth_prob.TY;
    
    prob = skeletal_prob+depth_prob;

    [~,tempind] = max(prob);
    predicted_labels = actions(tempind)';
    
    test_labels = action_labels(te_ind);

    accuracy(set) = sum(predicted_labels==test_labels)/length(test_labels);
	disp(['DFMSDV accuracy for set ', num2str(set), ' is ', num2str(accuracy(set))]);
end    