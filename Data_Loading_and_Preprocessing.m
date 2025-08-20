% ===============================
% STEP 1A: Preprocess EEG & EMG Signals
% ===============================
% Description:
%   This script applies preprocessing to raw EEG and EMG signals:
%   - Bandpass filtering (EEG: 0.5–45 Hz, EMG: 10–120 Hz)
%   - Optional 50 Hz notch filter (to remove power line noise)
%   - Z-score normalization (channel-wise)
%
% Inputs:
%   preprocess_eeg_emg_sessions.mat  (contains EEG_data, EMG_data)
%
% Outputs:
%   EEG_EMG_Preprocessed.mat         (contains EEG_processed, EMG_processed)
%
% Author: Sania Dutta
% Date: [2025-07-01]

clear; clc;

%% ----------------------------
% Load Data
% ----------------------------
% NOTE: this should be a .mat file, not the .m script
load("C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\preprocess_eeg_emg_sessions.mat");  
% Variables expected: EEG_data, EMG_data

fs = 256;       % Sampling rate [Hz]
notchFreq = 50; % Power line interference frequency [Hz]

% Define bandpass ranges
eeg_band = [0.5 45];   % EEG: typical range for seizure-related analysis
emg_band = [10 120];   % EMG: retains muscle activity, removes drift

% Preallocate output cell arrays
EEG_processed = cell(size(EEG_data));
EMG_processed = cell(size(EMG_data));

%% ----------------------------
% Preprocessing Loop
% ----------------------------
for i = 1:length(EEG_data)
    fprintf('Processing Session %02d...\n', i);
    
    % ----- EEG Preprocessing -----
    eeg_raw = EEG_data{i};
    
    % Bandpass filter
    eeg_filt = bandpass(eeg_raw, eeg_band, fs);
    
    % Notch filter (50 Hz)
    d = designfilt('bandstopiir', 'FilterOrder', 2, ...
        'HalfPowerFrequency1', notchFreq-1, ...
        'HalfPowerFrequency2', notchFreq+1, ...
        'DesignMethod', 'butter', 'SampleRate', fs);
    eeg_notched = filtfilt(d, eeg_filt);
    
    % Z-score normalization (per channel)
    eeg_norm = (eeg_notched - mean(eeg_notched, 1)) ./ std(eeg_notched, [], 1);
    EEG_processed{i} = eeg_norm;
    
    % ----- EMG Preprocessing -----
    emg_raw = EMG_data{i};
    
    % Bandpass filter
    emg_filt = bandpass(emg_raw, emg_band, fs);
    
    % Apply same notch filter
    emg_notched = filtfilt(d, emg_filt);
    
    % Z-score normalization
    emg_norm = (emg_notched - mean(emg_notched, 1)) ./ std(emg_notched, [], 1);
    EMG_processed{i} = emg_norm;
    
    fprintf('Session %02d completed.\n', i);
end

%% ----------------------------
% Save Processed Data
% ----------------------------
save('EEG_EMG_Preprocessed.mat', 'EEG_processed', 'EMG_processed');
fprintf('\nAll sessions preprocessed and saved → EEG_EMG_Preprocessed.mat\n');
