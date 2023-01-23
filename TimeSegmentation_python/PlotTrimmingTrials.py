
#%% Import basic packages
import matplotlib.pyplot as plt
from Plot_Specs import Font_Specs
import numpy as np
import matplotlib.font_manager as fm

class Plot_TrimmingTrials():
    
    def __init__(self,  xds_untrimmed, xds_trimmed, Save_Figs):
        #%% Extracting the variables
        
        # Font & plotting specifications
        font_specs = Font_Specs()
        
        # Do you want to manually set the y-axis?
        man_y_axis = 'No'
        #man_y_axis = [-10, 175]
        
        #behavior_titles = Self_Untrimmed_Vars.behavior_titles
        behavior_titles = xds_untrimmed.joint_names
        
        #untrimmed_Behavior = Self_Untrimmed_Vars.test_Behavior
        #trimmed_Behavior = Self_Trimmed_Vars.test_Behavior
        untrimmed_Behavior = xds_untrimmed.joint_angles
        trimmed_Behavior = xds_trimmed.joint_angles
        
        #trimmed_joint_angle_time_frame = Self_Trimmed_Vars.trimmed_joint_angle_time_frame
        #joint_angle_time_frame = Self_Untrimmed_Vars.joint_angle_time_frame
        trimmed_joint_angle_time_frame = xds_trimmed.trimmed_joint_angle_time_frame
        joint_angle_time_frame = xds_untrimmed.joint_angle_time_frame
        
        #%% Plotting the concatenated predicted behavior
        
        for ii in range(len(behavior_titles)):
            
            plot_start = 0
            plot_end = 15
            
            Behavior = behavior_titles[ii].replace('EMG_', '', 1)
            #EMG = EMG.replace('1', '', 1)
            #EMG = EMG.replace('2', '', 1)
            
            fig, fig_axes = plt.subplots()
            end_idx = np.where(joint_angle_time_frame == plot_end)[0][0]
            plt.plot(joint_angle_time_frame[plot_start:end_idx], untrimmed_Behavior[plot_start:end_idx, ii], \
                     'k', label = 'Untrimmed')
            end_idx = np.where(trimmed_joint_angle_time_frame == plot_end)[0][0]
            plt.plot(trimmed_joint_angle_time_frame[plot_start:end_idx], trimmed_Behavior[plot_start:end_idx, ii], \
                     'r', label = 'Trimmed')

            title_string = 'Untrimmed vs. Trimmed - ' + Behavior
            plt.title(title_string, fontname = font_specs.font_name, fontsize = font_specs.title_font_size, fontweight = 'bold')
            # Axis Labels
            plt.xlabel('Time', fontname = font_specs.font_name, fontsize = font_specs.label_font_size)
            plt.ylabel(Behavior, fontname = font_specs.font_name, fontsize = font_specs.label_font_size)
            
            # Collect the current axis limits
            x_limits = fig_axes.get_xlim()
            plt.xlim(x_limits)
            
            if isinstance(man_y_axis, str):
                y_limits = fig_axes.get_ylim()
                axis_expansion = y_limits[1] + 6.5*(np.std(untrimmed_Behavior[plot_start:plot_end, ii]))
                # Reset the axis limits
                plt.ylim(y_limits[0], axis_expansion)
            else:
                plt.ylim(man_y_axis[0], man_y_axis[1])
    
            legend_font = fm.FontProperties(family = font_specs.font_name, size = font_specs.legend_font_size + 5)
            plt.legend(prop = legend_font)
            plt.legend(frameon = False)
            
            # Figure Saving
            if Save_Figs != 0:
                save_dir = 'C:/Users/rhpow/Desktop/'
                fig_title = title_string
                fig_title = str.replace(fig_title, ':', '')
                fig_title = str.replace(fig_title, 'vs.', 'vs')
                fig_title = str.replace(fig_title, 'mg.', 'mg')
                fig_title = str.replace(fig_title, 'kg.', 'kg')
                fig_title = str.replace(fig_title, '.', '_')
                fig_title = str.replace(fig_title, '/', '_')
                plt.savefig(save_dir + fig_title + '.' + Save_Figs)
                plt.close()
      
        
        #%% Plotting the per-trial predicted EMG's
        #fig, fig_axes = plt.subplots()
        
        #plt.plot(per_trial_testing_EMG[0][:,0], 'k')
        #plt.plot(per_trial_predicted_EMG[0][:,0], 'r')
        
        
        











