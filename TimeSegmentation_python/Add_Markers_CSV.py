# -*- coding: utf-8 -*-

#%% Import necessary packages
import pandas as pd
import os
import os.path

#%% Find all the csv files in the base directory

# Where the files will be loaded
base_dir = 'R:/Basic_Sciences/Phys/L_MillerLab/data/DPZ/brighten_relabeled_cleaned'
# Where the files will be saved
save_string = 'R:/Basic_Sciences/Phys/L_MillerLab/data/DPZ/brighten_relabeled_cleaned - Copy'
# Where the annotations additions are saved
add_file_name = 'R:/Basic_Sciences/Phys/L_MillerLab/limblab/User_folders/Henry/annotation_additions.csv'

# Find all the csv files in the directory & subdirectories 
file_list = []
dir_list = []
for root, dirs, files in os.walk(base_dir):
    for file in files:
        if(file.endswith(".csv")):
            dir_list.append(root)
            file_list.append(file)

#%% Loop through each file & add the new markers

add_file = pd.read_csv(add_file_name, header = None)
for ii in range(len(file_list)):
    file_name = file_list[ii]
    file_dir = dir_list[ii]
    # Load the file
    origin_file = pd.read_csv(file_dir + '/' + file_name, header = None)
    # Concatenate with the add-on annotations
    new_file = pd.concat([origin_file, add_file], axis = 1)
    # Save in the copy folder
    save_dir = file_dir.replace(base_dir, save_string)
    new_file.to_csv(save_dir + '/' + file_name, index = False, header = None)


    

        
    








