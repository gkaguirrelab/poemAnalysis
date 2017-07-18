function [diagnosisTable] = qualtricsAnalysis_classifyHeadache( T )
%
% This function takes the table variable "T" and performs a decision tree
% analysis to classify each subject into headache categories.

numSubjects = size(T,1);

diagnoses={'MigraineWithoutAura',...
    'MigraineWithVisualAura',...
    'MigraineWithOtherAura',...
    'HeadacheFree',...
    'HeadacheNOS'};

% Pull the QuestionText out of the table properties
QuestionText=T.Properties.UserData.QuestionText;

% At the outset of processing, all subjects are candidates for all
% diagnoses. We set these flags to true.
MigraineWithoutAuraFlag=true(numSubjects, 1);
MigraineWithVisualAuraFlag=true(numSubjects, 1);
MigraineWithOtherAuraFlag=true(numSubjects, 1);
HeadacheFreeFlag=true(numSubjects, 1);
HeadacheNOSFlag=true(numSubjects, 1);

for thisSubject = 1:numSubjects
    
    %% Migrane without aura
    % There are three sets of criteria that the subject must meet:
    %       1) give a specific set of yes/no responses, including "no" to
    %          questions regarding aura.
    %       2) endorse 2/4 from symptom list 1
    %       3) endorse 1/3 from symptom list 2
    
    % Define the binary questions and the diagnostic responses
    binaryQuestions={'Do you get headaches?',...
        'Do you get headaches that are NOT caused by a head injury, hangover, or an illness such as the cold or the flu?',...
        'Do your headaches ever last more than 4 hours?',...
        'Have you had this headache 5 or more times in your life?',...
        'Have you ever seen any spots, stars, lines, flashing lights, zigzag lines, or ''heat waves'' around the time of your headaches?',...
        'Have you ever had any numbness or tingling of your body or face, weakness on one limb or side of your body or face, difficulty speaking, or a dizzy sensation around the time of your headaches?'};
    diagnosticResponses={'Yes','Yes','Yes','Yes','No','No'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryQuestions);
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
    multiCriterionQuestions={'Do any of the following statements describing your pain and symptoms apply to your headaches that are longer than 4 hours? Please mark all that apply.',...
        'During your headaches that are longer than 4 hours, do you ever experience the following symptoms? Please mark all that apply.'};
    diagnosticNumberNeeded=[2,1];
    availableAnswers(1,:) = {'The pain is worse on one side',...
        'The pain is pounding, pulsating, or throbbing',...
        'The pain has moderate or severe intensity',...
        'The pain is made worse by routine activities such as walking or climbing stairs'};
    availableAnswers(2,:) = {'Nausea or vomiting',...
        'Sensitivity to light',...
        'Sensitivity to noise',''};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, multiCriterionQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), multiCriterionQuestions);
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
    binaryQuestions={'Do you get headaches?',...
        'Do you get headaches that are NOT caused by a head injury, hangover, or an illness such as the cold or the flu?',...
        'Have you ever seen any spots, stars, lines, flashing lights, zigzag lines, or ''heat waves'' around the time of your headaches?',...
        'Have you experienced these visual phenomena with your headaches two or more times in your life?',...
        'How long do these visual phenomena typically last?'};
    diagnosticResponses={'Yes','Yes','Yes','Yes','5 min to 1 hour'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryQuestions);
        % determine if these columns contain the diagnostic responses
        diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
        if sum(diagnosticAnswerTest) == length(diagnosticAnswerTest) && MigraineWithVisualAuraFlag(thisSubject)
            fprintf(['Subject ' num2str(thisSubject) ' met the first criterion for migraine with visual aura!\n']);
        else
            MigraineWithVisualAuraFlag(thisSubject) = false;
        end % binary test
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        MigraineWithVisualAuraFlag(thisSubject) = false;
    end
    
    % Define the necessary and sufficient response in the multiple choice
    % check box button set
    multiCriterionQuestions={'When do you see these visual phenomena in relation to your headache? Please mark all that apply.'};
    diagnosticNumberNeeded=[1];
    diagnosticAnswers(1,:) = {'Before the headache'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, multiCriterionQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), multiCriterionQuestions);
        % Loop through the diagnostic questions
        for qq=1:length(questionColumnIdx)
            % Get the answer string for this question
            answerString = table2cell(T(thisSubject,questionColumnIdx(qq)));
            % Test if the answer string contains enough diagnostic answers
            diagnosticAnswerTest=cellfun(@(x) strfind(answerString, x), diagnosticAnswers(qq,:));
            if sum(cellfun(@(x) ~isempty(x),diagnosticAnswerTest)) >= diagnosticNumberNeeded(qq) && MigraineWithVisualAuraFlag(thisSubject)
                fprintf(['Subject ' num2str(thisSubject) ' met the second criterion for migraine with visual aura!\n']);
            else
                MigraineWithVisualAuraFlag(thisSubject) = false;
            end % symptom inventory test
        end % loop over symptom inventory tests
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        MigraineWithVisualAuraFlag(thisSubject) = false;
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
    binaryQuestions={'Do you get headaches?',...
        'Do you get headaches that are NOT caused by a head injury, hangover, or an illness such as the cold or the flu?',...
        'Have you ever had any numbness or tingling of your body or face, weakness on one limb or side of your body or face, difficulty speaking, or a dizzy sensation around the time of your headaches?',...
        'Have you experienced these phenomena with your headaches two or more times in your life?',...
        'How long do these phenomena typically last?'};
    diagnosticResponses={'Yes','Yes','Yes','Yes','5 min to 1 hour'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryQuestions);
        % determine if these columns contain the diagnostic responses
        diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
        if sum(diagnosticAnswerTest) == length(diagnosticAnswerTest) && MigraineWithOtherAuraFlag(thisSubject)
            fprintf(['Subject ' num2str(thisSubject) ' met the first criterion for migraine with other aura!\n']);
        else
            MigraineWithOtherAuraFlag(thisSubject) = false;
        end % binary test
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        MigraineWithOtherAuraFlag(thisSubject) = false;
    end
    
    % Define the necessary and sufficient response in the multiple choice
    % check box button set
    multiCriterionQuestions={'When do you experience these phenomena in relation to your headache? Please mark all that apply.'};
    diagnosticNumberNeeded=[1];
    diagnosticAnswers(1,:) = {'Before the headache'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, multiCriterionQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), multiCriterionQuestions);
        % Loop through the diagnostic questions
        for qq=1:length(questionColumnIdx)
            % Get the answer string for this question
            answerString = table2cell(T(thisSubject,questionColumnIdx(qq)));
            % Test if the answer string contains enough diagnostic answers
            diagnosticAnswerTest=cellfun(@(x) strfind(answerString, x), diagnosticAnswers(qq,:));
            if sum(cellfun(@(x) ~isempty(x),diagnosticAnswerTest)) >= diagnosticNumberNeeded(qq) && MigraineWithOtherAuraFlag(thisSubject)
                fprintf(['Subject ' num2str(thisSubject) ' met the second criterion for migraine with other aura!\n']);
            else
                MigraineWithOtherAuraFlag(thisSubject) = false;
            end % symptom inventory test
        end % loop over symptom inventory tests
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        MigraineWithOtherAuraFlag(thisSubject) = false;
    end
    
    
    %% Headache free

    % Define the binary questions and the diagnostic response patterns
    binaryCriterionQuestions={'Do you get headaches?',...
        'Do you get headaches that are NOT caused by a head injury, hangover, or an illness such as the cold or the flu?',...
        'Have you ever had a headache?',...
        'Have you ever had a headache that was NOT caused by a head injury, hangover, or an illness such as the cold or the flu?',...
        'Have you ever had episodes of discomfort, pressure, or pain around your eyes or sinuses?'};
    diagnosticResponses(1,:) = {'No','' ,'No','' ,'No'};
    diagnosticResponses(2,:) = {'No','' ,'Yes','No','No'};
    diagnosticResponses(3,:) = {'Yes','No','', '' ,'No'};
    
    % Test if there is a column in the table for each question
    % KNOWN BUG - If no subjects have followed a path resulting in
    % responses in one or more of the criterion questions, then the test
    % for headache free status will be skipped for every subject!
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryCriterionQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        % test these columns for each of the diagnostic response patterns
        for ii = 1:size(diagnosticResponses,1)
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses(ii,:));
            sumDiagnosticAnswerTest(ii)=sum(diagnosticAnswerTest);
        end
        % If any of the patterns were found to match, then give this
        % diagnosis
        if any(sumDiagnosticAnswerTest == length(diagnosticAnswerTest)) && HeadacheFreeFlag(thisSubject)
            fprintf(['Subject ' num2str(thisSubject) ' met the criterion for headache free!\n']);
        else
            HeadacheFreeFlag(thisSubject) = false;
        end % binary test
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        HeadacheFreeFlag(thisSubject) = false;
    end
    
    
    %% HeadacheNOS
    % If a subject does not fall into any other diagnostic category, then
    % we label them HeadacheNOS
    HeadacheNOSFlag(thisSubject) = ~any( [ MigraineWithoutAuraFlag(thisSubject) ...
        MigraineWithVisualAuraFlag(thisSubject) ...
        MigraineWithOtherAuraFlag(thisSubject) ...
        HeadacheFreeFlag(thisSubject) ] );
    
    
end % loop over subjects

% Assemble diagnosisTable
diagnosisTable=table(MigraineWithoutAuraFlag,MigraineWithVisualAuraFlag,MigraineWithOtherAuraFlag,HeadacheFreeFlag,HeadacheNOSFlag);
diagnosisTable.Properties.VariableNames=diagnoses;
diagnosisTable.Properties.RowNames=T.Properties.RowNames;


end % function



