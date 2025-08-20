% ===============================
% STEP 5: CNN-BiLSTM Fusion Model (Subset Training)
% ===============================
% Description:
%   This script defines and trains a CNN-BiLSTM hybrid model on a 
%   subset of the EEG+EMG dataset. The CNN layers capture local 
%   spatial patterns, while the BiLSTM layer models temporal dependencies.
%
%   Workflow:
%     - Load cleaned and split dataset
%     - Select a smaller subset for faster training
%     - Define CNN-BiLSTM architecture
%     - Train and validate model
%     - Save trained model and report performance
%
% Inputs:
%   EEG_EMG_Segmented_Cleaned.mat (cleaned signals)
%   EEG_EMG_SplitData.mat         (X_train, Y_train, X_val, Y_val)
%
% Outputs:
%   CNN_BiLSTM_TrainedModel_Subset.mat (trained model)
%
% Author: Sania Dutta
% Date: [YYYY-MM-DD]

% clc; clear;   % Uncomment if running standalone

%% ----------------------------
% Load Data
% ----------------------------
load("C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG_Segmented_Cleaned.mat");  
load("C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG_SplitData.mat");

%% ----------------------------
% Select Subset for Quick Training
% ----------------------------
X_train = X_train(1:10000);
Y_train = Y_train(1:10000);
X_val   = X_val(1:1000);
Y_val   = Y_val(1:1000);

% Transpose each segment → [features x time]
X_train = cellfun(@(x) x.', X_train, 'UniformOutput', false);
X_val   = cellfun(@(x) x.', X_val,   'UniformOutput', false);

fprintf("Prepared subset. Example input size: %s\n", mat2str(size(X_train{1})));

%% ----------------------------
% Define CNN-BiLSTM Architecture
% ----------------------------
inputSize   = size(X_train{1}, 1);    % Expected = 3 channels
seqLength   = size(X_train{1}, 2);    % Expected = 640 timesteps
numClasses  = numel(unique(Y_train)); % Binary classification (0/1)

layers = [
    sequenceInputLayer(inputSize, "Name", "input")

    convolution1dLayer(3, 16, "Padding", "same", "Name", "conv1")
    batchNormalizationLayer("Name", "bn1")
    reluLayer("Name", "relu1")
    dropoutLayer(0.1, "Name", "drop1")

    convolution1dLayer(3, 32, "Padding", "same", "Name", "conv2")
    batchNormalizationLayer("Name", "bn2")
    reluLayer("Name", "relu2")
    dropoutLayer(0.2, "Name", "drop2")

    convolution1dLayer(3, 64, "Padding", "same", "Name", "conv3")
    batchNormalizationLayer("Name", "bn3")
    reluLayer("Name", "relu3")
    dropoutLayer(0.1, "Name", "drop3")

    bilstmLayer(128, 'OutputMode', 'sequence', 'Name', 'bilstm')

    fullyConnectedLayer(32, "Name", "fc1")
    reluLayer("Name", "relu_fc1")

    fullyConnectedLayer(numClasses, "Name", "fc2")
    softmaxLayer("Name", "softmax")
    classificationLayer("Name", "output")];

%% ----------------------------
% Training Options
% ----------------------------
options = trainingOptions("adam", ...
    "MaxEpochs", 25, ...
    "MiniBatchSize", 32, ...
    "Shuffle", "every-epoch", ...
    "ValidationData", {X_val, categorical(Y_val)}, ...
    "ValidationFrequency", 10, ...
    "ValidationPatience", 5, ...
    "LearnRateSchedule", "piecewise", ...
    "LearnRateDropFactor", 0.5, ...
    "LearnRateDropPeriod", 5, ...
    "Verbose", true, ...
    "Plots", "training-progress", ...
    "ExecutionEnvironment", "cpu", ...
    "OutputNetwork", "best-validation-loss");

%% ----------------------------
% Train Model
% ----------------------------
fprintf("Training CNN-BiLSTM model on subset...\n");
Y_train_cat = categorical(Y_train);
net = trainNetwork(X_train, Y_train_cat, layers, options);

% Save trained model
save("CNN_BiLSTM_TrainedModel_Subset.mat", "net");
fprintf("Training complete. Model saved → CNN_BiLSTM_TrainedModel_Subset.mat\n");

%% ----------------------------
% Evaluate on Validation Set
% ----------------------------
YPred = classify(net, X_val);
YTrue = categorical(Y_val);

% Confusion matrix
figure;
confusionchart(YTrue, YPred);
title("Validation Confusion Matrix - CNN-BiLSTM");

%% ----------------------------
% Compute Precision, Recall, F1
% ----------------------------
YPred_num = double(YPred);
YTrue_num = double(YTrue);

TP = sum((YPred_num == 1) & (YTrue_num == 1));
FP = sum((YPred_num == 1) & (YTrue_num == 0));
FN = sum((YPred_num == 0) & (YTrue_num == 1));

precision = TP / (TP + FP + eps);
recall    = TP / (TP + FN + eps);
F1        = 2 * (precision * recall) / (precision + recall + eps);

fprintf("Validation Precision: %.4f\n", precision);
fprintf("Validation Recall: %.4f\n", recall);
fprintf("Validation F1 Score: %.4f\n", F1);
