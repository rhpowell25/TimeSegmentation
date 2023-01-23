
%% Load the xds file
Monkey = 'Pop';
Date = '20220309';

xds = Load_XDS(Monkey, Date, 'FR', 1);

% Save XDS? (1 = Yes; 0 = No)
Save_XDS = 1;

% Which joint angles do you want to use?
%joint_choice = 'All';
joint_choice = strings;
joint_choice{1,1} = 'Index';
joint_choice{2,1} = 'Thumb';
%joint_choice{3,1} = 'Pinky';

% Do you want to normalize the joint paramater ('Yes' or 'No')
norm_joints = 'Yes';

% Do you want to use joint angles or joint velocity ('Angles' or 'Velocity')
joint_param = 'Angles';

%% Find the indexes of maximal & minimal joint angle variation

% Do you want maxima or minima? ('Max', or 'Min')
%time_choice = 'Max';

%[~, ~, max_joint_times, max_joint_time_idxs] = ...
%    Joint_Time_Modulation(xds, joint_choice, joint_param, norm_joints, time_choice);

% Do you want maxima or minima? ('Max', or 'Min')
time_choice = 'Min';

[~, ~, min_joint_times, min_joint_time_idxs] = ...
    Joint_Time_Modulation(xds, joint_choice, joint_param, norm_joints, time_choice);

% Merge the joint time indexes
joint_time_idxs = struct([]);

%joint_time_idxs{1,1} = unique(cat(2, max_joint_time_idxs{1,1}, min_joint_time_idxs{1,1}))';
%joint_time_idxs{1,1} = unique(max_joint_time_idxs{1,1});
joint_time_idxs{1,1} = unique(min_joint_time_idxs{1,1});

% Merge the maximum variance & minimum variance joint times
joint_times = struct([]);
%joint_times{1,1} = unique(cat(1, max_joint_times{1,1}, min_joint_times{1,1}));
%joint_times{1,1} = unique(max_joint_times{1,1});
joint_times{1,1} = unique(min_joint_times{1,1});

%% Seperate the joint modulation times into consecutive segments

% Find the difference between each index
joint_diff = diff(joint_time_idxs{1,1});
% Index differences greater than 1 indicate different segments
segment_boundaries = find(joint_diff > 1) + 1;
joint_segment_idxs = struct([]);
for ii = 1:(length(segment_boundaries) + 1)
    if ii == 1
        joint_segment_idxs{ii,1} = joint_time_idxs{1,1}(1:(segment_boundaries(ii)-1));
    end
    if ii > 1 && ii < (length(segment_boundaries) + 1)
        joint_segment_idxs{ii,1} = joint_time_idxs{1,1}(segment_boundaries(ii-1):(segment_boundaries(ii)-1));
    end
    if ii == (length(segment_boundaries) + 1)
        joint_segment_idxs{ii,1} = joint_time_idxs{1,1}(segment_boundaries(ii-1):end);
    end
end

%% Find the length and timestamps of these segments
joint_segment_start = zeros(length(joint_segment_idxs),1);
joint_segment_end = zeros(length(joint_segment_idxs),1);
joint_segment_length = zeros(length(joint_segment_idxs),1);
for ii = 1:length(joint_segment_idxs)
    joint_segment_start(ii,1) = xds.joint_angle_time_frame(joint_segment_idxs{ii}(1));
    joint_segment_end(ii,1) = xds.joint_angle_time_frame(joint_segment_idxs{ii}(end));
    joint_segment_length(ii,1) = joint_segment_end(ii,1) - joint_segment_start(ii,1);
end

%% Trim the joint angle segments out of the file

disp('Trimming the kinematic segments')
joint_angle_time_frame = xds.joint_angle_time_frame;
joint_angles = xds.joint_angles;

joint_angle_time_frame(end - length(joint_time_idxs{1,1}) + 1 : end, :) = [];
joint_angles(joint_time_idxs{1,1}, :) = [];

%% Bin the EMG & neural data to the joint angle time frame

disp('Binning the EMG')

% Binning the EMG to the joint time frame
EMG = zeros(length(xds.joint_angle_time_frame), width(xds.EMG));
for ii = 1:length(xds.joint_angle_time_frame)
    if ii == 1
        EMG_idx = find(xds.time_frame <= xds.joint_angle_time_frame(ii));
    else
        EMG_idx = find(xds.time_frame > xds.joint_angle_time_frame(ii - 1) & xds.time_frame <= xds.joint_angle_time_frame(ii));
    end
    EMG(ii,:) = mean(xds.EMG(EMG_idx,:));
end

disp('Binning the Neural Data')

spikes = xds.spikes;
bin_size = mode(diff(xds.joint_angle_time_frame));
bin_edges = [xds.joint_angle_time_frame - bin_size / 2; xds.joint_angle_time_frame(end) + bin_size / 2];

spike_counts = zeros(length(xds.joint_angle_time_frame), length(xds.unit_names));
for ii = 1:length(xds.unit_names)
    [spike_counts(:,ii), ~] = histcounts(spikes{ii}, bin_edges);
end

%% Trim the EMG out of the file

disp('Trimming the EMG segments')

EMG(joint_time_idxs{1,1}, :) = [];

%% Trim the neural data out of the file

disp('Trimming the neural segments')
neural_lag = 0; %0.2; % (200 ms)

% Adjust the indices with the neural lag
neural_time_idxs = struct([]);
neural_time_idxs{1,1} = joint_time_idxs{1,1} - round(neural_lag / bin_size);

% Trim those segments
spike_counts(neural_time_idxs{1,1}, :) = [];

%% Add the information back to xds

% Kinematic
xds.joint_angle_time_frame = joint_angle_time_frame;
xds.joint_angles = joint_angles;

% EMG data
xds.EMG = EMG;

% Neural data
time_frame = xds.time_frame;
time_frame(time_frame >= joint_angle_time_frame(end)) = [];

xds.time_frame = time_frame;
xds.spikes = spikes;
xds.spike_counts = spike_counts;

%% Save the trimmed xds file
[joint_variance] = Plot_Variance(xds, joint_choice);
if isequal(Save_XDS, 1)

    save_dir = strcat('C:\Users\rhpow\Documents\Work\Northwestern\Monkey_Data\', Monkey, '\', Date, '\Trimmed\');
    if ~exist(save_dir, 'dir')
        mkdir(save_dir);
    end

    disp('Saving XDS:')
    
    save_file = strcat(xds.meta.rawFileName(1:end-4), '_Trimmed', '.mat');
    save(strcat(save_dir, save_file), 'xds', '-v7.3');

end








