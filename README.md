# Multimodal Seizure Prediction Using EEG & EMG - MATLAB Implementation
![IEEE](https://img.shields.io/badge/IEEE-EMBS%20Pune%20Chapter-blue)  
![Platform](https://img.shields.io/badge/Platform-MATLAB%20R2024a-orange)  
![Dataset](https://img.shields.io/badge/Dataset-SeizeIT2-green)  
![License](https://img.shields.io/badge/License-MIT-lightgrey)  

This repository contains the complete MATLAB pipeline for a **multimodal deep learning project** aimed at predicting **non-motor seizures** using EEG and EMG signals.  

- **Dataset:** SeizeIT2  
- **Workflow:** Preprocessing → Segmentation → Deep Learning (LSTM & CNN-BiLSTM) → Evaluation → Statistical Testing  
- **Platform:** MATLAB R2022a+ with required toolboxes
- **Affiliation:** Developed during the **IEEE Engineering in Medicine & Biology Society (EMBS) Pune Chapter Internship**, under mentorship from Prof. Trupti T. Kudale.  

---

## Motivation  

Epileptic seizures are unpredictable and can seriously disrupt the lives of patients and their families. Imagine being at school, work, or even crossing the street and suddenly experiencing a seizure without warning. While EEG (brain activity) is the gold standard for monitoring, it often struggles to detect non-motor seizures, which occur without visible physical signs.  

That’s where **multimodal signals** come in. By combining EEG with EMG (muscle activity), we can capture hidden physiological patterns that a single signal might miss, like subtle muscle responses before a seizure starts.  

This project was developed to explore whether **deep learning** can uncover those early warning patterns. The goal isn’t just improving accuracy numbers in MATLAB, it’s about moving a step closer to systems that could one day give patients a **“seizure forecast,”** helping them live more safely and independently.  

---


## Directory Structure

### Data Files
| File | Description |
|------|-------------|
| `EEG_EMG_Numeric.mat` | Raw numeric EEG and EMG arrays loaded from SeizeIT2 dataset. |
| `EEG_EMG_Preprocessed.mat` | Preprocessed EEG+EMG signals (filtered, normalized). |
| `EEG_EMG_Preprocessed_Segment.mat` | Preprocessed signals segmented into 5-second windows. |
| `EEG_EMG_Segmented.mat` | Initial segmented signals without cleaning. |
| `EEG_EMG_Segmented_Cleaned.mat` | Cleaned segments (artefacts/corrupted samples removed). |
| `EEG_EMG_SplitData.mat` | Final dataset split into Train / Validation / Test sets. |
| `LSTM_TrainedModel_Subset.mat` | Trained LSTM model on a subset (quick validation). |
| `CNN_BiLSTM_TrainedModel_Subset.mat` | Trained CNN+BiLSTM model on a subset. |
| `Model_EvalResults.mat` | Accuracy, precision, recall, and loss values for models. |

### 🔹 MATLAB Code Files
| Script | Description |
|--------|-------------|
| `check_EEG_EMG_file_summary.m` | Displays session info (duration, sampling rate). |
| `Data_Loading_and_Preprocessing.m` | Loads SeizeIT2 files, filters & normalizes EEG/EMG signals. |
| `preprocess_eeg_emg_sessions.m` | Extracts subject sessions & applies preprocessing. |
| `preprocess_signals_for_lstm.m` | Final signal preparation (reshape/transpose) for LSTM input. |
| `EEG_EMG_Preprocessed_Segment.m` | Segments preprocessed data into 5s windows. |
| `extract_features_and_save.m` | Computes optional handcrafted features and saves them. |
| `LSTM_Training_Script.m` | Defines & trains a basic LSTM model. |
| `LSTM_Model_Training.m` | Full LSTM training + evaluation. |
| `CNN.m` | CNN-only baseline model (optional comparison). |
| `CNN_BiLSTM.m` | CNN + BiLSTM with dropout & optimization. |
| `flattenLayer.m` | Custom flatten layer for CNN+LSTM compatibility. |
| `statisticaltests.m` | Mann-Whitney, t-tests, and ANOVA between classes/features. |
| `statisticaltest2.m` | Additional stats (effect size, correlation, etc.). |

---

## Workflow
<p align="center">
  <img src="https://github.com/user-attachments/assets/e7110446-e75e-4018-abdf-2c702d8f8c49" alt="Flowchart" width="500"/>
</p>

1. **Data Preparation**  
   Run:  
   ```matlab
   Data_Loading_and_Preprocessing
   preprocess_eeg_emg_sessions
   ````
   Output → EEG_EMG_Preprocessed.mat
2. **Segmentation**
   Run:  
   ```matlab
   EEG_EMG_Preprocessed_Segment
   ```
   Output → EEG_EMG_Segmented.mat
3. **Cleaning and Split**
   Manually clean if needed → save as EEG_EMG_Segmented_Cleaned.mat
   Run:  
   ```matlab
   preprocess_signals_for_lstm
   ```
   Output → EEG_EMG_SplitData.mat
5. **Model Training**
   Run either:
   ```matlab
   LSTM_Model_Training
   CNN_BiLSTM
   ```
   Models are saved in .mat format.
7. **Evaluation**
   Results saved in Model_EvalResults.mat.
9. **Statistical Analysis**
    ```matlab
    statisticaltests
    statisticaltest2
   ```
    Outputs: Test statistics, p-values, plots

## Models Overview  

| Model                  | Architecture Summary                              | Key Features                          | My results -Performance (Val. Acc.) |
|-------------------------|--------------------------------------------------|---------------------------------------|--------------------------|
| **LSTM (Baseline)**     | 1 × LSTM (100 units) → Dropout → FC → Softmax    | Lightweight, captures temporal patterns | 61.0% |
| **CNN + BiLSTM (v1)**   | Conv1D → BatchNorm → ReLU → MaxPool → BiLSTM    | Learns spatial + temporal features, prone to overfitting | 53.0% |
| **Optimized CNN+BiLSTM**| Smaller Conv kernels → Dropout → BiLSTM + Attention | Stable learning, best balance of performance | **65.9%** |

