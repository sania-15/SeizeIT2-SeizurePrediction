% ===============================
% STEP 3: Segment EEG + EMG for LSTM Training
% ===============================
% Description:
%   This script segments preprocessed EEG and EMG recordings into 
%   fixed-length windows suitable for LSTM training.
%
%   Each session is split into 5-second windows (640 samples at 128 Hz). 
%   Segments are labeled based on whether they come from seizure or 
%   non-seizure sessions. 
%
%   Note:
%     In this early attempt I processed *all sessions equally*. 
%     Later, I realized the dataset is highly imbalanced (~30 seizure 
%     sessions out of 1000+ total). A better strategy is to specifically 
%     sieve out seizure segments and select matching non-seizure controls 
%     rather than segmenting everything. I’ve kept this script to 
%     document that learning process.
%
% Inputs:
%   EEG_EMG_Numeric.mat   (EEG_numeric, EMG_numeric)
%
% Outputs:
%   EEG_EMG_Segmented.mat (X, Y) → segmented data and labels
%
% Author: Sania Dutta
% Date: [2025-07-02]

clc; clear;

%% ----------------------------
% Parameters
% ----------------------------
windowLengthSec = 5;               % Window length [s]
samplingRate    = 128;             % Hz
segmentLength   = windowLengthSec * samplingRate;  % 640 samples per segment

% Load numeric EEG+EMG data
load('C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG_Numeric.mat');  
% Variables: EEG_numeric, EMG_numeric

fprintf("Segmenting EEG+EMG from %d sessions...\n", numel(EEG_numeric));

%% ----------------------------
% Initialize storage
% ----------------------------
X = {};  % segmented data
Y = [];  % labels

numSessions        = 56;   % total sessions considered
numSeizureSessions = 28;   % seizure-labeled sessions
labels = [ones(1,numSeizureSessions), zeros(1,numSessions-numSeizureSessions)];

%% ----------------------------
% Segment Each Session
% ----------------------------
for i = 1:numSessions
    eeg = EEG_numeric{i};
    emg = EMG_numeric{i};

    % Convert timetable to array if needed
    if istimetable(eeg), eeg = table2array(eeg(:,2:end)); end
    if istimetable(emg), emg = table2array(emg(:,2:end)); end

    % Skip empty or invalid signals
    if isempty(eeg) || isempty(emg) || size(eeg,2)==0 || size(emg,2)==0
        warning("Skipping session %d (empty or invalid data).", i);
        continue;
    end

    % Match signal lengths
    minLen = min(size(eeg,1), size(emg,1));
    eeg = eeg(1:minLen,:);
    emg = emg(1:minLen,:);

    % Segment into non-overlapping windows
    totalSegments = floor(minLen / segmentLength);

    for s = 1:totalSegments
        idxStart = (s-1)*segmentLength + 1;
        idxEnd   = s*segmentLength;

        eegSeg = eeg(idxStart:idxEnd,:); 
        emgSeg = emg(idxStart:idxEnd,:);

        % Combine EEG + EMG → [640 x (C1+C2)]
        if isnumeric(eegSeg) && isnumeric(emgSeg)
            segment = [eegSeg, emgSeg];

            % Skip flatline or NaN-heavy windows
            if all(isnan(segment),'all') || std(segment,0,'all') < 1e-6
                warning("Flat/NaN segment in session %d skipped.", i);
                continue;
            end

            X{end+1} = segment;
            Y(end+1) = labels(i);  % 1=seizure, 0=non-seizure
        else
            warning("Non-numeric data in session %d skipped.", i);
        end
    end

    fprintf("Session %d → %d segments extracted.\n", i, totalSegments);
end

fprintf("All sessions processed. Total segments = %d\n", numel(X));

%% ----------------------------
% Save Segmented Dataset
% ----------------------------
save('C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG_Segmented.mat', ...
    'X','Y','-v7.3');
fprintf("Saved segmented dataset → EEG_EMG_Segmented.mat\n");

%% ----------------------------
% Class Distribution
% ----------------------------
fprintf("\nFinal class distribution:\n");
tabulate(Y')

%% ----------------------------
% OPTIONAL: Diagnostic Block
% ----------------------------
fprintf("\nChecking EEG/EMG contents...\n");
emptyEEG = 0; emptyEMG = 0;

for i = 1:numel(EEG_numeric)
    if isempty(EEG_numeric{i}), fprintf("EEG session %d is EMPTY\n", i); emptyEEG=emptyEEG+1; end
    if isempty(EMG_numeric{i}), fprintf("EMG session %d is EMPTY\n", i); emptyEMG=emptyEMG+1; end
end

fprintf("\nEmpty EEG sessions: %d\n", emptyEEG);
fprintf("Empty EMG sessions: %d\n", emptyEMG);
