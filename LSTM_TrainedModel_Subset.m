% ===============================
% STEP 4B: LSTM Model Definition & Training (Subset Version)
% ===============================
% Description:
%   This script defines and trains a simple LSTM network on a small subset 
%   of the cleaned EEG+EMG dataset. It is mainly used for quick testing 
%   of architecture and training stability before running on the full dataset.
%
% Inputs:
%   EEG_EMG_Segmented_Cleaned.mat (X_fixed, Y_fixed)
%   EEG_EMG_SplitData.mat         (X_train, Y_train, X_val, Y_val)
%
% Outputs:
%   LSTM_TrainedModel_Subset.mat (trained LSTM model on small subset)
%
% Author: Sania Dutta
% Date: [YYYY-MM-DD]

clc; clear;

%% ----------------------------
% Load Data
% ----------------------------
load("C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG_Segmented_Cleaned.mat");  
load("C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG_SplitData.mat");          

fprintf("Full dataset loaded. Training: %d | Validation: %d\n", ...
    numel(X_train), numel(X_val));

%% ----------------------------
% Select a Small Subset for Quick Testing
% ----------------------------
N_train = 500;   % use only 500 training samples
N_val   = 100;   % use only 100 validation samples

X_train_sub = X_train(1:N_train);
Y_train_sub = Y_train(1:N_train);
X_val_sub   = X_val(1:N_val);
Y_val_sub   = Y_val(1:N_val);

% Transpose segments → [features x timeSteps]
X_train_sub = cellfun(@(x) x.', X_train_sub, 'UniformOutput', false);
X_val_sub   = cellfun(@(x) x.', X_val_sub,   'UniformOutput', false);

fprintf("Subset prepared: Training = %d | Validation = %d\n", ...
    numel(X_train_sub), numel(X_val_sub));
disp("Example input size: " + mat2str(size(X_train_sub{1})));

%% ----------------------------
% LSTM Network Architecture
% ----------------------------
inputSize      = size(X_train_sub{1}, 1);  % number of features (should be 3: EEG+EMG channels)
numHiddenUnits = 100;                      % hidden state size
numClasses     = numel(unique(Y_train_sub)); % number of output classes

layers = [ ...
    sequenceInputLayer(inputSize)
    lstmLayer(numHiddenUnits, 'OutputMode', 'last')
    dropoutLayer(0.5)  % regularization to reduce overfitting
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer];

%% ----------------------------
% Training Options
% ----------------------------
maxEpochs     = 5;    % short run for testing
miniBatchSize = 64;   % batch size

options = trainingOptions('adam', ...
    'MaxEpochs', maxEpochs, ...
    'MiniBatchSize', miniBatchSize, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', {X_val_sub, categorical(Y_val_sub)}, ...
    'ValidationFrequency', 10, ...
    'Plots', 'training-progress', ...
    'Verbose', true, ...
    'ExecutionEnvironment', 'auto', ...
    'OutputNetwork', 'best-validation-loss', ...
    'CheckpointPath', tempdir);

%% ----------------------------
% Train the Model
% ----------------------------
fprintf("Training small LSTM model on subset...\n");

Y_train_cat = categorical(Y_train_sub);
net = trainNetwork(X_train_sub, Y_train_cat, layers, options);

fprintf("Training complete. Model stored in variable 'net'.\n");

% Save trained model
save('LSTM_TrainedModel_Subset.mat', 'net');
fprintf("Saved trained model → LSTM_TrainedModel_Subset.mat\n");
