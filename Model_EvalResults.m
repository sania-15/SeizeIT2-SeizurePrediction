% ===============================
% STEP 6: Model Evaluation - LSTM vs CNN-BiLSTM
% ===============================
% Description:
%   This script evaluates trained LSTM and CNN-BiLSTM models on the test set.
%   It computes classification accuracy, confusion matrices, and advanced metrics 
%   (precision, recall, F1-score, ROC and PR curves, threshold analysis).
%   Use this to compare the performance of different architectures.
%
% Inputs:
%   - EEG_EMG_SplitData.mat          (contains X_test, Y_test)
%   - LSTM_TrainedModel_Subset.mat   (trained LSTM network)
%   - CNN_BiLSTM_TrainedModel_Subset.mat (trained CNN-BiLSTM network)
%
% Outputs:
%   - Printed evaluation metrics
%   - Confusion matrices and performance plots
%
% Author: Sania Dutta
% Date: [YYYY-MM-DD]

clc; clear;

%% ----------------------------
% Load Test Data
% ----------------------------
fprintf("Loading test data...\n");
load("C:/Users/User/OneDrive - Politechnika Śląska/Semester 6/IEEE internship/EEG_EMG_SplitData.mat");  
fprintf("Test data loaded: %d samples\n", numel(X_test));

%% ----------------------------
% Load Trained Models
% ----------------------------
fprintf("Loading trained models...\n");
lstmModel     = load("C:/Users/User/OneDrive - Politechnika Śląska/Semester 6/IEEE internship/LSTM_TrainedModel_Subset.mat");
cnnBiLstmModel = load("C:/Users/User/OneDrive - Politechnika Śląska/Semester 6/IEEE internship/CNN_BiLSTM_TrainedModel_Subset.mat");

netLSTM      = lstmModel.net;
netCNNBiLSTM = cnnBiLstmModel.net;

%% ----------------------------
% Prepare Test Data
% ----------------------------
Y_test_cat = categorical(Y_test);

