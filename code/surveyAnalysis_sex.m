function [ scoreTable, summaryMeasureFieldName ] = surveyAnalysis_sex( T )
%
% Details regarding this measure here

subjectIDField={'SubjectID_subjectIDList'};

summaryMeasureFieldName='Sex';

questions={'Gender_'};

textResponses={'Male',...
'Female',...
'Do Not Wish to Say'};

% Loop through the questions and build the list of indices
for qq=1:length(questions)
    questionIdx=find(strcmp(T.Properties.VariableNames,questions{qq}),1);
    if isempty(questionIdx)
        errorText='The list of hard-coded column headings does not match the headings in the passed table';
        error(errorText);
    else
        questionIndices(qq)=questionIdx;
    end % failed to find a question header
end % loop over questions

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
scoreTable=T(:,subjectIDIdx);
scoreTable=[scoreTable,T(:,questionIndices)];
scoreTable.Properties.VariableNames{2}=summaryMeasureFieldName;

end

