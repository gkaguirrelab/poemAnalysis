
% surveyAnalysis_main
%
% This routine loads the set of Excel files that contain the output of the
% Google Sheet demographic and survey information. The routine matches
% subject IDs across the instruments, and saves the entire set into sheets
% of an Excel fil.


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

% Can't analyze this one yet, because there is an index value that extends
% above the first row of column labels.
%    'MELA Vision Test Performance v1.0 Queried.xlsx',...

spreadSheetSet={'MELA Visual and Seasonal Sensitivity v1.1 (Responses) Queried.xlsx',...
    'MELA Substance and Medicine Questionnaire v1.0 (Responses) Queried.xlsx',...
    'MELA Sleep Quality Questionnaire v1.0 (Responses) Queried.xlsx',...
    'MELA Screening v1.1 (Responses) Queried.xlsx',...
    'MELA Demographics Form v1.0 (Responses) Queried.xlsx',...
    'MELA Chronotype Questionnaire v1.0 (Responses) Queried.xlsx',...
    'MELA AMPP Headache Survey v1.0 (Responses) Queried.xlsx'};

% Run through once to compile the subjectIDList
for i=1:length(spreadSheetSet)
    spreadSheetName=fullfile(dropboxDir, surveyDir, spreadSheetSet{i});
    T = makeSpreadSheetTable(spreadSheetName);
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

% Set the output filename
outputExcelName=fullfile(dropboxDir, analysisDir, 'MELA_compiledSurveyData.xlsx');

% Run through again and save the compiled spreadsheet
for i=1:length(spreadSheetSet)
    spreadSheetName=fullfile(dropboxDir, surveyDir, spreadSheetSet{i});
    [T, notesText] = makeSpreadSheetTable(spreadSheetName);
    % Set each table to have the same subjectID list
    T = outerjoin(subjectIDList,T);
    % Write the table data
    writetable(T,outputExcelName,'Range','A4','WriteRowNames',true,'Sheet',i)
    % Put the name of this spreadsheet at the top of the sheet
    writetable(cell2table(spreadSheetSet(i)),outputExcelName,'WriteVariableNames',false,'Range','A1','Sheet',i)
    % If there is noteText, write this to the table and add a warning
    if length(notesText) > 1
        writetable(cell2table(cellstr('CONVERSION WARNINGS: check bottom of sheet')),outputExcelName,'WriteVariableNames',false,'Range','A2','Sheet',i)
        cornerRange=['A' strtrim(num2str(size(T,1)+7))];
        writetable(cell2table(notesText),outputExcelName,'WriteVariableNames',false,'Range',cornerRange,'Sheet',i)
    end
end

% restore warning state
warning(orig_state);

