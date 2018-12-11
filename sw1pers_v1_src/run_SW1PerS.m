% SW1PerS - Sliding Windows and 1-Persistence Scoring


%% SET UP PARAMETERS FOR RUNNING SW1PerS

% a tab delimited time series file
% first row is times
% first column are IDs
% the times should be evenly spaced; e.g. t=1,2,3,4,5,6; not 1,2,3,7,8,9.
data_file_path = '../sw1pers_test/test_input/synth_data_noise0.txt';  

% an output directory, where several files will be written
out_dir_path = '../sw1pers_test/test_output/';  

% see SW1PerS_v0.m for details on the parameters
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


tic

%% RUN SW1PerS

% read in each line; will split the signal id off later and separate on
% tabs
infile = fopen(data_file_path);
rawdata = textscan(infile, '%s', 'delimiter', '\n', 'headerlines', 1);
rawdata = rawdata{1};
fclose(infile);

% open a file for writing results, print a header
[data_path,data_name,data_ext] = fileparts(data_file_path);
results_path = [out_dir_path '/' data_name '_sw_scores.txt'];
disp(fprintf('results file: %s\n', results_path));
results_file = fopen(results_path, 'w');
fprintf(results_file, '%s\t%s\t%s', 'id', 'score', 'per');

% had to add this here due to first run problem in matlab
javaclasspath('tda/jars/tda_1.0.0_unionFind3.jar')
import shell.*

for nsig = 1:length(rawdata)
    % split the tab delimited string, and separate id from data.
    lineSplit = regexp(rawdata{nsig},'\t','split');
    signalId = lineSplit(1);
    signalId = signalId{1};
    signal = str2double(lineSplit(2:end));

    score = SW1PerS_v1(...
    signal, ...
    num_cycles, ...
    feature_type, ...
    num_points, ... 
    allow_trending, ...
    use_meanshift, meanshift_epsilon, ... 
    use_expaverage, expaverage_alpha, ...
    use_movingaverage, movingaverage_window, ...
    use_smoothspline, smoothspline_sigma ...
    );
    
    fprintf('%s   %0.6f\n\n\n', signalId, score)
    fprintf(results_file, '\n%s\t%0.6f\t%0.2f', signalId, score, num_cycles);

end % for nsig in rawdata
					
fclose(results_file);

toc 

% save the parameters used
params_path = [out_dir_path '/' data_name '_sw_params.txt'];
disp(fprintf('params file: %s\n', params_path));
params_file = fopen(params_path, 'w');

fprintf(params_file, 'data_file_path:\t%s\n', data_file_path);
fprintf(params_file, 'num_cycles:\t%f\n', num_cycles);
fprintf(params_file, 'feature_type:\t%d\n', feature_type);
fprintf(params_file, 'num_points:\t%d\n', num_points);
fprintf(params_file, 'allow_trending:\t%d\n', allow_trending);
fprintf(params_file, 'use_meanshift:\t%d\n', use_meanshift); 
fprintf(params_file, 'meanshift_epsilon:\t%f\n', meanshift_epsilon);
fprintf(params_file, 'use_expaverage:\t%d\n', use_expaverage);
fprintf(params_file, 'expaverage_alpha:\t%f\n', expaverage_alpha);
fprintf(params_file, 'use_movingaverage:\t%d\n', use_movingaverage);
fprintf(params_file, 'movingaverage_window:\t%d\n', movingaverage_window);
fprintf(params_file, 'use_smoothspline:\t%d\n', use_smoothspline);
fprintf(params_file, 'smoothspline_sigma:\t%f\n', smoothspline_sigma);

fclose(params_file);
					
toc
