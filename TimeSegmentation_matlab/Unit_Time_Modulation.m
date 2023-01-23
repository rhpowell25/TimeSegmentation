function [unit_names, unit_times] = Unit_Time_Modulation(xds)
    
%% Basic settings, some variable extractions, & definitions

% Define the method to compare the unit's modulation ('Var' or 'Perc')
mod_method = 'Perc';

% How many units (# or 'All')
unit_num = 'All';

% How many time frames (#)
time_num = 10;

% Do you want maxima or minima? ('Max', or 'Min')
time_choice = 'Max';

% Find the top units
unit_names = Unit_Modulation_Check(xds, unit_num, mod_method);

% Bin size (in seconds)
bin_width = 0.2;

% How large of a time window to you want to scroll through? (in seconds)
time_window = 30;
% How many steps do you want per window (in seconds)
time_steps = 1;

% Do you want the window to be individualized or across all units 
% ('Individual' vs. 'Merged')
unit_window = 'Merged';

% Do you want to plot the rasters?
Plot_Raster = 1;
% Save the figures to desktop? ('pdf', 'png', 'fig', 0 = no)
Save_Figs = 0; %'png';

% Do you want the name of each unit labeled? (1 = Yes, 0 = No)
unit_label = 0;

%% Define the output variable
unit_times = struct([]);
mod_per_window = struct([]);

%% Convert the unit names into one cell
all_unit_names = struct([]);
% Concatenate all the information
cc = 1;
for xx = 1:length(unit_names)
    for jj = 1:length(unit_names{xx})
        all_unit_names{cc,1} = char(unit_names{xx}(jj));
        cc = cc + 1;
    end
end
% Rename the now merged variables
unit_names = unique(all_unit_names, 'Stable');

%% Loop through all units
for jj = 1:length(unit_names)

    % Display the unit
    disp(string(unit_names(jj)));

    % Getting the spike timestamps
    unit_idx = find(strcmp(xds.unit_names, unit_names{jj}));
    spikes = cell2mat(xds.spikes(unit_idx));
    
    %% Binning the spikes & finding the firing rate
    
    % Length of the file in seconds
    file_length = length(xds.time_frame) * xds.bin_width;
    % Number of bins
    n_bins = round(file_length/bin_width);
    
    % Binning
    [binned_spikes, ~] = histcounts(spikes, n_bins);

    % Averaging the hist spikes
    binned_fire_rate = binned_spikes / bin_width;

    firing_rate = binned_fire_rate';

    % Number of window to scroll through
    window_size = time_window / bin_width;
    step_size = time_steps / bin_width;
    [~, sliding_array, array_idxs] = Sliding_Window(firing_rate, window_size, step_size);

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
            mod_per_window{jj}(ii) = sqrt(var(sliding_array{ii}));
            %fprintf('%s seconds to %s seconds \n', string(array_idxs{ii}(1)*bin_width), ...
                    %string(array_idxs{ii}(end)*bin_width))
        end
    end

    %% Find the times of unit modulation
    mod_idx = struct([]);
    if strcmp(time_choice, 'Max')
        mod_times =  maxk(mod_per_window{jj}, time_num);
    end
    if strcmp(time_choice, 'Min')
        mod_times =  mink(mod_per_window{jj}, time_num);
    end
    for tt = 1:time_num
        mod_idx{tt,1} = find(mod_per_window{jj} == mod_times(tt));
        for ii = 1:length(mod_idx{tt,1})
            unit_times{jj,1}{tt,1}(ii,1) = array_idxs{mod_idx{tt,1}(ii)}(1)*bin_width;
            unit_times{jj,1}{tt,1}(ii,2) = array_idxs{mod_idx{tt,1}(ii)}(end)*bin_width;
        end
    end

end % End of unit loop

%% Finding the modulation of the binned spikes

if strcmp(unit_window, 'Merged')
    % Sum the modulation across all units
    summed_mod_per_window = zeros(length(mod_per_window{1,1}),1);
    for ii = 1:length(mod_per_window)
        for jj = 1:length(mod_per_window{ii})
            summed_mod_per_window(jj) = summed_mod_per_window(jj) + mod_per_window{ii}(jj);
        end
    end
        
    % Find the modulation
    mod_idx = struct([]);
    if strcmp(time_choice, 'Max')
        mod_times =  maxk(summed_mod_per_window, time_num);
    end
    if strcmp(time_choice, 'Min')
        mod_times =  mink(summed_mod_per_window, time_num);
    end
    for tt = 1:time_num
        mod_idx{tt,1} = find(summed_mod_per_window == mod_times(tt));
        for ii = 1:length(mod_idx{tt,1})
            unit_times{jj,1}{tt,1}(ii,1) = array_idxs{mod_idx{tt,1}(ii)}(1)*bin_width;
            unit_times{jj,1}{tt,1}(ii,2) = array_idxs{mod_idx{tt,1}(ii)}(end)*bin_width;
        end
    end
end

%% Raster Plot

if isequal(Plot_Raster, 1)

    % Do you want the heatmap? (1 = Yes, 0 = No)
    heat_map = 1;

    % Generate the figure
    Raster_figure = figure;
    Raster_figure.Position = [200 50 700 700];
    fig_title = strcat('Top', {' '}, string(length(unit_names)), {' '}, 'Unit Rasters (Binned Firing Rates)');
    
    for uu = 1:length(unit_names)

        %unit_times{uu}{1,1}(1,1) = 0;
        %unit_times{uu}{1,1}(1,2) = xds.time_frame(end);

        subplot(length(unit_names),1,uu)
        hold on

        % Title the subplot
        if isequal(unit_label, 1)
            if strcmp(unit_window, 'Individual')
                sub_fig_title = strcat(char(unit_names{uu}), {' '}, string(unit_times{uu}{1,1}(1,1)), ...
                    ' :', {' '}, string(unit_times{uu}{1,1}(1,2)), ' seconds');
            end
            if strcmp(unit_window, 'Merged')
                sub_fig_title = strcat(char(unit_names{uu}), {' '}, string(unit_times{1,1}{1,1}(1,1)), ...
                    ' :', {' '}, string(unit_times{1,1}{1,1}(1,2)), ' seconds');
            end
            title(sub_fig_title, 'Fontsize', 12);
        end

        % Find the unit of interest
        N = find(strcmp(xds.unit_names, char(unit_names{uu})));
        % Getting the spike timestamps
        spikes = cell2mat(xds.spikes(N));

        % Getting the spike timestamps based on the behavior timings above
        if strcmp(unit_window, 'Individual')
            aligned_spike_timing = spikes((spikes >= unit_times{uu,1}{1,1}(1,1)) & ...
                (spikes <= unit_times{uu,1}{1,1}(1,2)));
        end
        if strcmp(unit_window, 'Merged')
            aligned_spike_timing = spikes((spikes >= unit_times{1,1}{1,1}(1,1)) & ...
                (spikes <= unit_times{1,1}{1,1}(1,2)));
        end
    
        % If Heat Map is selected
        if isequal(heat_map, 1)
        
            % Binning & averaging the spikes
            % Set the number of bins based on the length of each trial
            bin_width = 0.05;
            time_frame_length = unit_times{1,1}{1,1}(1,2) - unit_times{1,1}{1,1}(1,1);
            n_bins = round(time_frame_length / bin_width);
            hist_spikes = struct([]);
            for ii = 1:length(unit_times)
                [hist_spikes{ii, 1}, ~] = histcounts(aligned_spike_timing, n_bins);
            end
        
            % Finding the firing rates of the hist spikes
            fr_hists_spikes = struct([]);
            for ii = 1:length(unit_times)
                fr_hists_spikes{ii,1} = hist_spikes{ii,1} / bin_width;
            end
        
            % Finding the maximum firing rate of each unit to normalize
            max_fr_per_trial = zeros(length(fr_hists_spikes),1);
            for ii = 1:length(max_fr_per_trial)
                max_fr_per_trial(ii) = max(fr_hists_spikes{ii,1});
            end
        
            % Normalizing the firing rate of each unit
            norm_fr_hists_spikes = fr_hists_spikes;
            for ii = 1:length(unit_times)
                norm_fr_hists_spikes{ii,1} = fr_hists_spikes{ii,1} / max_fr_per_trial(ii);
            end
        
        end
    
        if isequal(heat_map, 0)
            % The main raster plot
            plot(aligned_spike_timing - unit_times{ii,1}{1,1}(1,1), ...
                ones(1, length(aligned_spike_timing))*ii,... 
                'Marker', '.', 'Color', 'k', 'Markersize', 3, 'Linestyle', 'none');
        end
    
        if isequal(heat_map, 1)
            colormap('turbo');
            % Define the time axis
            time_axis = (0:bin_width:time_frame_length);
            if length(time_axis) > length(norm_fr_hists_spikes{ii,1})
                time_axis(end) = [];
            end
            % The main raster plot
            imagesc(time_axis, ii, norm_fr_hists_spikes{ii,1});
            % Setting the axis limits
            xlim([0, time_frame_length]);
        end
    
        % Remove the y-axis
        yticks([])

        % Only label every other tick
        figure_axes = gca;
        x_labels = string(figure_axes.XAxis.TickLabels);
        if ~isequal(uu, length(unit_names))
            x_labels(1:1:end) = NaN;
            figure_axes.XAxis.TickLabels = x_labels;
        end
        if isequal(uu, length(unit_names))
            x_labels(1:2:end) = NaN;
            figure_axes.XAxis.TickLabels = x_labels;
        end
        % Set ticks to outside
        set(figure_axes,'TickDir','out');
        % Remove the top and right tick marks
        set(figure_axes,'box','off')
        % Set The Font
        set(figure_axes,'fontname', 'Arial');
    end
    raster_handle = axes(Raster_figure,'visible','off'); 
    
    %sgtitle(fig_title, 'Fontsize', 15);
    raster_handle.XLabel.Visible='on';
    raster_handle.YLabel.Visible='on';
    %ylabel(raster_handle, 'Time Frames', 'FontSize', 15);
    xlabel(raster_handle, 'Time (sec.)', 'FontSize', 15);

    %% Define the save directory & save the figures
    if ~isequal(Save_Figs, 0)
        save_dir = 'C:\Users\rhpow\Desktop\';
        for uu = numel(findobj('type','figure')):-1:1
            set(gcf, 'InvertHardcopy', 'off');
            if ~strcmp(Save_Figs, 'All')
                saveas(gcf, fullfile(save_dir, char(fig_title)), Save_Figs)
            end
            if strcmp(Save_Figs, 'All')
                saveas(gcf, fullfile(save_dir, char(fig_title)), 'png')
                saveas(gcf, fullfile(save_dir, char(fig_title)), 'pdf')
                saveas(gcf, fullfile(save_dir, char(fig_title)), 'fig')
            end
            close gcf
        end
    end

end







