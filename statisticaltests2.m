% ===============================
% STEP 7B: Quick Evaluation on Small Test Subset
% ===============================
% Description:
%   This script evaluates a trained model (LSTM or CNN-BiLSTM) on a small 
%   subset of the test data. This is useful for quick checks without 
%   running through the full test set (avoids memory overload).
%
%   - Loads trained model and test data
%   - Runs classification on a small batch of test samples
%   - Saves predictions, scores, and ground truth for further analysis
%   - Prints the contents of key .mat files (for debugging)
%
% Inputs:
%   LSTM_TrainedModel_Subset.mat OR CNN_BiLSTM_TrainedModel_Subset.mat
%   EEG_EMG_SplitData.mat (contains X_test, Y_test)
%
% Outputs:
%   Model_EvalResults.mat (Y_smallTrue, YPredicted, Scores)
%
% Author: Sania Dutta
% Date: [YYYY-MM-DD]

clc; clear;

%% ----------------------------
% Load Trained Model & Test Data
% ----------------------------
load('LSTM_TrainedModel_Subset.mat');   % Replace with CNN_BiLSTM if needed
load('EEG_EMG_SplitData.mat');          % Provides X_test, Y_test

%% ----------------------------
% Select Small Test Subset
% ----------------------------
N = 200;  % number of test samples to evaluate
X_smallTest = X_test(1:N);
Y_smallTrue = Y_test(1:N);

% Transpose input data if necessary [time x features] → [features x time]
X_smallTest = cellfun(@(x) x.', X_smallTest, 'UniformOutput', false);

%% ----------------------------
% Model Prediction
% ----------------------------
[YPredicted, Scores] = classify(net, X_smallTest);

% Save evaluation results for later analysis
save('Model_EvalResults.mat', 'Y_smallTrue', 'YPredicted', 'Scores');
fprintf("Evaluation complete. Results saved → Model_EvalResults.mat\n");

%% ----------------------------
% Debugging: Inspect Key MAT Files
% ----------------------------
fileList = {
    "C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG_Segmented_Cleaned.mat"
    "C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG_Numeric.mat"
    "C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG_SplitData.mat"
};

for i = 1:length(fileList)
    fprintf('\nInspecting contents of: %s\n', fileList{i});
    m = matfile(fileList{i});
    whos(m)   % List variables inside the .mat file
end
