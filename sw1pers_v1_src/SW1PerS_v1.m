function score = SW1PerS_v1(...
    signal, ...
    num_cycles, ...
    feature_type, ...
    num_points, ... 
    allow_trending, ...
    use_meanshift, ... 
    meanshift_epsilon, ... 
    use_expaverage, ...
    expaverage_alpha, ...
    use_movingaverage, ... 
    movingaverage_window, ...
    use_smoothspline, ...
    smoothspline_sigma ...
    )
    
% SW1PerS - Sliding Windows and 1-Persistence Scoring
% BY: jose perea
% VERSION: 1.0 2014 05 22
%
% INPUT:
%   signal:             
%       The signal that will scored. The time poimts should be evenly
%       spaced (at least in this implementation). e.g. the times should be
%       1,2,3,4,5,6; not 1,2,3,7,8,9.
%       Type: vector of floats
%       Example: [1.2, 3.4, ..., 12.3]
%
%   num_cycles:             
%       The number of cycles to search for in the signal. For example, you
%       might want to search for 2 cycles in 2 days worth of circadian
%       data.
%       Type: float
%       Example: 2 
%
%   feature_type: 
%       How the persistence is measured.
%       Type: Choice of 1, 2, 3, 4, or 5. 
%       Example: We suggest 3.
%
%   num_points:             
%       Number of time points in point cloud.
%       Type: int
%       Example: 200
%
%   allow_trending:
%       Apply a point-wise mean-center.
%       Type: bool
%       Example: true or false, or 1 or 0
%
%   use_meanshift: 
%       Apply denoising by point-cloud-level version of moving average.
%       Type: bool
%       Example: true or false, or 1 or 0
%   meanshift_epsilon:
%       Parameter for mean shift. 
%       We suggest 1 - cos(pi/16).
%       Type: int
%       Example: 1 - cos(pi/16)
%
%   use_expaverage:
%       Apply a low pass filter denoising via exponential moving average.
%       Type: bool
%       Example: true or false, or 1 or 0
%   expaverage_alpha:
%       Parameter for exponential moving average.
%       Type: float
%       Example: 0.3
%
%   use_movingaverage:
%       Apply a smooth/low-pass denoising via moving average.
%       Type: bool
%       Example: true or false, or 1 or 0
%   movingaverage_window:
%       Parameter for moving average. Integer much smaller than the number 
%       of observations in the time series. 
%       We suggest about #obs/5
%       Type: int
%       Example: 5
%
%   use_smoothspline: 
%       Apply denoising via smoothing splines.
%       Type: bool
%       Example: true or false, or 1 or 0
%   smoothspline_sigma:
%       Parameter for smoothing spline.
%       Type: float
%       Example: 0.05
%
% OUTPUT:
%    score - row vector with the maximum persistence score. 
%


	nS = length(signal);

	signal = reshape(signal,1,[]);


	%% Part II - Define parameters 
	% Parameters for the sliding window cloud
	N = 7;                     % Highest Fourier Harmonic being captured
	p = 11;                    % A prime number (larger than N) for the Z/p calculation
	M = 2*N;                   % M+1 = dimension of the embedding
	tau = (2*pi)./((M+1)*num_cycles);   % step size = tau; window size = M*tau


	%% Part III - Signal pre-processing

	% Low pass filter denoising via exponential moving average
	if use_expaverage
		sigLowPass = signal;
		for i=2:nS
			sigLowPass(i) = sigLowPass(i-1) + (expaverage_alpha)*(signal(i) - sigLowPass(i-1));
		end
		signal = sigLowPass;
	end

	% Smooth/low-pass denoising  via moving average
	if use_movingaverage
		signal = smooth(signal',movingaverage_window,'moving')';
	end

	% detrending; not using currently because
	% decreased performance
	use_detrending = 0;
	if (use_detrending == 1)
		if (detrending_type == 1)
			% Eliminate piecewise-linear trends
			signal = detrend(signal, floor(nS/num_cycles));
		elseif (detrending_type == 2)
			% Eliminate a single linear trend
			signal = detrend(signal);
		end
	end


	%% Part IV Create Sliding Window point cloud data

	t = 2*pi*linspace(0,1,nS);

	T = (2*pi - M*tau)*linspace(0,1,num_points);
	tt = tau*(0:M)'*ones(1,num_points) + ones(M+1,1)*T;

	if use_smoothspline
		ss.weights = ones(1,nS);
		tolerance = nS*(smoothspline_sigma*peak2peak(signal)).^2;
		[sp, vals] =  spaps(t,signal,tolerance, ss.weights);
		cloud_raw = fnval(sp,tt);
		signal = vals;
	else
		cloud_raw = spline(t, signal , tt);
	end

	% Point-wise mean-center
	if allow_trending
		cloud_centered = cloud_raw - ones(M+1,1)*mean(cloud_raw);
	else
		cloud_centered = cloud_raw - mean(signal);
	end

	% Point-wise normalize
	SW_cloud = cloud_centered./( ones(M+1,1)*sqrt(sum(cloud_centered.^2)) );  
	SW_cloud = SW_cloud';


	%% Part V Point cloud level post-processing 

	% Denoising by mean-shift
	if use_meanshift
		cloud = zeros(size(SW_cloud));
		D = squareform(pdist(SW_cloud,'cosine'));
		indD = (D <= meanshift_epsilon);

		for k=1:num_points
			cloud(k,:) = mean( SW_cloud(indD(k,:),:) ) ;
		end

		SW_cloud = cloud;
	end


	%% Part VI maximum 1d-Persistence computation (tda)

	% load tda
	javaclasspath('tda/jars/tda_1.0.0_unionFind3.jar')
	import shell.*

					
	tda = Tda();

	tda.RCA1({'settingsFile=tda/cts.txt', ['zp_value=',num2str(p)], 'distanceBoundOnEdges=2'}, SW_cloud);

	intervals0 = tda.getResultsRCA1(0).getIntervals;
	intervals1 = tda.getResultsRCA1(1).getIntervals;


	if (isempty(intervals0) || isempty(intervals1))
		score = 1;
	else
		if (feature_type == 1)      % Feature 1
			score = 1 - max(intervals1(:,2) - intervals1(:,1))/sqrt(3);					
		elseif (feature_type == 2)  % Feature 2
			score = 1 - max(intervals1(:,2).^2 - intervals1(:,1)*max(intervals0(:,2)))/3;
		elseif (feature_type == 3)  % Feature 3
			score = 1 - max(intervals1(:,2).^2 - intervals1(:,1).^2)/3;
		elseif (feature_type == 4)  % Feature 4
			score = 1 - max(intervals1(:,2).^3 - intervals1(:,1).^2)/(3*sqrt(3));
		elseif (feature_type == 5)  % Feature 5
			score = 1 - max(intervals1(:,2).^4 - intervals1(:,1).^2)/9;
		end
	end


end

					
