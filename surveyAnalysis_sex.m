function [ resultTable, summaryMeasureFieldName ] = surveyAnalysis_sex( T )
%
% Details regarding this measure here

subjectIDField={'SubjectID_subjectIDList'};

summaryMeasureFieldName='Sex';

questions={'Gender_'};

textResponses={'Male',...
'Female',...
'Do Not Wish to Say'};

% Check that the column headings match the list of questions
questionsStartIdx=find(strcmp(T.Properties.VariableNames,questions{1}));
if ~isempty(questionsStartIdx)
    if ~isequal(T.Properties.VariableNames(questionsStartIdx:questionsStartIdx+length(questions)-1),questions)
    errorText='The list of hard-coded column headings does not match the headings in the passed table';
    error(errorText);
    end
else
    errorText='The list of hard-coded column headings does not match the headings in the passed table';
    error(errorText);
end

% Check that we have the right name for the subjectID field
subjectIDIdx=find(strcmp(T.Properties.VariableNames,subjectIDField),1);
if isempty(subjectIDIdx)
    errorText='The hard-coded subjectID field name is not present in this table';
    error(errorText);
end

% Convert the text responses categories
for qq=1:length(questions)
    T.(questions{qq})=categorical(T.(questions{qq}),textResponses,'Ordinal',false);
end

% Create a little table with the subject IDs and scores
resultTable=T(:,subjectIDIdx);
resultTable=[resultTable,T(:,questionsStartIdx:questionsStartIdx+length(questions)-1)];
resultTable.Properties.VariableNames{2}=summaryMeasureFieldName;

end

