function [variance_times] = Unit_Joint_Time_Modulation(xds)
    
%% Basic settings, some variable extractions, & definitions

% Do you want to use joint angles or joint velocity ('Angles' or 'Velocity')
joint_param = 'Velocity';

% Define the method to compare the joint modulation ('Var' or 'Perc')
mod_method = 'Var';

% How many time frames (#)
time_num = 5;

% Seconds per frame
sec_per_frame = 0.033;

% Bin size (in seconds)
bin_width = sec_per_frame; %0.2;

% How large of a time window to you want to scroll through? (in seconds)
time_window = 30;
% How many steps do you want per window (in seconds)
time_steps = 30;

%% Joint angle vs joint velocity
if strcmp(joint_param, 'Angles')
    joint_var = xds.joint_angles;
elseif strcmp(joint_param, 'Velocity')
    joint_var = diff(xds.joint_angles) / sec_per_frame;
end

%% Binning the spikes & finding the firing rate

% Number of bins
n_bins = length(joint_var);

% Binning
binned_fire_rate = zeros(n_bins, length(xds.spikes));
for ii = 1:length(xds.spikes)
    spikes = xds.spikes{ii};
    [binned_spikes, ~] = histcounts(spikes, n_bins);
    % Averaging the hist spikes
    binned_fire_rate(:,ii) = binned_spikes / bin_width;
end

firing_rate = binned_fire_rate';

%% If you are using the principle components

[~, transformed_joint_var, eigen_values] = pca(joint_var);
joint_idx = 1;

% Display how much variance is accounted for
variance_accounted = eigen_values(1,1) / sum(eigen_values);
fprintf('PC1 accounts for %0.1f percent of the variance \n', variance_accounted*100)

joint_var = transformed_joint_var(:, joint_idx);

%% Define the output variable
variance_times = struct([]);
mod_per_window = struct([]);

%% Moving window through the joint angles

% Number of window to scroll through
window_size = time_window / sec_per_frame;
step_size = time_steps / sec_per_frame;
[sliding_array, array_idxs] = Sliding_Window(joint_var(:,joint_idx), window_size, step_size);

 % Percentile
if strcmp(mod_method, 'Perc')
    for ii = 1:length(sliding_array)
        % Find the 5th percentile
        min_perc = prctile(sliding_array{ii}, 5);
        % Find the 90th percentile
        max_perc = prctile(sliding_array{ii}, 90);
        % Find the modulation
        mod_per_window{jj}(ii) = max_perc - min_perc;
        %fprintf('%s seconds to %s seconds \n', string(array_idxs{ii}(1)*bin_width), ...
            %string(array_idxs{ii}(end)*bin_width))
    end
end

% Variance
if strcmp(mod_method, 'Var')
    for ii = 1:length(sliding_array)
        mod_per_window{jj}(ii) = sqrt(var(sliding_array{ii}, 'omitnan'));
        %fprintf('%s seconds to %s seconds \n', string(array_idxs{ii}(1)*bin_width), ...
            %string(array_idxs{ii}(end)*bin_width))
    end
end

%% Find the maximum joint angle modulation

% Find the modulation
max_mod_idx = struct([]);
max_mod_times =  maxk(mod_per_window{jj}, time_num);
for tt = 1:time_num
    max_mod_idx{tt,1} = find(mod_per_window{jj} == max_mod_times(tt));
    for ii = 1:length(max_mod_idx{tt,1})
        variance_times{jj,1}{tt,1}(ii,1) = array_idxs{max_mod_idx{tt,1}(ii)}(1)*sec_per_frame;
        variance_times{jj,1}{tt,1}(ii,2) = array_idxs{max_mod_idx{tt,1}(ii)}(end)*sec_per_frame;
    end
end


%% Plot the variance of the 1st PCA through time

figure
hold on
fig_title = strcat('PC1 of Joint', {' '}, joint_param, {' '}, '& Binned Firing Rates');
title(fig_title, 'Fontsize', 15);
ylabel('Sqrt Variance', 'FontSize', 15);
xlabel('Time Segments (30 sec.)', 'FontSize', 15)

joint_variance = mod_per_window{1,1};

%array_padding = zeros(1, round(window_size / 2));
%joint_variance = cat(2, array_padding, joint_variance);
%joint_variance = cat(2, joint_variance, array_padding);

time = (1:length(joint_variance));
plot(time, joint_variance)




