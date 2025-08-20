% ===============================
% STEP 2: Convert Preprocessed EEG & EMG to Numeric Arrays
% ===============================
% Description:
%   This script takes preprocessed EEG and EMG data (stored as cell tables 
%   or heterogeneous structures) and converts them into clean numeric arrays.
%   Each session is flattened into [time x channels] matrices for easier 
%   downstream use in segmentation and LSTM model training.
%
% Inputs:
%   EEG_EMG_Preprocessed.mat   (contains EEG_processed, EMG_processed)
%
% Outputs:
%   EEG_EMG_Numeric.mat        (contains EEG_numeric, EMG_numeric)
%
% Author: Sania Dutta
% Date: [2025-07-01]

clc; clear;

%% ----------------------------
% Load Preprocessed Data
% ----------------------------
load('EEG_EMG_Preprocessed.mat');  % Variables: EEG_processed, EMG_processed

EEG_numeric = cell(size(EEG_processed));
EMG_numeric = cell(size(EMG_processed));

fprintf("Converting EEG and EMG data from %d sessions...\n", numel(EEG_processed));

%% ----------------------------
% Convert Cell/Struct Data to Numeric
% ----------------------------
for i = 1:numel(EEG_processed)
    eeg_raw = EEG_processed{i};
    emg_raw = EMG_processed{i};

    try
        % ---- EEG ----
        eeg_cols = [];
        for c = 1:width(eeg_raw)
            if iscell(eeg_raw{:,c})
                colData = cell2mat(eeg_raw{:,c});  % if stored as cell
            else
                colData = eeg_raw{:,c};            % if already numeric
            end
            eeg_cols = [eeg_cols, colData];
        end
        EEG_numeric{i} = eeg_cols;

        % ---- EMG ----
        emg_cols = [];
        for c = 1:width(emg_raw)
            if iscell(emg_raw{:,c})
                colData = cell2mat(emg_raw{:,c});
            else
                colData = emg_raw{:,c};
            end
            emg_cols = [emg_cols, colData];
        end
        EMG_numeric{i} = emg_cols;

    catch ME
        fprintf("Warning: Session %d could not be processed (%s)\n", i, ME.message);
        EEG_numeric{i} = [];
        EMG_numeric{i} = [];
    end
end

fprintf("Conversion complete.\n");
fprintf("EEG_numeric sessions: %d\n", numel(EEG_numeric));
fprintf("EMG_numeric sessions: %d\n", numel(EMG_numeric));

%% ----------------------------
% Save Numeric Dataset
% ----------------------------
save('EEG_EMG_Numeric.mat', 'EEG_numeric', 'EMG_numeric', '-v7.3');
fprintf("Saved numeric arrays → EEG_EMG_Numeric.mat\n");

%% ----------------------------
% Quick Sanity Check
% ----------------------------
load EEG_EMG_Numeric.mat
disp("Sample dimensions:");
disp(size(EEG_numeric{1}));  % e.g. [256 x N]
disp(size(EMG_numeric{1}));
