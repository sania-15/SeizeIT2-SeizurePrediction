% ===============================
% STEP 7: Statistical Analysis of EEG+EMG Segments
% ===============================
% Description:
%   This script performs a simple statistical analysis on the segmented 
%   EEG+EMG dataset. It extracts mean values from each channel (EEG1, EEG2, EMG),
%   compares seizure vs non-seizure distributions using Mann-Whitney U tests,
%   and visualizes results with boxplots.
%
% Inputs:
%   EEG_EMG_Segmented_Cleaned.mat (X_fixed, Y_fixed)
%
% Outputs:
%   - P-values from statistical tests (printed to console)
%   - Boxplots of feature distributions
%
% Author: Sania Dutta
% Date: [YYYY-MM-DD]

clc; clear;

%% ----------------------------
% Load Segmented Dataset
% ----------------------------
load("C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG_Segmented_Cleaned.mat");
X = X_fixed;
Y = Y_fixed;

fprintf("Loaded %d EEG+EMG segments.\n", numel(X));

% Ensure Y is column vector
if isrow(Y)
    Y = Y';
end

%% ----------------------------
% Feature Extraction
% ----------------------------
% Features: mean of each channel per segment
% Each sample is [640 x 3] → channels = EEG1, EEG2, EMG
features = zeros(numel(X), 3);

for i = 1:numel(X)
    sample = X{i};
    if isempty(sample) || size(sample, 2) ~= 3
        warning("Skipping sample %d due to incorrect shape.", i);
        continue;
    end
    features(i, :) = mean(sample, 1);  % mean across time dimension
end

% Group indices
idx_seizure    = Y == 1;
idx_nonseizure = Y == 0;

% Grouped feature sets
seizure_feats    = features(idx_seizure, :);
nonseizure_feats = features(idx_nonseizure, :);

feat_names = {'Mean EEG1', 'Mean EEG2', 'Mean EMG'};

%% ----------------------------
% Statistical Testing (Mann-Whitney U Test)
% ----------------------------
fprintf("\nPerforming Mann-Whitney U tests (Seizure vs Non-Seizure)...\n");

for i = 1:3
    p = ranksum(seizure_feats(:, i), nonseizure_feats(:, i));
    fprintf("- %s: p = %.4f\n", feat_names{i}, p);
end

%% ----------------------------
% Visualization: Boxplots
% ----------------------------
figure;
for i = 1:3
    subplot(1,3,i)
    boxplot([seizure_feats(:, i); nonseizure_feats(:, i)], ...
        [repmat({'Seizure'}, sum(idx_seizure), 1); ...
         repmat({'Non-Seizure'}, sum(idx_nonseizure), 1)]);
    title(feat_names{i});
    ylabel('Mean Value');
    grid on;
end
sgtitle("EEG+EMG Feature Distributions: Seizure vs Non-Seizure");
