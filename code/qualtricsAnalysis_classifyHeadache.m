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

% At the outset of processing, all subjects are candidates for all
% diagnoses. We set these flags to true.
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
    %       2) endorse 2/4 from symptom list 1
    %       3) endorse 1/3 from symptom list 2
    
    % Define the binary questions and the diagnostic responses
    binaryQuestions={'Q1','Q3','Q4','Q7','Q8','Q23'};
    diagnosticResponses={'Yes','Yes','Yes','Yes','No','No'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(T.Properties.VariableNames,x))==1, binaryQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(T.Properties.VariableNames,x)), binaryQuestions);
        % determine if these columns contain the diagnostic responses
        diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
        if sum(diagnosticAnswerTest) == length(diagnosticAnswerTest) && MigraineWithoutAuraFlag(thisSubject)
            fprintf(['Subject ' num2str(thisSubject) ' met the first criterion for migraine without aura!\n']);
        else
            MigraineWithoutAuraFlag(thisSubject) = false;
        end % binary test
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        MigraineWithoutAuraFlag(thisSubject) = false;
    end
    
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
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(T.Properties.VariableNames,x))==1, multiCriterionQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
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
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        MigraineWithoutAuraFlag(thisSubject) = false;
    end
    
    %% Migraine with visual aura
    % The criteria that the subject must meet:
    %       1) give a specific set of yes/no responses, including:
    %           - yes to headache questions (Q1, Q3)
    %           - yes to question regarding visual aura (Q8); Q23 is ignored
    %           - yes to having more than 2 lifetime visual aura events (Q22)
    %       2) multiple choice checkbox with one necessary and sufficient
    %          diagnostic answer: endorse having aura before headache (Q9)
    %       3) multiple choice radio button, with one diagnostic answer:
    %          report aura duration between 5 and 60 min (Q19). This can be
    %          treated as a binary question in the program logic.
    
    % Define the binary questions and the diagnostic responses
    binaryQuestions={'Q1','Q3','Q8','Q22','Q19'};
    diagnosticResponses={'Yes','Yes','Yes','Yes','5 min to 1 hour'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(T.Properties.VariableNames,x))==1, binaryQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(T.Properties.VariableNames,x)), binaryQuestions);
        % determine if these columns contain the diagnostic responses
        diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
        if sum(diagnosticAnswerTest) == length(diagnosticAnswerTest) && MigraineWithVisualAura(thisSubject)
            fprintf(['Subject ' num2str(thisSubject) ' met the first criterion for migraine with visual aura!\n']);
        else
            MigraineWithVisualAura(thisSubject) = false;
        end % binary test
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        MigraineWithVisualAura(thisSubject) = false;
    end
    
    % Define the necessary and sufficient response in the multiple choice
    % check box button set
    multiCriterionQuestions={'Q9'};
    diagnosticNumberNeeded=[1];
    diagnosticAnswers(1,:) = {'Before the headache'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(T.Properties.VariableNames,x))==1, multiCriterionQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(T.Properties.VariableNames,x)), multiCriterionQuestions);
        % Loop through the diagnostic questions
        for qq=1:length(questionColumnIdx)
            % Get the answer string for this question
            answerString = table2cell(T(thisSubject,questionColumnIdx(qq)));
            % Test if the answer string contains enough diagnostic answers
            diagnosticAnswerTest=cellfun(@(x) strfind(answerString, x), diagnosticAnswers(qq,:));
            if sum(cellfun(@(x) ~isempty(x),diagnosticAnswerTest)) >= diagnosticNumberNeeded(qq) && MigraineWithVisualAura(thisSubject)
                fprintf(['Subject ' num2str(thisSubject) ' met the second criterion for migraine with visual aura!\n']);
            else
                MigraineWithVisualAura(thisSubject) = false;
            end % symptom inventory test
        end % loop over symptom inventory tests
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        MigraineWithVisualAura(thisSubject) = false;
    end
    
    %% Migraine with other aura
    % The criteria that the subject must meet:
    %       1) give a specific set of yes/no responses, including:
    %           - yes to headache questions (Q1, Q3)
    %           - yes to question regarding other aura (Q23); Q8 is ignored
    %           - yes to having more than 2 lifetime other aura events (Q24)
    %       2) multiple choice checkbox with one necessary and sufficient
    %          diagnostic answer: endorse having aura before headache (Q25)
    %       3) multiple choice radio button, with one diagnostic answer:
    %          report aura duration between 5 and 60 min (Q26). This can be
    %          treated as a binary question in the program logic.
    
    % Define the binary questions and the diagnostic responses
    binaryQuestions={'Q1','Q3','Q23','Q24','Q26'};
    diagnosticResponses={'Yes','Yes','Yes','Yes','5 min to 1 hour'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(T.Properties.VariableNames,x))==1, binaryQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(T.Properties.VariableNames,x)), binaryQuestions);
        % determine if these columns contain the diagnostic responses
        diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
        if sum(diagnosticAnswerTest) == length(diagnosticAnswerTest) && MigraineWithOtherAura(thisSubject)
            fprintf(['Subject ' num2str(thisSubject) ' met the first criterion for migraine with other aura!\n']);
        else
            MigraineWithOtherAura(thisSubject) = false;
        end % binary test
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        MigraineWithOtherAura(thisSubject) = false;
    end
    
    % Define the necessary and sufficient response in the multiple choice
    % check box button set
    multiCriterionQuestions={'Q26'};
    diagnosticNumberNeeded=[1];
    diagnosticAnswers(1,:) = {'Before the headache'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(T.Properties.VariableNames,x))==1, multiCriterionQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(T.Properties.VariableNames,x)), multiCriterionQuestions);
        % Loop through the diagnostic questions
        for qq=1:length(questionColumnIdx)
            % Get the answer string for this question
            answerString = table2cell(T(thisSubject,questionColumnIdx(qq)));
            % Test if the answer string contains enough diagnostic answers
            diagnosticAnswerTest=cellfun(@(x) strfind(answerString, x), diagnosticAnswers(qq,:));
            if sum(cellfun(@(x) ~isempty(x),diagnosticAnswerTest)) >= diagnosticNumberNeeded(qq) && MigraineWithOtherAura(thisSubject)
                fprintf(['Subject ' num2str(thisSubject) ' met the second criterion for migraine with other aura!\n']);
            else
                MigraineWithOtherAura(thisSubject) = false;
            end % symptom inventory test
        end % loop over symptom inventory tests
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        MigraineWithOtherAura(thisSubject) = false;
    end
    
end % loop over subjects

% Assemble diagnosisTable
diagnosisTable=table(MigraineWithoutAuraFlag,MigraineWithVisualAura,MigraineWithOtherAura,HeadacheNOS,HeadacheFree);
diagnosisTable.Properties.VariableNames=diagnoses;

end % function



