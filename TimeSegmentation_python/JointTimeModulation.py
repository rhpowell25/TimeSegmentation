# -*- coding: utf-8 -*-

#%% Loading the morning & afternoon files
from File_Loading import Load_XDS

# Monkey Name
Monkey = 'Pop'
# Select the date & task to analyze (YYYMMDD)
Date = '20220309'
Task = 'FR'

# Do you want to process the XDS file? (1 = yes; 0 = no)
Process_XDS = 0

xds = Load_XDS.Load_XDS(Monkey, Date, Task, 1, Process_XDS)

#%% Basic settings, some variable extractions, & definitions

# Do you want to find the principle components ('Yes' or 'No')
Use_PCA = 'Yes'

# Which joint angles do you want to use?
joint_choice = []
joint_choice.append('Index')
joint_choice.append('Thumb')

# Do you want to normalize the joint paramater ('Yes' or 'No')
#norm_joints = 'No'

# Do you want to use joint angles or joint velocity ('Angles' or 'Velocity')
#joint_param = 'Velocity'

# Define the method to compare the joint modulation ('Var' or 'Perc')
mod_method = 'Var'

# How many time frames (#)
time_num = 10

# Seconds per frame
sec_per_frame = 0.033

# How large of a time window to you want to scroll through? (in seconds)
time_window = 5 #2
# How many steps do you want per window (in seconds)
time_steps = 1 #sec_per_frame

# What do you want to plot?
Plot_Figs = 1

#%% Joint angle vs joint velocity
if joint_param == 'Angles':
    joint_var = xds.joint_angles
elif joint_param == 'Velocity':
    joint_var = diff(xds.joint_angles) / sec_per_frame