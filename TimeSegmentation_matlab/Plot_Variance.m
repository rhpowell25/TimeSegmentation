function [joint_variance] = Plot_Variance(xds, joint_choice)
    
%% Basic settings, some variable extractions, & definitions

% Frame rate (in seconds)
sec_per_frame = 0.033;

% How large of a time window to you want to scroll through? (in seconds)
time_window = 2;%5; %
% How many steps do you want per window (in seconds)
time_steps = sec_per_frame;%1; %

joint_var = xds.joint_angles;

%% Joint names

if ~strcmp(joint_choice, 'All')
    joint_name_idxs = [];
    for ii = 1:length(joint_choice)
        temp_idxs = find(contains(xds.joint_names, joint_choice{ii,1}));
        joint_name_idxs = cat(2, joint_name_idxs, temp_idxs);
    end
    joint_var = joint_var(:,joint_name_idxs);
end

%% Normalize joint angles

for ii = 1:width(joint_var)
    min_param = min(joint_var(:,ii));
    if min_param < 0
        joint_var(:,ii) = joint_var(:,ii) + abs(min_param);
    else
        joint_var(:,ii) = joint_var(:,ii) - min_param;
    end
    max_param = prctile(joint_var(:,ii), 99);
    joint_var(:,ii) = joint_var(:,ii) / max_param * 100;
end

%% If you are using the principle components
    
%eigen_vectors
[~, transformed_joint_var, eigen_values] = pca(joint_var);
joint_idx = 1;

% Display how much variance is accounted for
variance_accounted = eigen_values(1,1) / sum(eigen_values);
fprintf('PC1 accounts for %0.1f percent of the variance \n', variance_accounted*100)

joint_var = transformed_joint_var(:, joint_idx);

%% Moving window through the joint angles

% Number of window to scroll through
window_size = time_window / sec_per_frame;
step_size = time_steps / sec_per_frame;
[~, sliding_array, ~] = Sliding_Window(joint_var(:,joint_idx), window_size, step_size);

% Variance
joint_variance = zeros(1,length(sliding_array));
for ii = 1:length(sliding_array)
    joint_variance(ii) = var(sliding_array{ii}, 'omitnan');
end

%% Plot the variance of the 1st PCA through time
    
array_padding = zeros(1, round(window_size / 2));
joint_variance = cat(2, array_padding, joint_variance);
joint_variance = cat(2, joint_variance, array_padding);

figure
hold on

time = xds.joint_angle_time_frame;
plot(time, joint_variance)

if ~strcmp(joint_choice, 'All')
    title_joints = '';
    for ii = 1:length(joint_choice)
        if isequal(ii, 1)
            title_joints = strcat(title_joints, joint_choice{ii});
        else
            title_joints = strcat(title_joints, ',', {' '}, joint_choice{ii});
        end
    end
    fig_title = strcat('Variance of PC1 of', {' '}, title_joints, {' '}, 'Joints');
else
    fig_title = 'Variance of PC1 of All Joints';
end


xlim([time(1), time(end)])

title(fig_title, 'Fontsize', 25);
ylabel('Variance', 'FontSize', 25);
xlabel('Time (sec.)', 'FontSize', 25)



