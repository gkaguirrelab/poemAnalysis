

% Specify the location of the unitTestRawResponses relative to this
% function
functionPath = mfilename('fullpath');
functionPathParts = strsplit(functionPath,filesep);
rawDataPath = fullfile(functionPathParts{1:end-2},'data','unitTestRawResponses.csv');
rawDataPath = [filesep rawDataPath];

% Specify the location of the unitTestDiagnosisTable relative to this
% function
diagnosisPathTable = fullfile(functionPathParts{1:end-2},'data','unitTestDiagnosisTable.csv');
diagnosisPathTable = [filesep diagnosisPathTable];
diagnosisPathMat = fullfile(functionPathParts{1:end-2},'data','unitTestDiagnosisTable.mat');
diagnosisPathMat = [filesep diagnosisPathMat];


% Create diagnosis table from the unit test data
[T, notesText] = poemAnalysis_preProcess(rawDataPath);
diagnosisTable = poemAnalysis_classify( T );

% If the diagnosis table does not exist, then write it. If it does exist,
% load it and compare it to the current output
if exist(diagnosisPathTable,'file')~=2
    save(diagnosisPathMat,'diagnosisTable');
    writetable(diagnosisTable,diagnosisPathTable,'WriteRowNames',true);
else
    % Load the diagnosis table variable and compare
    dataLoad = load(diagnosisPathMat);
    cachedDiagnosisTable = dataLoad.diagnosisTable;
    % Are the cached and current tables identical? Throw an error if not.
    assert(isequaln(cachedDiagnosisTable,diagnosisTable))
end