function unit_names = Unit_Modulation_Check(xds, unit_num, mod_method)
    
%% Basic settings, some variable extractions, & definitions

% Bin size
bin_size = 0.2;

%% Define the output variable
mod_per_unit = zeros(length(xds.unit_names), 1);

%% Loop through all units
for jj = 1:length(xds.unit_names)

    % Display the unit
    disp(string(xds.unit_names(jj)));

    % Getting the spike timestamps
    spikes = cell2mat(xds.spikes(jj));
    
    %% Binning the spikes & finding the firing rate

    % Length of the file in seconds
    file_length = length(xds.time_frame) * xds.bin_width;
    % Number of bins
    n_bins = round(file_length/bin_size);
    
    % Binning
    [binned_spikes, ~] = histcounts(spikes, n_bins);

    % Averaging the hist spikes
    binned_fire_rate = binned_spikes / bin_size;

    firing_rate = binned_fire_rate';

    %% Finding the modulation of the binned spikes

    if strcmp(mod_method, 'Perc')

        % Find the 5th percentile
        min_perc = prctile(firing_rate, 5);

        % Find the 90th percentile
        max_perc = prctile(firing_rate, 90);

        % Find the modulation
        mod_per_unit(jj) = max_perc - min_perc;

    end

    if strcmp(mod_method, 'Var')

        % Remove the outliers greater than 3 std from the mean
        firing_rate = rmoutliers(firing_rate, 'mean');

        % Find the variance of unit in each time frame
        mod_per_unit(jj) = sqrt(var(firing_rate));

    end

end % End of unit loop

%% Find the top modulating units

% Find the units that modulates the most in all trials
if ~strcmp(unit_num, 'All')
    top_mod = maxk(mod_per_unit, unit_num);
else
    top_mod = sort(mod_per_unit, 1, 'Descend');
end

mod_unit_idx = struct([]);
for ii = 1:length(top_mod)
    mod_unit_idx{ii,1} = find(mod_per_unit == top_mod(ii));
end

%% Convert the unis indexes into the unit names

unit_names = struct([]);
for ii = 1:length(mod_unit_idx)
    unit_names{ii,1} = xds.unit_names(mod_unit_idx{ii,1});
end

% Print the unit that modulated most across all time frames
fprintf("The unit which modulates most across all time frames is %s \n", ...
    string(unit_names{1}));





