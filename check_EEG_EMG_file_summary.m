baseFolder = "C:\Users\User\OneDrive - Politechnika Śląska\Semester 6\IEEE internship\EEG_EMG";
subList = sprintfc('sub-%03d', 1:125);  % Generate sub-001 to sub-125

results = table('Size', [125 6], ...
    'VariableTypes', {'string', 'logical', 'logical', 'double', 'double', 'double'}, ...
    'VariableNames', {'Subject', 'HasEEG', 'HasEMG', 'JSON_Count', 'TSV_Count', 'EDF_Count'});

for i = 1:numel(subList)
    subName = subList{i};
    subPath = fullfile(baseFolder, subName);
    eegPath = fullfile(subPath, 'eeg');
    emgPath = fullfile(subPath, 'emg');

    % Initialize counters
    jsonCount = 0;
    tsvCount = 0;
    edfCount = 0;

    % Count files if EEG folder exists
    if isfolder(eegPath)
        eegFiles = dir(fullfile(eegPath, '*'));
        jsonCount = jsonCount + sum(endsWith({eegFiles.name}, '.json'));
        tsvCount = jsonCount + sum(endsWith({eegFiles.name}, '.tsv'));
        edfCount = edfCount + sum(endsWith({eegFiles.name}, '.edf'));
    end

    % Count files if EMG folder exists
    if isfolder(emgPath)
        emgFiles = dir(fullfile(emgPath, '*'));
        jsonCount = jsonCount + sum(endsWith({emgFiles.name}, '.json'));
        tsvCount = tsvCount + sum(endsWith({emgFiles.name}, '.tsv'));
        edfCount = edfCount + sum(endsWith({emgFiles.name}, '.edf'));
    end

    % Fill the results table
    results.Subject(i) = subName;
    results.HasEEG(i) = isfolder(eegPath);
    results.HasEMG(i) = isfolder(emgPath);
    results.JSON_Count(i) = jsonCount;
    results.TSV_Count(i) = tsvCount;
    results.EDF_Count(i) = edfCount;
end

disp(results);

%%
% --- Subsection: Print subject names with at least one missing file type ---
incompleteIdx = results.JSON_Count == 0 & results.TSV_Count == 0 & results.EDF_Count == 0;
incompleteSubjects = results.Subject(incompleteIdx);

if ~isempty(incompleteSubjects)
    fprintf('\nSubjects with at least one missing file type (JSON, TSV, or EDF):\n');
    disp(incompleteSubjects)
else
    fprintf('\n✅ All subjects have all three file types.\n');
end
