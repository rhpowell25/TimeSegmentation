
%clear
clc
%% Load the files
%xds = Load_XDS('Pop', '20220309', 'FR', 1);

% Load the xds file
base_dir = 'C:\Users\rhpow\Documents\Work\Northwestern\Monkey_Data\Pop\20220309\Aajan_Angles\';
AA_file_name = '20220309_Aajan_Angles';
%load(strcat(base_dir, AA_file_name));

%% Aajan joint names

Aajan_joint_names = struct([]);
Aajan_joint_names{1,1} = 'Pinky_DIP_Flex_Ext';
Aajan_joint_names{2,1} = 'Ring_DIP_Flex_Ext';
Aajan_joint_names{3,1} = 'Middle_DIP_Flex_Ext';
Aajan_joint_names{4,1} = 'Index_DIP_Flex_Ext';
Aajan_joint_names{5,1} = 'Thumb_IP_Flex_Ext';

Aajan_joint_names{1,2} = 'Pinky_PIP_Flex_Ext';
Aajan_joint_names{2,2} = 'Ring_PIP_Flex_Ext';
Aajan_joint_names{3,2} = 'Middle_PIP_Flex_Ext';
Aajan_joint_names{4,2} = 'Index_PIP_Flex_Ext';
Aajan_joint_names{5,2} = 'Thumb_MCP_Flex_Ext';

Aajan_joint_names{1,3} = 'Pinky_MCP_Flex_Ext';
Aajan_joint_names{2,3} = 'Ring_MCP_Flex_Ext';
Aajan_joint_names{3,3} = 'Middle_MCP_Flex_Ext';
Aajan_joint_names{4,3} = 'Index_MCP_Flex_Ext';
Aajan_joint_names{5,3} = 'Thumb_CMC_Flex_Ext';

%% Basic Settings, some variable extractions, & definitions

% Save the figures to desktop? ('pdf', 'png', 'fig', 0 = no)
Save_Figs = 'png';

% Find the joint of choice
angle_name = 'Ring_PIP_Flex_Ext';

OpenSim_angle_idx = find(strcmp(xds.joint_names, angle_name));
[Aajan_idx_x, Aajan_idx_y] = find(strcmp(Aajan_joint_names, angle_name));

time_frame = xds.joint_angle_time_frame;

% Extract the joint angles
AA_joint_angles = new_joints(3:end,Aajan_idx_x,Aajan_idx_y);
OpenSim_joint_angles = xds.joint_angles(:,OpenSim_angle_idx);

% How long do you want plotted (sec.)
plot_time = 540;

% Find the frame rate / bin size
bin_size = mode(diff(xds.joint_angle_time_frame));
plot_length = round(plot_time/bin_size);

% Font specifications
label_font_size = 15;
legend_font_size = 12;
legend_location = 'NorthEast';
title_font_size = 15;
figure_width = 750;
figure_height = 250;
font_name = 'Arial';

%% Plotting

Joint_figure = figure;
Joint_figure.Position = [300 300 figure_width figure_height];
hold on

% Titling the plot
Joint_title = strrep(char(angle_name), '_', ' ');
title(sprintf('Aajan Angles vs OpenSim, %s: %s', Joint_title), 'FontSize', title_font_size)

% Labels
ylabel('Joint Angles', 'FontSize', label_font_size);
xlabel('Time (sec.)', 'FontSize', label_font_size);

% Plotting the angles
plot(time_frame(1:plot_length), AA_joint_angles(1:plot_length), 'LineWidth', 2, 'Color', [.5 0 .5])
plot(time_frame(1:plot_length), OpenSim_joint_angles(1:plot_length), 'LineWidth', 2, 'Color', [0 0 1])

% Legend
legend('AA', 'OSim', 'Location', legend_location, 'FontSize', legend_font_size)
% Remove the legend's outline
legend boxoff

% Collect the current y axis
y_limits = ylim;
% Reset the axis limits
xlim([0, plot_time])
ylim([y_limits(1), y_limits(2) + 50])

% Only label every other tick
figure_axes = gca;
x_labels = string(figure_axes.XAxis.TickLabels);
x_labels(2:2:end) = NaN;
figure_axes.XAxis.TickLabels = x_labels;
% Set ticks to outside
set(figure_axes,'TickDir','out');
% Remove the top and right tick marks
set(figure_axes,'box','off');
% Set The Font
set(figure_axes,'fontname', font_name);

%% Cross Correlation
%x_corr = xcorr(OpenSim_joint_angles(1:length(OpenSim_joint_angles)), ...
%    AA_joint_angles(1:length(OpenSim_joint_angles)));

%% Figure Saving
if ~isequal(Save_Figs, 0)
    save_dir = 'C:\Users\rhpow\Desktop\';
    for ii = 1:length(findobj('type','figure'))
        fig_info = get(gca,'title');
        fig_title = get(fig_info, 'string');
        if isempty(fig_title)
            fig_info = sgt;
            fig_title = get(fig_info, 'string');
        end
        fig_title = strrep(fig_title, ':', '');
        fig_title = strrep(fig_title, 'vs.', 'vs');
        fig_title = strrep(fig_title, 'mg.', 'mg');
        fig_title = strrep(fig_title, 'kg.', 'kg');
        fig_title = strrep(fig_title, '.', '_');
        fig_title = strrep(fig_title, '/', '_');
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














