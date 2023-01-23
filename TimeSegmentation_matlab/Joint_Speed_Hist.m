function [Speed_Violation_Ratio, Joint_Speed_Med] = Joint_Speed_Hist(xds, joint_name, Save_Figs)

%% Basic settings, some variable extractions, & definitions

% Find the joint angle idx
if ~ischar(joint_name)
    N = joint_name;
else
    N = find(strcmp(xds.joint_names, joint_name));
end

% Font specifications
label_font_size = 20;
title_font_size = 15;
legend_font_size = 15;
font_name = 'Arial';

if ~isequal(Save_Figs, 0)
    % Do you want a save title or blank title (1 = save_title, 0 = blank)
    Fig_Save_Title = 1;
end

%% If the joint doesn't exist

if isempty(N)
    fprintf('%s does not exist \n', joint_name);
    Joint_Speed_Med = NaN;
    Speed_Violation_Ratio = NaN;
    return
end

%% Some variable extraction & definitions

% Extracting the joint angles of the designated joint
joint_angles = xds.joint_angles(:,N);

% Find the frame rate / bin size
bin_size = mode(diff(xds.joint_angle_time_frame));

% Calculate the joint speed (degrees / second)
joint_speed = diff(joint_angles) / bin_size;

Joint_Speed_Med = median(joint_speed);

%% Calculate the number of refractory period violations

% Define the joint speed cutoff (500 degrees / second)
max_speed = 500;

% Find the number of speed violations
speed_violation_idxs = find(abs(joint_speed) > max_speed);
speed_violations = length(speed_violation_idxs);

% Find the percent of spikes this corresponds to
Speed_Violation_Ratio = speed_violations / length(joint_angles);

%% Plotting the histograms

% Histogram
figure
hold on

% Set the title
hist_title = strcat('Joint Angular Velocity -', {' '}, strrep(char(xds.joint_names(N)), '_', ' '));
if contains(xds.meta.rawFileName, 'Pre')
    hist_title = strcat(hist_title, {' '}, '(Morning)');
    hist_color = [0.9290, 0.6940, 0.1250];
elseif contains(xds.meta.rawFileName, 'Post')
    hist_title = strcat(hist_title, {' '}, '(Afternoon)');
    hist_color = [.5 0 .5];
else
    hist_color = [0, 0, 0];
end
title(hist_title, 'FontSize', title_font_size)

% Plot the histogram
histogram(joint_speed, 'EdgeColor', 'k', 'FaceColor', hist_color)

set(gca,'yscale','log')

% Axis Labels
xlabel('Angular Velocity (deg./sec.)', 'FontSize', label_font_size)
ylabel('Frames', 'FontSize', label_font_size)

% Collect the current axis limits
y_limits = ylim;
x_limits = xlim;

% Annotation of the speed violations
legend_dims = [0.52 0.35 0.44 0.44];
speed_violation_string = strcat('SVR =', {' '}, num2str(round(Speed_Violation_Ratio, 3)));
legend_string = {char(speed_violation_string)};
ann_legend = annotation('textbox', legend_dims, 'String', legend_string, ... 
    'FitBoxToText', 'on', 'EdgeColor','none', ... 
    'verticalalignment', 'top', 'horizontalalignment', 'center');
ann_legend.FontSize = legend_font_size;
ann_legend.FontName = font_name;

% Reset the axis limits
xlim([x_limits(1),x_limits(2)])
ylim([y_limits(1),y_limits(2) + 1])

%% Print the percentage of speed violations
fprintf("%0.1f%% of the frames in %s have an angular speed less than %0.1f deg. per sec. \n", ...
Speed_Violation_Ratio*100, string(xds.joint_names{N}), max_speed);

Speed_Violation_Ratio = double(min(Speed_Violation_Ratio));

%% Define the save directory & save the figures
if ~isequal(Save_Figs, 0)
    save_dir = 'C:\Users\rhpow\Desktop\Post_Int\';
    for ii = 1:length(findobj('type','figure'))
        fig_info = get(gca,'title');
        fig_title = get(fig_info, 'string');
        fig_title = strrep(fig_title, ':', '');
        fig_title = strrep(fig_title, 'vs.', 'vs');
        fig_title = strrep(fig_title, 'mg.', 'mg');
        fig_title = strrep(fig_title, 'kg.', 'kg');
        fig_title = strrep(fig_title, '.', '_');
        fig_title = strrep(fig_title, '/', '_');
        if isequal(Fig_Save_Title, 0)
            title '';
        end
        if strcmp(Save_Figs, 'All')
            saveas(gcf, fullfile(save_dir, char(fig_title)), 'png')
            saveas(gcf, fullfile(save_dir, char(fig_title)), 'pdf')
            saveas(gcf, fullfile(save_dir, char(fig_title)), 'fig')
        else
            saveas(gcf, fullfile(save_dir, char(fig_title)), Save_Figs)
        end
        close gcf
    end
end







