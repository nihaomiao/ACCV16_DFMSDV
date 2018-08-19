% Adaptive Optimal Joint Selection Model
% Author: Haomiao Ni
function dominant_body_part_set = OJSDTJ(tr_subjects, data_dir, bones, relative_body_part_pairs, opt_joint_thre)
    % loading labels
    load( [data_dir, '/labels'], 'action_labels', 'subject_labels');

    % loading filtered joint positions
    load([data_dir, '/filter_skeletal_data']);

    % training set
    tr_subject_ind = ismember(subject_labels,tr_subjects);
    tr_num = sum(tr_subject_ind);

	% setting
    n_subjects = 5;
    n_actions = 20;
    n_instances = 3;
    n_joint = 20;

    % Layer 1
    % 1. Calculating the energy of each joint for each sequence
    SampleEnergy = zeros(tr_num,n_joint);
    count = 1;
    for action = 1:n_actions
        for subject_ind = 1:n_subjects
            for instance = 1:n_instances
                subject = tr_subjects(subject_ind);
                if(skeletal_data_validity(action,subject,instance))
                    Sample = filter_skeletal_data{action,subject,instance}.filter_joint_locations; %3*20*n_frame
                    n_frame = size(Sample,3);
                    % using tangent vector to represent joint positions
                    TangentVec = zeros(size(Sample,1),size(Sample,2),n_frame-1);
                    for frame = 2:n_frame
                        TangentVec(:,:,frame-1) = Sample(:,:,frame) - Sample(:,:,frame-1);
                    end
                    % calculating the moving distance of each joint
                    n_joint = size(Sample,2);
                    DisVec = zeros(n_joint,n_frame-1);
                    for joint = 1: n_joint
                        DisVec(joint,:) = sum(TangentVec(:,joint,:).^2);
                        SampleEnergy(count,:) = sum(DisVec,2);
                    end
                    count = count+1;
                end
            end
        end
    end

    tr_actions = action_labels(tr_subject_ind);
    dominant_joint_set = cell(n_actions,1);
    for action = 1:n_actions
        % 2. Determining the dominant joint subset of each training sequence from the
        % training set
        tr_action_ind = ismember(tr_actions,action);
        tr_action_energy = SampleEnergy(tr_action_ind,:);

        tr_action_num = sum(tr_action_ind);
        dominant_joint_subset = cell(tr_action_num,1);
        SortEnergy = cell(tr_action_num,1);
        for i = 1:tr_action_num
            energy = tr_action_energy(i,:);
            energy = energy';

            SortEnergy{i} = [(1:n_joint)' energy];
            SortEnergy{i} = sortrows(SortEnergy{i},-2);

            SumEnergy = sum(energy);
            ThreEnergy = opt_joint_thre*SumEnergy;

            TempEnergy = 0;
            EnergyInd = [];
            for j = 1:n_joint
                TempEnergy = TempEnergy+SortEnergy{i}(j,2);
                if(TempEnergy>=ThreEnergy)
                    break;
                else
                    EnergyInd = [EnergyInd SortEnergy{i}(j,1)];
                end

            end
            dominant_joint_subset{i} = EnergyInd;
        end

        % Layer 2
        % Selecting the discriminative dominant joint set of class
        dominant_joint_set{action} = dominant_joint_subset{1};
        for  i = 2:tr_action_num
            dominant_joint_set{action} = intersect(dominant_joint_set{action},dominant_joint_subset{i});
        end

        % Algorithm 3: generating body part sets
        torso_joint = 4;
        opt_joint = union(torso_joint, dominant_joint_set{action});
        opt_ind = false(19,1);
        for i = 1:19
            temp = intersect(opt_joint,bones(i,:));
            if(~isempty(temp))
                opt_ind(i) = true;
            end
        end
        
        individual_bones = bones(opt_ind, :);
        n_individual_bones = size(individual_bones,1);
        
        n_relative_pairs = size(relative_body_part_pairs,1);
        body_part_ind = false(n_relative_pairs,1);
        
        for pairs = 1:n_relative_pairs
            for i = 1:n_individual_bones
                if(relative_body_part_pairs(pairs,1:2) == individual_bones(i,:))
                    for j = 1:n_individual_bones
                        if(relative_body_part_pairs(pairs,3:4) == individual_bones(j,:))
                            body_part_ind(pairs) = true;
                            break;
                        end
                    end
                end
                
                if(body_part_ind(pairs) == true)
                    break;
                end
            end
        end
        
        dominant_body_part_set{action} = body_part_ind;
    end

end





