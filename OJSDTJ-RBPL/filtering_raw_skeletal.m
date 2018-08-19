% This code is used for implementing Savitzky-Golay smoothing filter.
% Author: Haomiao Ni
clc;
clear;
data = load('data/skeletal_data');
skeletal_data = data.skeletal_data;
skeletal_data_validity = data.skeletal_data_validity;

% setting
n_actions = 20;
n_subjects = 10;
n_instances = 3;

filter_skeletal_data = cell(size(skeletal_data));
action_labels = [];
subject_labels = [];
max_frame = -1;
max_filter_frame = -1;
for action = 1:n_actions
    for subject = 1:n_subjects
        for instance = 1:n_instances
            if (skeletal_data_validity(action, subject, instance))    
                action_labels = [action_labels action];
                subject_labels = [subject_labels subject];
                joint_locations = skeletal_data{action, subject, instance}.joint_locations;%3*20*FRAME
                
                n_frame = size(joint_locations,3);
                if n_frame > max_frame
                    max_frame = n_frame;
                end
				
				%Savitzky-Golay smoothing filter
                filter_joint_locations = zeros(size(joint_locations));
                for frame = 3:n_frame-2
                    filter_joint_locations(:,:,frame) = (-3*joint_locations(:,:,frame-2)+12*joint_locations(:,:,frame-1)+17*joint_locations(:,:,frame)+12*joint_locations(:,:,frame+1)-3*joint_locations(:,:,frame+2))./35;
                end
                filter_joint_locations = filter_joint_locations(:,:,3:n_frame-2);
				
                if size(filter_joint_locations, 3) > max_filter_frame
                    max_filter_frame = size(filter_joint_locations, 3);
                end
                filter_skeletal_data{action, subject, instance}.filter_joint_locations =  filter_joint_locations;
            end
        end
    end
end
disp(['max_frame: ', mat2str(max_frame)]);
disp(['max_filter_frame: ', mat2str(max_filter_frame)]);
save('OJSDTJ-RBPL/data/filter_skeletal_data','filter_skeletal_data','skeletal_data_validity');
action_labels = action_labels';
subject_labels = subject_labels';
save('OJSDTJ-RBPL/data/labels', 'action_labels', 'subject_labels');