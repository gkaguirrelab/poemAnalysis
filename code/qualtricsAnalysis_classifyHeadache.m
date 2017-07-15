function [diagnosisTable] = qualtricsAnalysis_classifyHeadache( T )
%
% This function takes the table variable "T" and performs a decision tree
% analysis to classify each subject into headache categories.

numSubjects = size(T,1);

diagnoses={'MigraineWithoutAura',...
    'MigraineWithVisualAura',...
    'MigraineWithOtherAura',...
    'HeadacheNOS',...
    'HeadacheFree'};

MigraineWithoutAuraFlag=true(numSubjects, 1);
MigraineWithVisualAura=true(numSubjects, 1);
MigraineWithOtherAura=true(numSubjects, 1);
HeadacheNOS=true(numSubjects, 1);
HeadacheFree=true(numSubjects, 1);

for thisSubject = 1:numSubjects
    
    %% Migrane without aura
    % There are three sets of criteria that the subject must meet:
    %       1) give a specific set of yes/no responses, including "no" to
    %          questions regarding aura.
    %       2) endorse 3/4 from symptom list 1
    %       3) endorse 1/3 from symptom list 2
    
    % Define the binary questions and the diagnostic responses --  NOTE the diagnostic response for Q8 should be "no". Set to yes for testing purposes at the moment
    binaryQuestions={'Q1','Q3','Q4','Q7','Q8','Q23'};
    diagnosticResponses={'Yes','Yes','Yes','Yes','Yes','No'};
    
    % identify which columns of the table contain the relevant questions
    questionColumnIdx = cellfun(@(x) find(strcmp(T.Properties.VariableNames,x)), binaryQuestions);
    
    % determine if these columns contain the diagnostic responses
    diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
    if sum(diagnosticAnswerTest) == length(diagnosticAnswerTest) && MigraineWithoutAuraFlag(thisSubject)
        fprintf(['Subject ' num2str(thisSubject) ' met the first criterion for migraine without aura!\n']);
    else
        MigraineWithoutAuraFlag(thisSubject) = false;
    end % binary test
    
    % Define the symptom inventory questions and diagnostic responses
    multiCriterionQuestions={'Q5','Q6'};
    diagnosticNumberNeeded=[2,1];    
    availableAnswers(1,:) = {'The pain is worse on one side',...
        'The pain is pounding, pulsating, or throbbing',...
        'The pain has moderate or severe intensity',...
        'The pain is made worse by routine activities such as walking or climbing stairs'};    
    availableAnswers(2,:) = {'Nausea or vomiting',...
        'Sensitivity to light',...
        'Sensitivity to noise',''};
    
    % Find the columns that contain the diagnostic questions
    questionColumnIdx = cellfun(@(x) find(strcmp(T.Properties.VariableNames,x)), multiCriterionQuestions);
    
    % Loop through the diagnostic questions
    for qq=1:length(questionColumnIdx)
        
        % Get the answer string for this question
        answerString = table2cell(T(thisSubject,questionColumnIdx(qq)));
        % Test if the answer string contains enough diagnostic answers
        diagnosticAnswerTest=cellfun(@(x) strfind(answerString, x), availableAnswers(qq,:));
        if sum(cellfun(@(x) ~isempty(x),diagnosticAnswerTest)) >= diagnosticNumberNeeded(qq) && MigraineWithoutAuraFlag(thisSubject)
            fprintf(['Subject ' num2str(thisSubject) ' met the second criterion for migraine without aura!\n']);
        else
            MigraineWithoutAuraFlag(thisSubject) = false;
        end % symptom inventory test
    end % loop over symptom inventory tests


    %% Migrane with aura
    % Details here


end % loop over subjects

% Assemble diagnosisTable
diagnosisTable=table(MigraineWithoutAuraFlag,MigraineWithVisualAura,MigraineWithOtherAura,HeadacheNOS,HeadacheFree);
diagnosisTable.Properties.VariableNames=diagnoses;

end % function



