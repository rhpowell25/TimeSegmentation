function joint_names = Joint_Modulation_Check(xds, mod_method)
    
%% Basic settings, some variable extractions, & definitions

% What do you want to plot?
Plot_Scatter = 0;
Save_Figs = 0;

% Do you want the name of each unit labeled? (1 = Yes, 0 = No)
joint_label = 1;

%% Define the output variable
mod_per_joint = zeros(length(xds.joint_names), 1);

%% Loop through all units
for jj = 1:length(xds.joint_names)

    % Display the unit
    disp(string(xds.joint_names(jj)));

    % Getting the spike timestamps
    joint_angles = xds.joint_angles(:,jj);
    
    %% Finding the modulation of the binned spikes

    if strcmp(mod_method, 'Perc')

        % Find the 5th percentile
        min_perc = prctile(joint_angles, 5);

        % Find the 90th percentile
        max_perc = prctile(joint_angles, 90);

        % Find the modulation
        mod_per_joint(jj) = max_perc - min_perc;

    end

    if strcmp(mod_method, 'Var')

        % Find the variance of unit in each time frame
        % sqrt(var) is the same as std!!
        mod_per_joint(jj) = sqrt(var(joint_angles, 'omitnan'));

    end

end % End of joint loop

%% Find the top modulating joints

% Find the joints that modulates the most in throughout the experiment
top_mod = sort(mod_per_joint, 1, 'Descend');

mod_joint_idx = struct([]);
for ii = 1:length(top_mod)
    mod_joint_idx{ii,1} = find(mod_per_joint == top_mod(ii));
end

%% Convert the unis indexes into the unit names

joint_names = struct([]);
for ii = 1:length(mod_joint_idx)
    joint_names{ii,1} = xds.joint_names(mod_joint_idx{ii,1});
end

% Print the unit that modulated most across all time frames
fprintf("The joint which modulates most across all time frames is %s \n", ...
    string(joint_names{1}));

%% Scatter Plot
   
if isequal(Plot_Scatter, 1)

    if strcmp(mod_method, 'Var')
        Joint_Angle_Var = mod_per_joint;
    end
    if strcmp(mod_method, 'Perc')
        Joint_Angle_Perc = mod_per_joint;
    end
    
    figure
    hold on
    fig_title = 'p(90) - p(5) vs. Sqrt Variance';
    scatter(Joint_Angle_Var, Joint_Angle_Perc, 250, '.', 'k')
    title(fig_title, 'Fontsize', 15);
    xlabel('Sqrt Variance', 'FontSize', 15);
    ylabel('p(90) - p(5)', 'FontSize', 15);

    if isequal(joint_label, 1)
        for jj = 1:length(xds.joint_names)
            text(Joint_Angle_Var(jj) + 1.5, Joint_Angle_Perc(jj) - 1.5, ...
                char(xds.joint_names(jj)));
        end
    end

    % Set the axis
    xlim([10, 80])
    ylim([10, 80])
    
    if ~isequal(Save_Figs, 0)
        save_dir = 'C:\Users\rhpow\Desktop\';
        saveas(gcf, fullfile(save_dir, 'p(90) - p(5) vs Sqrt Variance'), 'png')
        close gcf
    end

end