% LSTM/CNN-BiLSTM expect input as [features x timeSteps], so transpose each trial
X_test_transposed = cellfun(@(x) x.', X_test, 'UniformOutput', false);

%% ----------------------------
% Evaluate LSTM Model
% ----------------------------
fprintf("Evaluating LSTM model...\n");
YPred_LSTM = classify(netLSTM, X_test_transposed);

% Manual accuracy calculation (avoids memory issues for large arrays)
correct = sum(YPred_LSTM == Y_test_cat);
acc_LSTM = correct / numel(Y_test_cat);
fprintf("LSTM Accuracy: %.2f%%\n", acc_LSTM * 100);

%% ----------------------------
% Evaluate CNN-BiLSTM Model
% ----------------------------
fprintf("Evaluating CNN-BiLSTM model...\n");
YPred_CNNBiLSTM = classify(netCNNBiLSTM, X_test_transposed);

correct_cnn = sum(YPred_CNNBiLSTM == Y_test_cat);
acc_CNNBiLSTM = correct_cnn / numel(Y_test_cat);
fprintf("CNN-BiLSTM Accuracy: %.2f%%\n", acc_CNNBiLSTM * 100);

%% ----------------------------
% Confusion Matrices
% ----------------------------
figure;
confusionchart(Y_test_cat, YPred_LSTM);
title("Confusion Matrix - LSTM");

figure;
confusionchart(Y_test_cat, YPred_CNNBiLSTM);
title("Confusion Matrix - CNN-BiLSTM");

%% ----------------------------
% Compute Precision, Recall, F1
% ----------------------------
% Requires confusionmatStats.m (File Exchange)
stats_LSTM     = confusionmatStats(double(Y_test_cat), double(YPred_LSTM));
stats_CNNBiLSTM = confusionmatStats(double(Y_test_cat), double(YPred_CNNBiLSTM));

fprintf("\nLSTM Metrics:\n");     disp(stats_LSTM)
fprintf("\nCNN-BiLSTM Metrics:\n"); disp(stats_CNNBiLSTM)

%% ----------------------------
% Manual Metric Calculation (example values from confusion matrix)
% ----------------------------
% Replace these with dynamically computed values if available
TP_LSTM = 53586; FP_LSTM = 38963; FN_LSTM = 20738; TN_LSTM = 25219;
TP_CNN  = 51991; FP_CNN  = 37031; FN_CNN  = 22333; TN_CNN  = 27151;

calc_metrics = @(TP, FP, FN, TN) struct( ...
    'Accuracy', (TP + TN) / (TP + TN + FP + FN), ...
    'Precision', TP / (TP + FP), ...
    'Recall', TP / (TP + FN), ...
    'Specificity', TN / (TN + FP), ...
    'F1', 2 * TP / (2 * TP + FP + FN), ...
    'BalancedAccuracy', ((TP / (TP + FN)) + (TN / (TN + FP))) / 2);

metricsLSTM = calc_metrics(TP_LSTM, FP_LSTM, FN_LSTM, TN_LSTM);
metricsCNN  = calc_metrics(TP_CNN, FP_CNN, FN_CNN, TN_CNN);

fprintf("\nFinal Metrics (LSTM):\n"); disp(metricsLSTM)
fprintf("\nFinal Metrics (CNN-BiLSTM):\n"); disp(metricsCNN)

%% ----------------------------
% ROC Curve (AUC)
% ----------------------------
fprintf("Computing ROC curves...\n");

batchSize = 10000;
numBatches = ceil(numel(X_test) / batchSize);

probs_LSTM = []; probs_CNN = [];

for i = 1:numBatches
    idxStart = (i - 1) * batchSize + 1;
    idxEnd   = min(i * batchSize, numel(X_test));
    batchData = X_test_transposed(idxStart:idxEnd);

    scoresLSTM = predict(netLSTM, batchData);
    scoresCNN  = predict(netCNNBiLSTM, batchData);

    probs_LSTM = [probs_LSTM; scoresLSTM(:,2)];
    probs_CNN  = [probs_CNN; scoresCNN(:,2)];
end

Y_numeric = double(Y_test_cat);  

figure;
[X_lstm, Y_lstm, ~, AUC_LSTM] = perfcurve(Y_numeric, probs_LSTM, 1);
[X_cnn,  Y_cnn,  ~, AUC_CNN]  = perfcurve(Y_numeric, probs_CNN,  1);

plot(X_lstm, Y_lstm, 'b-', 'LineWidth', 2); hold on;
plot(X_cnn,  Y_cnn,  'r-', 'LineWidth', 2);
xlabel('False Positive Rate'); ylabel('True Positive Rate');
legend(sprintf('LSTM (AUC = %.2f)', AUC_LSTM), ...
       sprintf('CNN-BiLSTM (AUC = %.2f)', AUC_CNN));
title('ROC Curve - LSTM vs CNN-BiLSTM');
grid on;

%% ----------------------------
% Precision-Recall Curves
% ----------------------------
fprintf("Computing Precision-Recall curves...\n");

batchSize = 5000;
numBatches = ceil(numel(X_test_transposed) / batchSize);

scores_LSTM = []; scores_CNNBiLSTM = []; labels_all = [];

for i = 1:numBatches
    idx_start = (i - 1) * batchSize + 1;
    idx_end   = min(i * batchSize, numel(X_test_transposed));
    batch_X   = X_test_transposed(idx_start:idx_end);
    batch_Y   = Y_test_cat(idx_start:idx_end);
    
    [~, scoreLSTM] = classify(netLSTM, batch_X);
    [~, scoreCNN]  = classify(netCNNBiLSTM, batch_X);

    scores_LSTM    = [scores_LSTM; scoreLSTM(:,2)];
    scores_CNNBiLSTM = [scores_CNNBiLSTM; scoreCNN(:,2)];
    labels_all     = [labels_all; categorical(batch_Y(:))];
end

labels_bin = double(labels_all == categorical(1));

[precLSTM, recLSTM, ~, aucLSTM] = perfcurve(labels_bin, scores_LSTM, 1, 'xCrit', 'reca', 'yCrit', 'prec');
[precCNN,  recCNN,  ~, aucCNN]  = perfcurve(labels_bin, scores_CNNBiLSTM, 1, 'xCrit', 'reca', 'yCrit', 'prec');

figure;
plot(recLSTM, precLSTM, 'b-', 'LineWidth', 2); hold on;
plot(recCNN,  precCNN,  'r-', 'LineWidth', 2);
xlabel('Recall'); ylabel('Precision');
title('Precision-Recall Curve - LSTM vs CNN-BiLSTM');
legend(sprintf('LSTM (AUC = %.2f)', aucLSTM), ...
       sprintf('CNN-BiLSTM (AUC = %.2f)', aucCNN), ...
       'Location', 'SouthWest');
grid on;

%% ----------------------------
% F1-Score vs Threshold
% ----------------------------
fprintf("Analyzing F1-score across thresholds...\n");

thresholds = 0:0.01:1;
f1_lstm = zeros(size(thresholds));
f1_cnn  = zeros(size(thresholds));
true_labels = double(labels_all == categorical(1));

for i = 1:length(thresholds)
    % LSTM predictions
    pred_lstm = scores_LSTM >= thresholds(i);
    tp = sum((pred_lstm == 1) & (true_labels == 1));
    fp = sum((pred_lstm == 1) & (true_labels == 0));
    fn = sum((pred_lstm == 0) & (true_labels == 1));
    prec = tp / (tp + fp + eps);
    rec  = tp / (tp + fn + eps);
    f1_lstm(i) = 2 * (prec * rec) / (prec + rec + eps);

    % CNN-BiLSTM predictions
    pred_cnn = scores_CNNBiLSTM >= thresholds(i);
    tp = sum((pred_cnn == 1) & (true_labels == 1));
    fp = sum((pred_cnn == 1) & (true_labels == 0));
    fn = sum((pred_cnn == 0) & (true_labels == 1));
    prec = tp / (tp + fp + eps);
    rec  = tp / (tp + fn + eps);
    f1_cnn(i) = 2 * (prec * rec) / (prec + rec + eps);
end

figure;
plot(thresholds, f1_lstm, 'b-', 'LineWidth', 2); hold on;
plot(thresholds, f1_cnn,  'r-', 'LineWidth', 2);
xlabel('Classification Threshold'); ylabel('F1-Score');
title('F1-Score vs Threshold - LSTM vs CNN-BiLSTM');
legend('LSTM', 'CNN-BiLSTM', 'Location', 'SouthWest');
grid on;

[~, idx_lstm] = max(f1_lstm);
[~, idx_cnn]  = max(f1_cnn);
fprintf("Best F1 (LSTM): %.4f at Threshold = %.2f\n", f1_lstm(idx_lstm), thresholds(idx_lstm));
fprintf("Best F1 (CNN-BiLSTM): %.4f at Threshold = %.2f\n", f1_cnn(idx_cnn), thresholds(idx_cnn));

