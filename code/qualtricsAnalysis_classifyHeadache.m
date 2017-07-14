function qualtricsAnalysis_classifyHeadache( T )
%
% This function takes the table variable "T" and performs a decision tree
% analysis to classify each subject into headache categories.

numSubjects = size(T,1);

% Test for migraine without aura

for thisSubject = 1:numSubjects
    
    binaryQuestions={'Q1','Q3','Q4','Q7','Q8','Q23'};
    
    %% NOTE the diagnostic response for Q8 should be "no". Set to yes for testing purposes at the moment
    diagnosticResponses={'Yes','Yes','Yes','Yes','Yes','No'};
    
    questionColumnIdx = cellfun(@(x) find(strcmp(T.Properties.VariableNames,x)), binaryQuestions);
    
    diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
    
    if sum(diagnosticAnswerTest) == length(diagnosticAnswerTest)
        fprintf(['Subject ' num2str(thisSubject) ' met the first criterion for migraine without aura!\n']);
    end % test for migraine
    
    multiCriterionQuestions={'Q5','Q6'};
    diagnosticNumberNeeded=[2,1];

    availableAnswers(1,:) = {'The pain is worse on one side',...
        'The pain is pounding, pulsating, or throbbing',...
        'The pain has moderate or severe intensity',...
        'The pain is made worse by routine activities such as walking or climbing stairs'};
    
    availableAnswers(2,:) = {'Nausea or vomiting',...
        'Sensitivity to light',...
        'Sensitivity to noise',''};
    
    questionColumnIdx = cellfun(@(x) find(strcmp(T.Properties.VariableNames,x)), multiCriterionQuestions);

    qq=1;
    
    answerString = table2cell(T(thisSubject,questionColumnIdx(qq)));
    diagnosticAnswerTest=cellfun(@(x) strfind(answerString, x), availableAnswers(qq,:));
    if sum(~isempty(diagnosticAnswerTest)) >= diagnosticNumberNeeded(qq)
        fprintf(['Subject ' num2str(thisSubject) ' met the second criterion for migraine without aura!\n']);
    end % test if criterion was met

    
    
end % loop over subjects

end % function


%
% subjectIDField={'SubjectID_subjectIDList'};
%
% summaryMeasureFieldName='Sex';
%
% questions={'Gender_'};
%
% textResponses={'Male',...
% 'Female',...
% 'Do Not Wish to Say'};
%
% % Loop through the questions and build the list of indices
% for qq=1:length(questions)
%     questionIdx=find(strcmp(T.Properties.VariableNames,questions{qq}),1);
%     if isempty(questionIdx)
%         errorText='The list of hard-coded column headings does not match the headings in the passed table';
%         error(errorText);
%     else
%         questionIndices(qq)=questionIdx;
%     end % failed to find a question header
% end % loop over questions
%
% % Check that we have the right name for the subjectID field
% subjectIDIdx=find(strcmp(T.Properties.VariableNames,subjectIDField),1);
% if isempty(subjectIDIdx)
%     errorText='The hard-coded subjectID field name is not present in this table';
%     error(errorText);
% end
%
% % Convert the text responses categories
% for qq=1:length(questions)
%     T.(questions{qq})=categorical(T.(questions{qq}),textResponses,'Ordinal',false);
% end
%
% % Create a little table with the subject IDs and scores
% scoreTable=T(:,subjectIDIdx);
% scoreTable=[scoreTable,T(:,questionIndices)];
% scoreTable.Properties.VariableNames{2}=summaryMeasureFieldName;

