function [xds] = Joint_Interpolation(xds)

%% Loop through each joint angle

for jj = 1:length(xds.joint_names)

    %% Some variable extraction & definitions

    % Extracting the joint angles of the designated joint
    joint_angles = xds.joint_angles(:,jj);
    
    % Find the frame rate / bin size
    bin_size = mode(diff(xds.joint_angle_time_frame));
    
    % Calculate the joint speed (degrees / second)
    joint_speed = diff(joint_angles) / bin_size;
    
    %% Calculate the number of refractory period violations
    
    % Define the joint speed cutoff (500 degrees / second)
    max_speed = 500;
    
    % Find the number of speed violations
    speed_violation_idxs = find(abs(joint_speed) > max_speed);
    
    % Find violations that only happened in a single frame
    single_point_violation_idxs = find(diff(speed_violation_idxs) == 1);
    single_point_violations = speed_violation_idxs(single_point_violation_idxs + 1);
    
    % Interpolate the single frame violations
    for ii = 1:length(single_point_violation_idxs)
       joint_angles(single_point_violations(ii)) = ...
           (joint_angles(single_point_violations(ii) - 1) + joint_angles(single_point_violations(ii) + 1)) / 2;
    end
    
    speed_violations = length(speed_violation_idxs);
    
    % Find the percent of spikes this corresponds to
    Speed_Violation_Ratio = speed_violations / length(joint_angles);
    
    %% Place the joint angle back into xds
    xds.joint_angles(:,jj) = joint_angles;

    %% Print the percentage of speed violations
    fprintf("%0.1f%% of the frames in %s have an angular speed less than %0.1f deg. per sec. \n", ...
        Speed_Violation_Ratio*100, string(xds.joint_names{jj}), max_speed);

end






