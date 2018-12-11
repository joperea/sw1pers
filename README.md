# SW1PerS
version 1.0 
2014 06 03


REQUIREMENTS
Matlab 2012 or higher
Java


TO RUN Sw1PerS
Run the sw1pers_v1_src/run_SW1PerS.m file


INPUT FORMAT
Tab delimited.
First row contains sample times.
First column contains signal IDs.


OUTPUT FORMAT
Tab delimited.
First row is header, for columns:
ID, SW periodicity score (smaller is better), and the period for that score.



TO TEST SW1PerS
1. Use the original main file: sw1pers_v1_src/run_SW1PerS.m

2. With the data files in: sw1pers_test/test_input 

3. With the setup:
data_file_path = '../sw1pers_test/test_input/synth_data_noise0.txt';  
out_dir_path = '../sw1pers_test/test_output/';    
num_cycles = 2;  
feature_type = 3;  
num_points = 200;  
allow_trending = true;  
use_meanshift = true;   
meanshift_epsilon = 1 - cos(pi/16);   
use_expaverage = false;  
expaverage_alpha = NaN;  
use_movingaverage = true;   
movingaverage_window = 10;  
use_smoothspline = false;  
smoothspline_sigma = NaN;  

4. Check that the files you generated in: sw1pers_test/test_output/ 
match the correct files we generated in: sw1pers_test/test_output_correct/
