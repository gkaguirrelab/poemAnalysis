function [ resultTable, summaryMeasureFieldName ] = surveyAnalysis_age( T )
% function [ processedTable ] = surveyAnalysis_VDS( T )
%
% Details regarding the VDS here
%

subjectIDField={'SubjectID_subjectIDList'};

summaryMeasureFieldName='Age';

YoB='YearOfBirth_';
timestamp='Timestamp';

% Check that we have the right name for the subjectID field
subjectIDIdx=find(strcmp(T.Properties.VariableNames,subjectIDField),1);
if isempty(subjectIDIdx)
    errorText='The hard-coded subjectID field name is not present in this table';
    error(errorText);
end

% Check that we have the year of birth field
tmp=find(strcmp(T.Properties.VariableNames,YoB),1);
if isempty(tmp)
    errorText='The hard-coded Year of birth field name is not present in this table';
    error(errorText);
end

% Check that we have the timestamp field
tmp=find(strcmp(T.Properties.VariableNames,timestamp),1);
if isempty(tmp)
    errorText='The hard-coded timestamp field name is not present in this table';
    error(errorText);
end

% Calculate the difference between YoB and timestamp in years.
age=caldiff([datetime(T.(YoB),1,1),T.(timestamp)]','years')';

% Create a little table with the subject IDs and ages
resultTable=T(:,subjectIDIdx);
resultTable=[resultTable,cell2table(num2cell(age))];
resultTable.Properties.VariableNames{2}=summaryMeasureFieldName;

end

