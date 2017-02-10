
% surveyAnalysis_main
%
% This routine loads the set of Excel files that contain the output of the
% Google Sheet demographic and survey information. The routine matches
% subject IDs across the instruments, and saves the entire set into sheets
% of an Excel file.


%% Housekeeping
clear all
close all

[~, userName] = system('whoami');
userName = strtrim(userName);
dropboxDir = ...
    fullfile('/Users', userName, '/Dropbox (Aguirre-Brainard Lab)');

%% Set paths to surveys and output
surveyDir = '/MELA_subject/Google_Doc_Sheets/';
analysisDir = '/MELA_analysis/surveyMelanopsinAnalysis/';

% Set the output filenames
outputRawExcelName=fullfile(dropboxDir, analysisDir, 'MELA_compiledRawSurveyData.xlsx');
outputResultExcelName=fullfile(dropboxDir, analysisDir, 'MELA_compiledResultSurveyData.xlsx');

spreadSheetSet={'MELA Demographics Form v1.0 (Responses) Queried.xlsx',...
    'MELA Screening v1.1 (Responses) Queried.xlsx',...
    'MELA Vision Test Performance v1.0 Queried.xlsx',...
    'MELA Visual and Seasonal Sensitivity v1.1 (Responses) Queried.xlsx',...
    'MELA Substance and Medicine Questionnaire v1.0 (Responses) Queried.xlsx',...
    'MELA Sleep Quality Questionnaire v1.0 (Responses) Queried.xlsx',...
    'MELA Chronotype Questionnaire v1.0 (Responses) Queried.xlsx',...
    'MELA AMPP Headache Survey v1.0 (Responses) Queried.xlsx'};


%% PROCESS

% Run through once to compile the subjectIDList
for i=1:length(spreadSheetSet)
    spreadSheetName=fullfile(dropboxDir, surveyDir, spreadSheetSet{i});
    T = surveyAnalysis_preProcess(spreadSheetName);
    if i==1
        subjectIDList=cell2table(T.SubjectID);
    else
        subjectIDList=outerjoin(subjectIDList,cell2table(T.SubjectID(:)));
        tmpFill=fillmissing(table2cell(subjectIDList),'nearest',2);
        subjectIDList=cell2table(tmpFill(:,1));
    end
end
subjectIDList.Properties.VariableNames{1}='SubjectID';

% Turn off warnings about adding a sheet to the Excel file
warnID='MATLAB:xlswrite:AddSheet';
orig_state = warning;
warning('off',warnID);

% Run through again and save the compiled spreadsheet
for i=1:length(spreadSheetSet)
    spreadSheetName=fullfile(dropboxDir, surveyDir, spreadSheetSet{i});
    [T, notesText] = surveyAnalysis_preProcess(spreadSheetName);
    % Set each table to have the same subjectID list
    T = outerjoin(subjectIDList,T);
    % Write the table data
    writetable(T,outputRawExcelName,'Range','A4','WriteRowNames',true,'Sheet',i)
    % Put the name of this spreadsheet at the top of the sheet
    writetable(cell2table(spreadSheetSet(i)),outputRawExcelName,'WriteVariableNames',false,'Range','A1','Sheet',i)
    % If there is noteText, write this to the table and add a warning
    if length(notesText) > 1
        writetable(cell2table(cellstr('CONVERSION WARNINGS: check bottom of sheet')),outputRawExcelName,'WriteVariableNames',false,'Range','A2','Sheet',i)
        cornerRange=['A' strtrim(num2str(size(T,1)+7))];
        writetable(cell2table(notesText),outputRawExcelName,'WriteVariableNames',false,'Range',cornerRange,'Sheet',i)
    end
    % Save the table into a a structure with an informative field name
    tmp=strsplit(spreadSheetSet{i},' ');
    fieldName=strjoin(tmp(2:4),'_');
    fieldName=strrep(fieldName, '.', '_');
    fieldName=strrep(fieldName, '(', '_');
    fieldName=strrep(fieldName, ')', '_');
    tableFieldNames{i}=fieldName;
    compiledTable.(tableFieldNames{i})=T;
end

% restore warning state
warning(orig_state);

% Create a result table
[tmpTable]=surveyAnalysis_age(compiledTable.(tableFieldNames{1}));
resultTable=tmpTable;

[tmpTable] = surveyAnalysis_sex( compiledTable.(tableFieldNames{1}) );
resultTable=innerjoin(resultTable,tmpTable);

[tmpTable] = surveyAnalysis_ACHOO( compiledTable.(tableFieldNames{4}) );
resultTable=innerjoin(resultTable,tmpTable);

[tmpTable] = surveyAnalysis_conlon_VDS( compiledTable.(tableFieldNames{4}) );
resultTable=innerjoin(resultTable,tmpTable);

[tmpTable] = surveyAnalysis_choi_phobia( compiledTable.(tableFieldNames{4}) );
resultTable=innerjoin(resultTable,tmpTable);

[tmpTable] = surveyAnalysis_hogan_phobia( compiledTable.(tableFieldNames{4}) );
resultTable=innerjoin(resultTable,tmpTable);

[tmpTable] = surveyAnalysis_PAQ_phobia( compiledTable.(tableFieldNames{4}) );
resultTable=innerjoin(resultTable,tmpTable);

[tmpTable] = surveyAnalysis_PAQ_philia( compiledTable.(tableFieldNames{4}) );
resultTable=innerjoin(resultTable,tmpTable);


% Write the resultTable along with some notes.
notesText=cell(1,1);
notesText{1}='MELA survey analysis';
notesText{2}=['Analysis timestamp: ' datestr(datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss'))];
notesText{3}=['User: ' userName];

%% NEED TO ADD A CALL TO GetGITInfo with MRKLAR toolbox to add github version

writetable(resultTable,outputResultExcelName,'Range','A4','WriteRowNames',true,'Sheet',1)
cornerRange=['A' strtrim(num2str(size(resultTable,1)+7))];
writetable(cell2table(notesText'),outputResultExcelName,'WriteVariableNames',false,'Range',cornerRange,'Sheet',1)
