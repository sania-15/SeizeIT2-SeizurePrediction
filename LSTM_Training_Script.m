% ===============================
% STEP 4A: Train / Validation / Test Split
% ===============================
% Description:
%   This script prepares the dataset for model training.
%   - Ensures all EEG/EMG segments are [640 x 3] (padding/trimming if needed)
%   - Removes corrupted or invalid samples
%   - Shuffles the dataset (fixed random seed for reproducibility)
%   - Splits data into Train (70%), Validation (15%), and Test (15%)
%   - Saves the split dataset for later use
%
% Inputs:
%   EEG_EMG_Segmented.mat (X, Y) – raw segmented data
%
% Outputs:
%   EEG_EMG_Segmented_Cleaned.mat (X_fixed, Y_fixed)
%   EEG_EMG_SplitData.mat (X_train, Y_train, X_val, Y_val, X_test, Y_test)
%
% Author: Sania Dutta
% Date: [YYYY-MM-DD]

clc; clear;

%% ----------------------------
% Load Segmented Data
% ----------------------------
load("C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG_Segmented.mat");  % X, Y
fprintf("Loaded %d segments before cleaning.\n", numel(X));

%% ----------------------------
% Enforce Uniform Shape [640 x 3]
% ----------------------------
fprintf("Checking and fixing segments...\n");

X_fixed = {};
Y_fixed = [];

for i = 1:numel(X)
    seg = X{i};

    % Check that segment is numeric with correct length (640 time steps)
    if isnumeric(seg) && size(seg,1) == 640
        % If already 3 channels → keep
        if size(seg,2) == 3
            X_fixed{end+1} = seg;
            Y_fixed(end+1) = Y(i);

        % If fewer than 3 channels → pad with zeros
        elseif size(seg,2) < 3
            padded = [seg, zeros(640, 3 - size(seg,2))];
            X_fixed{end+1} = padded;
            Y_fixed(end+1) = Y(i);
            fprintf("Padded segment %d: had %d channels → padded to 3.\n", i, size(seg,2));

        % If more than 3 channels → trim extras
        elseif size(seg,2) > 3
            trimmed = seg(:,1:3);
            X_fixed{end+1} = trimmed;
            Y_fixed(end+1) = Y(i);
            fprintf("Trimmed segment %d: had %d channels → kept first 3.\n", i, size(seg,2));
        end

    else
        % Completely invalid → skip
        fprintf("Removed segment %d (invalid size: %s).\n", i, mat2str(size(seg)));
    end
end

fprintf("Cleaning complete: retained %d valid segments.\n", numel(X_fixed));

% Save cleaned dataset
save("EEG_EMG_Segmented_Cleaned.mat", "X_fixed", "Y_fixed", "-v7.3");

%% ----------------------------
% Reload Cleaned Data & Shuffle
% ----------------------------
load("C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG_Segmented_Cleaned.mat");

rng(42);  % Fixed seed for reproducibility
n = numel(X_fixed);
idx = randperm(n);

X_fixed = X_fixed(idx);
Y_fixed = Y_fixed(idx);

%% ----------------------------
% Split into Train / Validation / Test
% ----------------------------
nTrain = round(0.7 * n);
nVal   = round(0.15 * n);
nTest  = n - nTrain - nVal;

X_train = X_fixed(1:nTrain);            Y_train = Y_fixed(1:nTrain);
X_val   = X_fixed(nTrain+1:nTrain+nVal);Y_val   = Y_fixed(nTrain+1:nTrain+nVal);
X_test  = X_fixed(nTrain+nVal+1:end);   Y_test  = Y_fixed(nTrain+nVal+1:end);

% Save split dataset
save("C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG_SplitData.mat", ...
     "X_train","Y_train","X_val","Y_val","X_test","Y_test","-v7.3");

fprintf("Dataset split complete:\n");
fprintf("- Train: %d\n- Validation: %d\n- Test: %d\n", numel(X_train), numel(X_val), numel(X_test));

%% ----------------------------
% Quick Sanity Check
% ----------------------------
fprintf("\nChecking shape of first few samples...\n");
for i = 1:min(5,numel(X_train))
    sz = size(X_train{i});
    fprintf("Sample %d → [%d x %d]\n", i, sz(1), sz(2));
end

fprintf("\nScanning full training set...\n");
incorrectIdx = [];
for i = 1:numel(X_train)
    sz = size(X_train{i});
    if sz(1) ~= 640 || sz(2) ~= 3 || ~isnumeric(X_train{i})
        incorrectIdx(end+1) = i;
    end
end

if isempty(incorrectIdx)
    fprintf("All %d training samples are valid [640 x 3].\n", numel(X_train));
else
    fprintf("%d segments had incorrect size/type.\n", numel(incorrectIdx));
    disp(incorrectIdx(1:min(10,end)));  % Show first few problematic indices
end
