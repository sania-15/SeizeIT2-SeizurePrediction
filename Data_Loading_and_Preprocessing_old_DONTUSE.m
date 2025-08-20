% ===============================
% DONT USE - INITIAL ATTEMPT: Batch Loading of EEG+EMG Data
% ===============================
% Description:
%   This script was one of my first attempts to preprocess the entire 
%   dataset in batches of subjects. The idea was to load EEG and EMG 
%   signals for each subject, align them, and save them batch-wise 
%   for downstream processing. 
%
%   However, this approach turned out to be inefficient: 
%     - Out of ~1000+ subject/session files, only ~30 contained actual 
%       seizure data. 
%     - Processing everything wasted time and memory, while the real 
%       challenge was to sieve out seizure vs. non-seizure data and 
%       balance them for training. 
%
%   I have kept this script in the repository for transparency, as it 
%   documents my initial exploration and the lesson learned.
%
% Inputs:
%   EEG_EMG (sub- folders with EEG/EMG .edf files)
%
% Outputs:
%   Batch files (batch_01.mat, batch_02.mat, …) with EEG_data, EMG_data, Labels
%
% Author: Sania Dutta
% Date: [YYYY-MM-DD]

%% ----------------------------
% Batch 1 to 10
% ----------------------------
clc; clear;

baseFolder = "C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG";
subjectFolders = dir(baseFolder);
subjectFolders = subjectFolders([subjectFolders.isdir] & startsWith({subjectFolders.name}, "sub-"));

batchSize = 5;
totalSubjects = length(subjectFolders);
fprintf("Starting batch-wise data loading (%d subjects total)\n", totalSubjects);

batchNum = 1;

for i = 1:batchSize:totalSubjects
    EEG_data = {};
    EMG_data = {};
    Labels   = [];

    batchEnd = min(i + batchSize - 1, totalSubjects);
    fprintf("\nProcessing batch %d: Subjects %d to %d\n", batchNum, i, batchEnd);

    for j = i:batchEnd
        subjName = subjectFolders(j).name;
        eegFolder = fullfile(baseFolder, subjName, "eeg");
        emgFolder = fullfile(baseFolder, subjName, "emg");

        eegFiles = dir(fullfile(eegFolder, "*.edf"));
        emgFiles = dir(fullfile(emgFolder, "*.edf"));

        if isempty(eegFiles) || isempty(emgFiles)
            fprintf("Skipping %s (missing EEG or EMG)\n", subjName);
            continue;
        end

        minFiles = min(length(eegFiles), length(emgFiles));

        for k = 1:minFiles
            eegPath = fullfile(eegFolder, eegFiles(k).name);
            emgPath = fullfile(emgFolder, emgFiles(k).name);

            fprintf("[%s] File %d | EEG: %s | EMG: %s\n", ...
                subjName, k, eegFiles(k).name, emgFiles(k).name);

            try
                [eeg_signal, ~] = edfread(eegPath);
                [emg_signal, ~] = edfread(emgPath);

                minLen = min(size(eeg_signal, 2), size(emg_signal, 2));
                eeg_signal = eeg_signal(:, 1:minLen);
                emg_signal = emg_signal(:, 1:minLen);

                EEG_data{end+1} = eeg_signal;
                EMG_data{end+1} = emg_signal;
                Labels(end+1)   = 0;  % placeholder

            catch ME
                fprintf("Error in %s file %d: %s\n", subjName, k, ME.message);
            end
        end
    end

    % Save each batch separately
    filename = sprintf("batch_%02d.mat", batchNum);
    save(fullfile(baseFolder, filename), 'EEG_data', 'EMG_data', 'Labels', '-v7.3');
    fprintf("Batch %d saved as %s\n", batchNum, filename);

    batchNum = batchNum + 1;
    clear EEG_data EMG_data Labels
end

fprintf("\nAll batches processed and saved successfully!\n");
