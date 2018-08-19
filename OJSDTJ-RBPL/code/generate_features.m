function features = generate_features(data_dir,  n_frames, body_model)        
    load([data_dir,  '/filter_skeletal_data'])

    n_subjects = 10;
    n_actions = 20;
    n_instances = 3;

    n_sequences = length(find(skeletal_data_validity));        

    features = cell(n_sequences, 1);
    action_labels = zeros(n_sequences, 1);
    subject_labels = zeros(n_sequences, 1);
    instance_labels = zeros(n_sequences, 1); 

    count = 1;    

    for action = 1:n_actions
        for subject = 1:n_subjects
            for instance = 1:n_instances
                if (skeletal_data_validity(action, subject, instance))
                    joint_locations = filter_skeletal_data{action, subject, instance}.filter_joint_locations;
                    features{count} =  get_se3_lie_algebra_features(joint_locations, body_model,...
                                                        n_frames, 'relative_pairs');
                    action_labels(count) = action;       
                    subject_labels(count) = subject;
                    instance_labels(count) = instance;
                    count = count + 1;
                end
            end
        end
    end
end

      
