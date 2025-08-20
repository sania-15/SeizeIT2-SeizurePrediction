% ===============================
% DONT USE - Feature Extraction from EEG+EMG Batches
% ===============================
% Description:
%   This script extracts simple statistical features (mean, std, skewness, 
%   kurtosis) from preprocessed EEG+EMG recordings stored in batch files. 
%   Features are saved to CSV for downstream machine learning models.
%
%   Note:
%     This was one of my **initial approaches**, where I processed 
%     *all batches of data equally*. 
%     Later, I realized this was inefficient: only ~30 out of 1000+ 
%     sessions actually contained seizures. A better approach is to 
%     specifically sieve out seizure sessions and match them with 
%     balanced non-seizure data, rather than extracting features 
%     blindly from the entire dataset.
%
% Inputs:
%   batch_XX.mat (containing EEG_data, EMG_data, Labels)
%
% Outputs:
%   features_batch_XXtoYY.csv (tabular statistical features + labels)
%
% Author: Sania Dutta
% Date: [YYYY-MM-DD]

clc; clear;

%% ----------------------------
% User Settings
% ----------------------------
baseFolder = "C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG";
startBatch = 1;       % first batch to include
endBatch   = 5;       % last batch to include
csvOut     = fullfile(baseFolder, sprintf("features_batch_%02dto%02d.csv", startBatch, endBatch));

featureTable = [];    % initialize storage

%% ----------------------------
% Loop Through Batches
% ----------------------------
for batchNum = startBatch:endBatch
    batchFile = fullfile(baseFolder, sprintf("batch_%02d.mat", batchNum));

    if ~isfile(batchFile)
        warning("Batch %02d missing. Skipping...", batchNum);
        continue;
    end

    fprintf("Loading Batch %02d...\n", batchNum);
    try
        S = load(batchFile);
        eegAll = S.EEG_data;
        emgAll = S.EMG_data;
        labels = S.Labels;
    catch
        warning("Error loading Batch %02d. Skipping...", batchNum);
        continue;
    end

    % ----------------------------
    % Extract Features Per Sample
    % ----------------------------
    for i = 1:numel(eegAll)
        try
            eeg = eegAll{i};
            emg = emgAll{i};

            % Convert timetable → numeric
            if istimetable(eeg), eeg = eeg.Variables; end
            if istimetable(emg), emg = emg.Variables; end

            eeg = double(eeg);
            emg = double(emg);

            % Match lengths
            minLen = min(size(eeg,1), size(emg,1));
            eeg = eeg(1:minLen,:);
            emg = emg(1:minLen,:);

            % Optional: fuse channels by averaging
            fused = [mean(eeg,2), mean(emg,2)];  % [time x 2]

            % Extract basic statistics per channel
            feats = [mean(fused); std(fused); skewness(fused); kurtosis(fused)];

            % Store row in table
            row = array2table(feats(:)', ...
                'VariableNames', compose("f%d", 1:numel(feats)));
            row.Label = categorical(labels(i));

            featureTable = [featureTable; row];

        catch ME
            warning("Error in Batch %02d, Sample %d: %s", batchNum, i, ME.message);
            continue;
        end
    end
end

%% ----------------------------
% Save Features to CSV
% ----------------------------
writetable(featureTable, csvOut);
fprintf("Feature CSV saved → %s\n", csvOut);
