

%% Load the xds file
Monkey = 'Pop';
Date = '20220309';

xds = Load_XDS('Pop', '20220309', 'FR', 2);

% Save XDS? (1 = Yes; 0 = No)
Save_XDS = 1;

%% Define the time frame to trim (in seconds)

trim_start = [0, 480.001]; %240; %

trim_end = [240, 540]; %540; %

%% Find & trim the selected segments

for jj = 1:length(trim_start)

    % Reset the trim time based on the previous segment
    if ~isequal(jj, 1)
        trim_start(jj) = trim_start(jj) - (trim_end(1) - trim_start(1));
        trim_end(jj) = trim_end(jj) - (trim_end(1) - trim_start(1));
    end

    % Find the indices of the segment to trim
    joint_trim_idxs = find(xds.joint_angle_time_frame >= trim_start(jj) & xds.joint_angle_time_frame < trim_end(jj));
    trim_idxs = find(xds.time_frame >= trim_start(jj) & xds.time_frame < trim_end(jj));
    
    % Trim the joint angels
    xds.joint_angles(joint_trim_idxs, :) = [];
    
    % Trim the EMG & binned spikes
    xds.EMG(trim_idxs, :) = [];
    xds.spike_counts(trim_idxs, :) = [];
    
    % Trim the time frames
    xds.joint_angle_time_frame(end - length(joint_trim_idxs) + 1 : end, :) = [];
    xds.time_frame(end - length(trim_idxs) + 1 : end, :) = [];
    
    % Loop through the spikes
    for ii = 1:length(xds.spikes)
        % Find the spikes in the trimmed segments
        spike_idxs = find(xds.spikes{ii} >= trim_start(jj) & xds.spikes{ii} < trim_end(jj));
    
        % Adjust the threshold crossing time
        xds.spikes{ii}(spike_idxs(end):end) = xds.spikes{ii}(spike_idxs(end):end) - (trim_end(jj) - trim_start(jj));
    
        % Trim the spikes
        xds.spikes{ii}(spike_idxs) = [];
    
    end

end

%% Save the xds file
if isequal(Save_XDS, 1)

    disp('Saving XDS:')

    save_dir = strcat('C:\Users\rhpow\Documents\Work\Northwestern\Monkey_Data\', Monkey, '\', Date, '\Trimmed\');
    save_file = strcat(xds.meta.rawFileName(1:end-4), '_Early', '.mat');
    save(strcat(save_dir, save_file), 'xds', '-v7.3');

end











