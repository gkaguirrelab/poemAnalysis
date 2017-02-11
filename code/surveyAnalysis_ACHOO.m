function [ resultTable, summaryMeasureFieldName ] = surveyAnalysis_ACHOO( T )
%
% Details regarding this measure here

subjectIDField={'SubjectID_subjectIDList'};

summaryMeasureFieldName='Photic_sneeze';

questions={'x1__DoYouTendToSneezeWhenYouStepOutOfADarkRoomIntoBrightSunligh'};

textResponses={'Yes'};

% This is the offset between the index number of the textResponses
% [1, 2, 3, ...] and the assigned score value (e.g.) [0, 1, 2, ...]
scoreOffset=0;

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

% Convert the text responses to integers. Sadly, this
% has to be done in a loop as Matlah does not have a way to address an
% array of dynamically identified field names of a structure

for qq=1:length(questions)
    T.(questions{qq})=grp2idx(categorical(T.(questions{qq}),textResponses,'Ordinal',true))+scoreOffset;
end

% Calculate the score.
% Sum (instead of nansum) is used so that the presence of any NaN values in
% the responses for a subject result in an undefined total score.
scoreMatrix=table2array(T(:,questionsStartIdx:questionsStartIdx+length(questions)-1));
sumScore=sum(scoreMatrix,2);


% Create a little table with the subject IDs and scores
resultTable=T(:,subjectIDIdx);
resultTable=[resultTable,cell2table(num2cell(sumScore))];
resultTable.Properties.VariableNames{2}=summaryMeasureFieldName;

end

