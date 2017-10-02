
% qualtricsAnalysis_main
%
% This routine loads the .csv files generated by Qualtrics that have the
% results of the migraine diagnostic pathway.
%
%  https://upenn.co1.qualtrics.com/jfe/form/SV_4NQzKbssiT8qqVf
%

%% Housekeeping
clear variables
close all

[~, userName] = system('whoami');
userName = strtrim(userName);
dropboxDir = ...
    fullfile('/Users', userName, '/Dropbox (Aguirre-Brainard Lab)');

%% Set paths to data and output
qualtricsDataDir = '/MELA_analysis/surveyMelanopsinAnalysis/Qualtrics/';
analysisDir = '/MELA_analysis/surveyMelanopsinAnalysis/Qualtrics/';

% Set the output filenames
outputResultExcelName=fullfile(dropboxDir, analysisDir, 'MELA_QualtricsHeadacheResults.xlsx');
rawDataSheets={'POEM_v1.0_10-01-2017_PPIRemoved.csv'};

% get the full path to thisDataSheet
thisDataSheetFileName=fullfile(dropboxDir, qualtricsDataDir, rawDataSheets{1});

%% load and pre-process thisDataSheet, returning table "T"
[T, notesText] = qualtricsAnalysis_preProcess(thisDataSheetFileName);

%% classify headache based upon table T
diagnosisTable = qualtricsAnalysis_classifyHeadache( T );
writetable(diagnosisTable,outputResultExcelName,'Range','A4','WriteRowNames',true)

%% create a confusion matrix

% load the study neurologist diagnoses
goldStandardFile = 'ACHE-M_studyID+diagnosis.csv';
goldStandardFileFullPath = fullfile(dropboxDir, analysisDir, goldStandardFile);
goldStandardDiagnosis = readtable(goldStandardFileFullPath);

% This is the order of columns in the confusion matrix. Note that we are
% not including the Migraine with other aura here.
reOrderedPoemDiagnosisLabels = {'HeadacheFree','MildNonMigrainousHeadache','HeadacheNOS','MigraineWithoutAura','MigraineWithVisualAura'};

confusionMatrix = zeros(3,5);
% loop through the subjects in the diagnosisTable
for ss = 1:size(diagnosisTable,1)
    % get this subject's studyID
    studyID = diagnosisTable.Row{ss};
    % see if there is an entry in the gold standard table
    matchIdx = find(cellfun(@(x) strcmp(studyID,x), goldStandardDiagnosis.SubjectID));
    % assign a confuion matrix row based upon the gold standard diagnosis
    if ~isempty(matchIdx)
        switch goldStandardDiagnosis.Diagnosis{matchIdx}
            case ''
                rowIdx = [];
            case 'Control'
                rowIdx = 1;
            case 'Migraine without aura'
                rowIdx = 2;
            case 'Migraine with aura'
                rowIdx = 3;
            otherwise
                error('I encountered an undefined gold standard diagnosis');
        end
        % Identify which poem diagnosis was assigned to this subject
        initialColumnIdx = find(table2array(diagnosisTable(ss,1:6)),1);
        % Find which column this diagnosis will be placed within
        columnIdx = find( strcmp(reOrderedPoemDiagnosisLabels, diagnosisTable.Properties.VariableNames{initialColumnIdx}) ); 
        if ~isempty(rowIdx)
            confusionMatrix(rowIdx,columnIdx) = confusionMatrix(rowIdx,columnIdx) + 1;
        end
    end
end

% print out the confusion matrix
outline='\t';
for dd = 1:5
    outline = [outline '\t' reOrderedPoemDiagnosisLabels{dd} '\t'];
end
fprintf([outline '\n']);
goldStandardDiagnoses = {'Control\t\t','Migraine without aura','Migraine with aura'};
for rr = 1:3
    outline = [goldStandardDiagnoses{rr} '\t'];
    for cc = 1:5
        outline = [outline num2str(confusionMatrix(rr,cc)) '\t\t'];
    end
fprintf([outline '\n']);
end
