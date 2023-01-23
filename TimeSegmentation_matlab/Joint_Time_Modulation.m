function [joint_variance, joint_names, joint_times, joint_time_idxs] = ...
    Joint_Time_Modulation(xds, joint_choice, joint_param, norm_joints, time_choice)
    
%% Basic settings, some variable extractions, & definitions

% Do you want to find the principle components ('Yes' or 'No')
Use_PCA = 'Yes';

% Define the method to compare the joint modulation ('Var' or 'Perc')
mod_method = 'Var';

% What method do you want to use? (#, 'STD', 'PCTL')
time_method = 'PCTL';

% Frame rate (in seconds)
sec_per_frame = 0.033;

% How large of a time window to you want to scroll through? (in seconds)
time_window = 2;%5; %
% How many steps do you want per window (in seconds)
time_steps = sec_per_frame;%1; %

% What do you want to plot?
Plot_Figs = 1;

%% Joint angle vs joint velocity
if strcmp(joint_param, 'Angles')
    joint_var = xds.joint_angles;
elseif strcmp(joint_param, 'Velocity')
    joint_var = diff(xds.joint_angles) / sec_per_frame;
end

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

if strcmp(norm_joints, 'Yes')
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
end

%% If you are using the principle components
if strcmp(Use_PCA, 'Yes')
    
    %eigen_vectors
    [~, transformed_joint_var, eigen_values] = pca(joint_var);
    joint_idx = 1;

    % Display how much variance is accounted for
    variance_accounted = eigen_values(1,1) / sum(eigen_values);
    fprintf('PC1 accounts for %0.1f percent of the variance \n', variance_accounted*100)

    joint_var = transformed_joint_var(:, joint_idx);
    joint_names = struct([]);
    joint_names{1,1} = 'PC1';

else
    % Find the top units
    joint_names = Joint_Modulation_Check(xds, mod_method);

    % Convert the joint names into one cell
    all_joint_names = struct([]);
    % Concatenate all the information
    cc = 1;
    for xx = 1:length(joint_names)
        for jj = 1:length(joint_names{xx})
            all_joint_names{cc,1} = char(joint_names{xx}(jj));
            cc = cc + 1;
        end
    end
    % Rename the now merged variables
    joint_names = unique(all_joint_names, 'Stable');
end

%% Define the output variable
joint_times = struct([]);
joint_time_idxs = struct([]);
mod_per_window = struct([]);

%% Loop through all units
for jj = 1:length(joint_names)

    % Display the joint name
    disp(string(joint_names(jj)));

    if strcmp(Use_PCA, 'No')
        
        % Getting the spike timestamps
        joint_idx = strcmp(xds.joint_names, joint_names{jj});

    end
    
    %% Moving window through the joint angles
    
    % Number of window to scroll through
    window_size = time_window / sec_per_frame;
    step_size = time_steps / sec_per_frame;
    [~, sliding_array, array_idxs] = Sliding_Window(joint_var(:,joint_idx), window_size, step_size);

     % Percentile
    if strcmp(mod_method, 'Perc')
        for ii = 1:length(sliding_array)
            % Find the 5th percentile
            min_perc = prctile(sliding_array{ii}, 5);
            % Find the 90th percentile
            max_perc = prctile(sliding_array{ii}, 90);
            % Find the modulation
            mod_per_window{jj}(ii) = max_perc - min_perc;
        end
    end

    % Variance
    if strcmp(mod_method, 'Var')
        for ii = 1:length(sliding_array)
            mod_per_window{jj}(ii) = var(sliding_array{ii}, 'omitnan');
        end
    end

    %% Find the time of joint angle modulation

    % Find the max or minimum modulation
    mod_idx = struct([]);
    if strcmp(time_choice, 'Max')
        if strcmp(time_method, 'STD')
            mod_times = mean(mod_per_window{jj}) + 3*std(mod_per_window{jj});
        elseif strcmp(time_method, 'PCTL')
            mod_times =  prctile(mod_per_window{jj}, 95);
        elseif isnumeric(time_method)
            mod_times =  maxk(mod_per_window{jj}, time_method);
        end
    end
    if strcmp(time_choice, 'Min')
        if strcmp(time_method, 'STD')
            mod_times = mean(mod_per_window{jj}) - 3*std(mod_per_window{jj});
        elseif strcmp(time_method, 'PCTL')
            mod_times =  prctile(mod_per_window{jj}, 15);
        elseif isnumeric(time_method)
            mod_times =  mink(mod_per_window{jj}, time_method);
        end
    end

    % Find the time of modulation
    if strcmp(time_method, 'STD') || strcmp(time_method, 'PCTL')
        if strcmp(time_choice, 'Max')
            mod_idx = find(mod_per_window{jj} >= mod_times);
        end
        if strcmp(time_choice, 'Min')
            mod_idx = find(mod_per_window{jj} <= mod_times);
        end
        joint_time_idxs{jj,1} = [];
        for ii = 1:length(mod_idx)
            joint_time_idxs{jj,1} = cat(2, joint_time_idxs{jj,1}, array_idxs{mod_idx(ii)});
        end
        joint_time_idxs{jj,1} = unique(joint_time_idxs{jj,1});
        joint_times{jj,1} = xds.joint_angle_time_frame(joint_time_idxs{jj,1});
    elseif isnumeric(time_method)
        loop_length = length(time_method);
        for tt = 1:loop_length
            mod_idx{tt,1} = find(mod_per_window{jj} == mod_times(tt));
            for ii = 1:length(mod_idx{tt,1})
                joint_times{jj,1}{tt,1}(ii,1) = ...
                    xds.joint_angle_time_frame(array_idxs{mod_idx{tt,1}(ii)}(1));
                joint_times{jj,1}{tt,1}(ii,2) = ...
                    xds.joint_angle_time_frame(array_idxs{mod_idx{tt,1}(ii)}(end));
            end
        end
    end

end % End of joint loop

%% Plot the variance of the 1st PCA through time
joint_variance = mod_per_window{1,1};
    
array_padding = zeros(1, round(window_size / 2));
joint_variance = cat(2, array_padding, joint_variance);
joint_variance = cat(2, joint_variance, array_padding);

if isequal(Plot_Figs, 1)
    figure
    hold on

    time = xds.joint_angle_time_frame;
    plot(time, joint_variance)
    if strcmp(time_method, 'STD') || strcmp(time_method, 'PCTL')
        line([time(1), time(end)], [mod_times, mod_times], ...
            'LineWidth', 1, 'color', 'r');
    end
    
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
end


