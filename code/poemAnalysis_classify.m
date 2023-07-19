function [diagnosisTable] = poemAnalysis_classify( T )
% Classify survey responses into headache diagnostic categories
%
% Syntax:
%  diagnosisTable = poemAnalysis_classify(T);
%
% Description:
%   This function takes the table variable "T" and performs a decision tree
%   analysis to classify each subject into headache categories.
%

numSubjects = size(T,1);

verbose = false;

diagnoses={'HeadacheFree',...
    'MildNonMigrainousHeadache',...
    'HeadacheNOS',...
    'MigraineWithoutAura',...
    'MigraineWithVisualAura',...
    'MigraineWithOtherAura',...
    'ChoiIctalPhotophobiaScore',...
    'InterictalPhotophobia',...
    'IctalAllodyniaScore',...
    'InterictalAllodynia',...
    'LightSensitiveEyes',...
    'ChildhoodMotionSickness',...
    'FamHxOfHeadache',...
    'Ophthalmology',...
    'FrequencyMonthly',...
    'RecencyMigraine',...
    'RecencyAnyAura',...
    'SincerityQuestion',...
    'FutureContact'};

% Pull the QuestionText out of the table properties (Important: Code assumes all POEM questions are unique, in order to work properly (e.g. when finding column ids))
QuestionText=T.Properties.UserData.QuestionText;

% At the outset of processing, all subjects are candidates for all
% diagnoses. We set these flags to true.
HeadacheFreeFlag=true(numSubjects, 1);
MildNonMigrainousHeadacheFlag=true(numSubjects, 1);
HeadacheNOSFlag=true(numSubjects, 1);
MigraineWithoutAuraFlag=true(numSubjects, 1);
MigraineWithVisualAuraFlag=true(numSubjects, 1);
MigraineWithOtherAuraFlag=true(numSubjects, 1);
% The Choi questions are a score; default to nan
ChoiIctalPhotophobiaScore=nan(numSubjects, 1);
% A variable to hold the response to this question from Choi
InterictalPhotophobia=false(numSubjects, 1);
% The ASC-12 questions are a score; default to nan
IctalAllodyniaScore=nan(numSubjects, 1);
% A variable to hold the response to this question from ASC-12
InterictalAllodynia=false(numSubjects, 1);
% A variable to hold if at least one kind of aura is recent
RecencyAnyAura = false(numSubjects, 1);
% These next set of data columns contain the strings copied over from the
% answer text, and default to empty.
LightSensitiveEyes = cell(numSubjects, 1);
ChildhoodMotionSickness = cell(numSubjects, 1);
FamHxOfHeadache = cell(numSubjects, 1);
Ophthalmology = cell(numSubjects, 1);
FrequencyMonthly = cell(numSubjects, 1);
RecencyMigraine = cell(numSubjects, 1);
SincerityQuestion = cell(numSubjects, 1);
FutureContact = cell(numSubjects, 1);

% At least 3 of multiple characteristics must be met in order to qualify as
% migraine with a type of aura
minRequirement = 3;

for thisSubject = 1:numSubjects
    
    
    %% Migraine with visual aura
    % The criteria that the subject must meet:
    %       1) give a specific set of yes/no responses, including:
    %           - yes to headache questions (Q1 or Q39 or Q41) (Q3)
    %           - yes to question regarding visual aura (Q8); Q23 is ignored
    %           - yes to having more than 2 lifetime visual aura events (Q22)
    %           - yes to aura symptom spreading over >= 5 minutes (Q82)
    %           - yes to aura symptom lasting 5-60 mins (Q70)
    %           - yes to aura symptom being unilateral (Q81)
    %           - yes to two or more aura symptoms occuring in succession (Q148)
    %       2) multiple choice checkbox with one necessary and sufficient
    %          diagnostic answer: endorse having aura before/during headache (Q9)
    %       3) multiple choice radio button, with one diagnostic answer:
    %          report aura duration between 5 and 60 min (Q19).
    
    % Define the binary questions and the diagnostic responses
    binaryQuestions={'Do you get headaches?',...
        'Have you ever had a headache?',...
        'Have you ever had episodes of discomfort, pressure, or pain around your eyes or face?',...
        'Do you get headaches or episodes of eye or face discomfort that are NOT caused by a head injury, hangover, or illness such as the cold or the flu?',...
        'Have you had these vision changes with your headaches or discomfort episodes two or more times in your life?'};
    clear diagnosticResponses;
    %For this section, binaryQuestions correspond to diagnosticResponses' columns (not rows)
    diagnosticResponses(1,:)={'Yes','','','Yes','Yes'};
    diagnosticResponses(2,:)={'No','Yes','','Yes','Yes'};
    diagnosticResponses(3,:)={'No','No','Yes','Yes','Yes'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryQuestions);
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExist)
        clear sumDiagnosticAnswerTest;
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryQuestions);
        % test these columns for each of the diagnostic response patterns
        for ii = 1:size(diagnosticResponses,1)
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses(ii,:));
            sumDiagnosticAnswerTest(ii)=sum(diagnosticAnswerTest);
        end
        % If any of the patterns were found to match, then give this diagnosis
        if any(sumDiagnosticAnswerTest == length(diagnosticAnswerTest)) && MigraineWithVisualAuraFlag(thisSubject)
            if verbose
                fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' met the first criterion for migraine with visual aura!\n']);
            end
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
    % At least three (minRequirement) of the following characteristics must be met
    multiCriterionQuestions={'Do the vision changes spread or move across your vision?',...
        'How long do these vision changes usually last?',...
        'Do these vision changes ever last 5-60 minutes?',...
        'Are the vision changes only on one side?',...
        'Around the time of your headaches or discomfort episodes, have you ever seen any of the following? (check all that apply)',...
        'When do you see these visual phenomena in relation to your headaches or discomfort episodes? Please check all that apply.',...
        'Do changes in vision, numbness/tingling, and or difficulty speaking happen at the same time?'};
    counter = 0;
    % For this section, multiCriterionQuestions(1:3) correspond to diagnosticResponses' columns (not rows)
    clear diagnosticResponses;
    diagnosticResponses(1,:) = {'Yes','Less than 5 min','Yes'};
    diagnosticResponses(2,:) = {'Yes','5 min to 1 hour',''};
    diagnosticResponses(3,:) = {'Yes','More than 1 hour','Yes'};
    diagnosticResponses(4,:) = {'Yes','More than 1 hour','No'};
    
    diagnosticNumberNeeded=[1,1,1,1,1,1,1];
    clear diagnosticAnswers
    diagnosticAnswers(1,:) = {'Yes','','','','',''};
    diagnosticAnswers(2,:) = {'5 min to 1 hour','','','','',''};
    diagnosticAnswers(3,:) = {'Yes','','','','',''};
    diagnosticAnswers(4,:) = {'Yes','','','','',''};
    diagnosticAnswers(5,:) = {'Spots','Stars','Lines','Flashing lights','Zigzag lines','Heat waves'};
    diagnosticAnswers(6,:) = {'Before the headache/discomfort','During the headache/discomfort','','','',''};
    diagnosticAnswers(7,:) = {'No, one happens first and then another happens later','','','','',''};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, multiCriterionQuestions);
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExist)
        clear sumDiagnosticAnswerTest;
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), multiCriterionQuestions);
        % test these columns for aura spread >= 5 minutes
        for ii = 1:size(diagnosticResponses,1)
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx(1:3))),diagnosticResponses(ii,:));
            sumDiagnosticAnswerTest(ii)=sum(diagnosticAnswerTest);
        end
        % If any of the patterns were found to match, then give this
        % diagnosis
        if any(sumDiagnosticAnswerTest == length(diagnosticAnswerTest)) && MigraineWithVisualAuraFlag(thisSubject)
            counter = counter + 1;
        end

        % Loop through the diagnostic questions
        for qq=2:length(questionColumnIdx) % Aura spread is handled right above, start at qq=2
            % Get the answer string for this question
            answerString = table2cell(T(thisSubject,questionColumnIdx(qq)));
            % Test if the answer string contains enough diagnostic answers
            diagnosticAnswerTest=cellfun(@(x) strfind(answerString, x), diagnosticAnswers(qq,:));
            if sum(cellfun(@(x) ~isempty(x),diagnosticAnswerTest)) >= diagnosticNumberNeeded(qq) && MigraineWithVisualAuraFlag(thisSubject)
                counter = counter + 1;
                if verbose
                    fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' met the second criterion for migraine with visual aura!\n']);
                end
            end % symptom inventory test
        end % loop over symptom inventory tests
        if counter < minRequirement
            MigraineWithVisualAuraFlag(thisSubject) = false;
        end
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        MigraineWithVisualAuraFlag(thisSubject) = false;
    end
    
    
    %% Migraine with other aura
    % The criteria that the subject must meet:
    %       1) give a specific set of yes/no responses, including:
    %           - yes to headache questions (Q1 or Q39 or Q41) (Q3)
    %           - yes to question regarding other aura (Q23 or Q85); Q8 is ignored
    %           - yes to having more than 2 lifetime other aura events (Q24 or Q86)
    %           - yes to aura symptom spreading over >= 5 minutes (Q84)(not applicable for speech aura)
    %           - yes to aura symptom lasting 5-60 mins (Q71 or Q90)
    %           - yes to aura symptom being unilateral (Q83 or Q85)
    %           - yes to two or more aura symptoms occuring in succession (Q148)
    %       2) multiple choice checkbox with one necessary and sufficient
    %          diagnostic answer: endorse having aura before/during headache (Q25 or Q87)
    %       3) multiple choice radio button, with two diagnostic answers:
    %          report aura duration between 5 and 60 min (Q26 or Q89). We
    %          understand that one can meet criteria by having two types of
    %          aura that are sequential and together last more than 60
    %          minutes. However, we do not test for sequential aura in POEM.
    
    % Define the binary questions and the diagnostic response patterns
    binaryQuestions={'Do you get headaches?',...
        'Have you ever had a headache?',...
        'Have you ever had episodes of discomfort, pressure, or pain around your eyes or face?',...
        'Do you get headaches or episodes of eye or face discomfort that are NOT caused by a head injury, hangover, or illness such as the cold or the flu?',...
        'Have you had this numbness and/or tingling with your headaches or discomfort episodes two or more times in your life?',...
        'Have you had difficulty speaking with your headaches or discomfort episodes two or more times in your life?'};
    clear diagnosticResponses;
    %For this section, binaryQuestions correspond to diagnosticResponses' columns (not rows)
    diagnosticResponses(1,:)={'Yes','','','Yes','Yes',''};
    diagnosticResponses(2,:)={'No','Yes','','Yes','Yes',''};
    diagnosticResponses(3,:)={'No','No','Yes','Yes','Yes',''};
    diagnosticResponses(4,:)={'Yes','','','Yes','Yes','No'};
    diagnosticResponses(5,:)={'No','Yes','','Yes','Yes','No'};
    diagnosticResponses(6,:)={'No','No','Yes','Yes','Yes','No'};
    diagnosticResponses(7,:)={'Yes','','','Yes','Yes','Yes'};
    diagnosticResponses(8,:)={'No','Yes','','Yes','Yes','Yes'};
    diagnosticResponses(9,:)={'No','No','Yes','Yes','Yes','Yes'};
    diagnosticResponses(10,:)={'Yes','','','Yes','','Yes'};
    diagnosticResponses(11,:)={'No','Yes','','Yes','','Yes'};
    diagnosticResponses(12,:)={'No','No','Yes','Yes','','Yes'};
    diagnosticResponses(13,:)={'Yes','','','Yes','No','Yes'};
    diagnosticResponses(14,:)={'No','Yes','','Yes','No','Yes'};
    diagnosticResponses(15,:)={'No','No','Yes','Yes','No','Yes'};

    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryQuestions);
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExist)
        clear sumDiagnosticAnswerTest;
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryQuestions);
        % test these columns for each of the diagnostic response patterns
        for ii = 1:size(diagnosticResponses,1)
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses(ii,:));
            sumDiagnosticAnswerTest(ii)=sum(diagnosticAnswerTest);
        end
        % If any of the patterns were found to match, then give this diagnosis
        if any(sumDiagnosticAnswerTest == length(diagnosticAnswerTest)) && MigraineWithOtherAuraFlag(thisSubject)
            if verbose
                fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' met the first criterion for migraine with other aura!\n']);
            end
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
    % At least three (minRequirement) of the following characteristics must
    % be met (for either sensory aura or speech aura)
    multiCriterionQuestionsSensory={'Does the numbness and/or tingling start in one spot, and then spread or move?',...
        'How long does the numbness and/or tingling last?',...
        'Do these changes ever last 5-60 minutes?',...
        'Is the numbness and/or tingling only on one side of your body?',...
        'Have you ever had any of the following happen around the time of your headaches or discomfort episodes? (check all that apply)',...
        'When do you have this numbness and/or tingling? Please check all that apply.',...
        'Do changes in vision, numbness/tingling, and or difficulty speaking happen at the same time?'};
    counterSensory = 0;
    % For this section, multiCriterionQuestionsSensory(1:3) correspond to diagnosticResponses' columns (not rows)
    clear diagnosticResponses;
    diagnosticResponses(1,:) = {'Yes','Less than 5 min','Yes'};
    diagnosticResponses(2,:) = {'Yes','5 min to 1 hour',''};
    diagnosticResponses(3,:) = {'Yes','More than 1 hour','Yes'};
    diagnosticResponses(4,:) = {'Yes','More than 1 hour','No'};

    diagnosticNumberNeededSensory=[1,1,1,1,1,1,1];
    clear diagnosticAnswersSensory
    diagnosticAnswersSensory(1,:) = {'Yes',''};
    diagnosticAnswersSensory(2,:) = {'5 min to 1 hour',''};
    diagnosticAnswersSensory(3,:) = {'Yes',''};
    diagnosticAnswersSensory(4,:) = {'Yes',''};
    diagnosticAnswersSensory(5,:) = {'Tingling of your body or face',''};
    diagnosticAnswersSensory(6,:) = {'Before the headache/discomfort','During the headache/discomfort'};
    diagnosticAnswersSensory(7,:) = {'No, one happens first and then another happens later',''};
    
    % Aura symptom spreading is not applicable for speech aura.
    % Q85 determines both if aura symptom is positive and if aura symptom
    % is unilateral, hence why it appears in the code twice.
    multiCriterionQuestionsSpeech={'How long does difficulty speaking usually last?',...
        'Do these speaking changes ever last 5-60 minutes?',...
        'Have you ever had any of the following happen around the time of your headaches or discomfort episodes? Please check all that apply.',...
        'Have you ever had any of the following happen around the time of your headaches or discomfort episodes? Please check all that apply.',...
        'When do you have difficulty speaking? Please check all that apply.',...
        'Do changes in vision, numbness/tingling, and or difficulty speaking happen at the same time?'};
    counterSpeech = 0;
    diagnosticNumberNeededSpeech=[1,1,1,1,1,1];
    clear diagnosticAnswersSpeech
    diagnosticAnswersSpeech(1,:) = {'5 min to 1 hour',''};
    diagnosticAnswersSpeech(2,:) = {'Yes',''};
    diagnosticAnswersSpeech(3,:) = {'Trouble saying words correctly','Unable to speak'}; % checks if unilateral
    diagnosticAnswersSpeech(4,:) = {'',''}; % checks if positive aura symptom
    diagnosticAnswersSpeech(5,:) = {'Before the headache/discomfort','During the headache/discomfort'};
    diagnosticAnswersSpeech(6,:) = {'No, one happens first and then another happens later',''};
    
    % Test if there is a column in the table for each question
    questionExistSensory = cellfun(@(x) sum(strcmp(QuestionText,x))==1, multiCriterionQuestionsSensory);
    questionExistSpeech = cellfun(@(x) sum(strcmp(QuestionText,x))==1, multiCriterionQuestionsSpeech);
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExistSensory) && all(questionExistSpeech)
        clear sumDiagnosticAnswerTest;
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdxSensory = cellfun(@(x) find(strcmp(QuestionText,x)), multiCriterionQuestionsSensory);
        questionColumnIdxSpeech = cellfun(@(x) find(strcmp(QuestionText,x)), multiCriterionQuestionsSpeech);
        % test these columns for aura spread >= 5 minutes
        for ii = 1:size(diagnosticResponses,1)
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdxSensory(1:3))),diagnosticResponses(ii,:));
            sumDiagnosticAnswerTest(ii)=sum(diagnosticAnswerTest);
        end
        % If any of the patterns were found to match, then give this
        % diagnosis
        if any(sumDiagnosticAnswerTest == length(diagnosticAnswerTest)) && MigraineWithOtherAuraFlag(thisSubject)
            counterSensory = counterSensory + 1;
        end

        % Loop through the sensory diagnostic questions
        for qq=2:length(questionColumnIdxSensory) % Aura spread is handled right above, start at qq=2
            % Get the answer string for this question
            answerStringSensory = table2cell(T(thisSubject,questionColumnIdxSensory(qq)));
            % Test if the answer string contains enough diagnostic answers
            diagnosticAnswerTestSensory=cellfun(@(x) strfind(answerStringSensory, x), diagnosticAnswersSensory(qq,:));
            if sum(cellfun(@(x) ~isempty(x),diagnosticAnswerTestSensory)) >= diagnosticNumberNeededSensory(qq) && MigraineWithOtherAuraFlag(thisSubject)
                counterSensory = counterSensory + 1;
                if verbose
                    fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' passed multiCriterionQuestion #' num2str(qq) ' for the second criterion for migraine with other aura!\n']);
                end
            end % symptom inventory test
        end % loop over symptom inventory tests
        % Loop through the speech diagnostic questions
        for qq=1:length(questionColumnIdxSpeech)
            % Get the answer string for this question
            answerStringSpeech = table2cell(T(thisSubject,questionColumnIdxSpeech(qq)));
            % Test if the answer string contains enough diagnostic answers
            diagnosticAnswerTestSpeech=cellfun(@(x) strfind(answerStringSpeech, x), diagnosticAnswersSpeech(qq,:));
            if sum(cellfun(@(x) ~isempty(x),diagnosticAnswerTestSpeech)) >= diagnosticNumberNeededSpeech(qq) && MigraineWithOtherAuraFlag(thisSubject)
                counterSpeech = counterSpeech + 1;
                if verbose
                    fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' passed multiCriterionQuestion #' num2str(qq) ' for the second criterion for migraine with other aura!\n']);
                end
            end % symptom inventory test
        end % loop over symptom inventory tests

        if counterSensory < minRequirement && counterSpeech < minRequirement
            MigraineWithOtherAuraFlag(thisSubject) = false;
        end
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        MigraineWithOtherAuraFlag(thisSubject) = false;
    end
    
    
    %% Migrane without aura
    % To qualify for migraine without aura, the candidate must not have
    %  received a diagnosis of Migraine with visual aura or Migraine with
    %  other aura (Q1 or Q39 or Q41) (Q3). They then must meet these criteria:
    %       1) give a specific set of yes/no responses (Q4, Q7)
    %       2) endorse 2/4 from symptom list 1 (Q5)
    %       3) endorse 1/3 from symptom list 2 (Q6)
    
    if ~MigraineWithVisualAuraFlag(thisSubject) && ~MigraineWithOtherAuraFlag(thisSubject)
        
        % Define the binary questions and the diagnostic responses
        binaryQuestions={'Do you get headaches?',...
            'Have you ever had a headache?',...
            'Have you ever had episodes of discomfort, pressure, or pain around your eyes or face?',...
            'Do you get headaches or episodes of eye or face discomfort that are NOT caused by a head injury, hangover, or illness such as the cold or the flu?',...
            'Do your headaches or discomfort episodes ever last more than 4 hours?',...
            'Have you had these headaches or discomfort episodes 5 or more times in your life?'};
        clear diagnosticResponses;
        %For this section, binaryQuestions correspond to diagnosticResponses' columns (not rows)
        diagnosticResponses(1,:)={'Yes','','','Yes','Yes','Yes'};
        diagnosticResponses(2,:)={'No','Yes','','Yes','Yes','Yes'};
        diagnosticResponses(3,:)={'No','No','Yes','Yes','Yes','Yes'};
        
        % Test if there is a column in the table for each question
        questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryQuestions);
        
        % QuestionExist will all be true if a column was found for each question
        if all(questionExist)
            clear sumDiagnosticAnswerTest;
            % Identify which columns of the table contain the relevant questions.
            questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryQuestions);
            % test these columns for each of the diagnostic response patterns
            for ii = 1:size(diagnosticResponses,1)
                diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses(ii,:));
                sumDiagnosticAnswerTest(ii)=sum(diagnosticAnswerTest);
            end
            % If any of the patterns were found to match, then give this diagnosis
            if any(sumDiagnosticAnswerTest == length(diagnosticAnswerTest)) && MigraineWithoutAuraFlag(thisSubject)
                if verbose
                    fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' met the first criterion for migraine without aura!\n']);
                end
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
        multiCriterionQuestions={'Do your headaches or discomfort episodes that last more than four hours have any of the following? Please check all that apply.',...
            'During headaches or discomfort episodes that last longer than 4 hours, do you ever experience the following symptoms? Please check all that apply.'};
        diagnosticNumberNeeded=[2,1];
        clear diagnosticAnswers
        diagnosticAnswers(1,:) = {'The pain is worse on one side',...
            'The pain is pounding, pulsating, or throbbing',...
            'The pain is moderate or severe in intensity',...
            'The pain is made worse by routine activities such as walking or climbing stairs'};
        diagnosticAnswers(2,:) = {'Nausea and/or vomiting',...
            'Sensitivity to light',...
            'Sensitivity to sound',...
            ''};
        
        % Test if there is a column in the table for each question
        questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, multiCriterionQuestions);
        
        % QuestionExist will all be true if a column was found for each question
        if all(questionExist)
            % Identify which columns of the table contain the relevant questions.
            questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), multiCriterionQuestions);
            % Loop through the diagnostic questions
            for qq=1:length(questionColumnIdx)
                % Get the answer string for this question
                answerString = table2cell(T(thisSubject,questionColumnIdx(qq)));
                % Test if the answer string contains enough diagnostic answers
                diagnosticAnswerTest=cellfun(@(x) strfind(answerString, x), diagnosticAnswers(qq,:));
                if sum(cellfun(@(x) ~isempty(x),diagnosticAnswerTest)) >= diagnosticNumberNeeded(qq) && MigraineWithoutAuraFlag(thisSubject)
                    if verbose
                        fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' passed multiCriterionQuestion #' num2str(qq) ' for the second criterion for migraine without aura!\n']);
                    end
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
        
    else
        % The subject has already been given a diagnosis of either Migraine
        % with visual aura, or Migraine with other aura, or both. As a
        % consequence, we will set Migraine without aura to false.
        MigraineWithoutAuraFlag(thisSubject) = false;
    end % check that neither Migraine with visual or other aura was true
    
    
    %% Headache free
    % Define the binary questions and the diagnostic response patterns (Q1, Q39, Q41, Q3)
    binaryCriterionQuestions={'Do you get headaches?',...
        'Have you ever had a headache?',...
        'Have you ever had episodes of discomfort, pressure, or pain around your eyes or face?',...
        'Do you get headaches or episodes of eye or face discomfort that are NOT caused by a head injury, hangover, or illness such as the cold or the flu?'};
    clear diagnosticResponses
    %For this section, binaryCriterionQuestions correspond to diagnosticResponses' columns (not rows)
    diagnosticResponses(1,:) = {'No','No','No',''};
    diagnosticResponses(2,:) = {'No','No','Yes','No'};
    diagnosticResponses(3,:) = {'No','Yes','','No'};
    diagnosticResponses(4,:) = {'Yes','','','No'};
    
    % Test if there is a column in the table for each question
    % KNOWN BUG - If no subjects have followed a path resulting in
    % responses in one or more of the criterion questions, then the test
    % for headache free status will be skipped for every subject!
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryCriterionQuestions);
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExist)
        clear sumDiagnosticAnswerTest;
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
            if verbose
                fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' met the criterion for headache free!\n']);
            end
        else
            HeadacheFreeFlag(thisSubject) = false;
        end % binary test
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        HeadacheFreeFlag(thisSubject) = false;
    end
    
    
    %% mildNonMigrainousHeadache vs. HeadacheNOS
    % If a subject does not fall into any other diagnostic category, then
    % we they will be given the label of either MildHeadache or HeadacheNOS
    % depending upon these questions
    
    % Test if the subject has received no other diagnosis yet
    if ~any( [ MigraineWithoutAuraFlag(thisSubject) ...
            MigraineWithVisualAuraFlag(thisSubject) ...
            MigraineWithOtherAuraFlag(thisSubject) ...
            HeadacheFreeFlag(thisSubject) ] )
        
        % Test if the subject has mild headache. This is done with a set of
        % multiCriterionQuestions for which there are exclusionary
        % responses. If the subject provides even one of these exclusionary
        % responses for a single question, then they do not meet criteria
        % for MildNonMigrainousHeadache
        
        % We exclude from the mild headache diagnosis anyone who:
        % 1. reports that their headaches last longer than 4 hour (Q4)
        % 2. endorses symptoms suggestive of aura, even if they do not
        %       meet formal criteria for migraine with aura (Q8, Q23, Q85)
        % 3. endorses any of the migraine characteristics of sensory
        %       sensivity, nausea/vomitting, exacerbation with activity (Q131, Q51, Q52)
        multiCriterionQuestions={'Do your headaches or discomfort episodes ever last more than 4 hours?',...
            'Around the time of your headaches or discomfort episodes, have you ever seen any of the following? (check all that apply)',...
            'Have you ever had any of the following happen around the time of your headaches or discomfort episodes? (check all that apply)',...
            'Have you ever had any of the following happen around the time of your headaches or discomfort episodes? Please check all that apply.',...
            'Do you usually get headaches around your menstrual periods?',...
            'For your WORST type of headache or discomfort episode, do any of the following statements describe your pain and symptoms? Please check all that apply.',...
            'During your WORST type of headache or discomfort episode, do you ever experience the following symptoms? Please check all that apply.'};
        
        exclusionNumberNeeded=[1,1,1,1,1,1,1];
        clear exclusionAnswers
        exclusionAnswers(1,:) ={'Yes','','','','','',''};
        exclusionAnswers(2,:) ={'Spots','Stars','Lines','Flashing lights','Zigzag lines','Heat waves','Vision loss'};
        exclusionAnswers(3,:) ={'Numbness of your body or face','Tingling of your body or face','','','','',''};
        exclusionAnswers(4,:) ={'Trouble saying words correctly','Slurred speech','Unable to speak','','','',''};
        exclusionAnswers(5,:) ={'Yes','','','','','',''};
        exclusionAnswers(6,:) ={'The pain is pounding, pulsating, or throbbing','The pain is moderate or severe in intensity','The pain is made worse by routine activities such as walking or climbing stairs','','','',''};
        exclusionAnswers(7,:) ={'Nausea and/or vomiting','Sensitivity to light','Sensitivity to sound','','','',''};
        
        % Test if there is a column in the table for each question
        questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, multiCriterionQuestions);
        
        % if any questionExist was found, then see if we can exclude the
        % subject from the MildHeadache category
        if any(questionExist)
            % Identify which columns of the table contain the relevant questions.
            questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), multiCriterionQuestions);
            % Loop through the exclusion questions
            for qq=1:length(questionColumnIdx)
                % Get the answer string for this question
                answerString = table2cell(T(thisSubject,questionColumnIdx(qq)));
                % Test if the answer string contains enough diagnostic answers
                exclusionAnswerTest=cellfun(@(x) strfind(answerString, x), exclusionAnswers(qq,:));
                if sum(cellfun(@(x) ~isempty(x),exclusionAnswerTest)) >= exclusionNumberNeeded(qq) && MildNonMigrainousHeadacheFlag(thisSubject)
                    if verbose
                        fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' has an exclusionary criterion for MildHeadache!\n']);
                    end
                    MildNonMigrainousHeadacheFlag(thisSubject) = false;
                end % symptom inventory test
            end % loop over symptom inventory tests
        else
            % No subject has gone down any branch of the survey that could
            % be used to evaluate for MildHeadache. Mark all subjects as
            % false for this diagnosis.
            MildNonMigrainousHeadacheFlag(thisSubject) = false;
        end
        
        % If the subject has met criteria for MildHeadache, then set
        % HeadacheNOSFlag to false
        if MildNonMigrainousHeadacheFlag(thisSubject)
            HeadacheNOSFlag(thisSubject) = false;
        else
            % if the subject has been excluded from MildHeadache, plus has
            % been excluded from all other diagnostic categories (including
            % HeadacheFree), then they are assigned to HeadacheNOS
            % (this line of code is not strictly needed, but is included
            % here to make the logic control more evident).
            HeadacheNOSFlag(thisSubject) = true;
        end
    else
        % As the subject has a headache diagnosis, then they cannot have
        % either MildHeadache or HeadacheNOS
        HeadacheNOSFlag(thisSubject) = false;
        MildNonMigrainousHeadacheFlag(thisSubject) = false;
    end
    
    
    %% Choi photophobia questions
    % The Choi (2009) survey consists of seven questions that assess
    % photophobia during migraine. The score is the number of 'yes'
    % responses out of seven (Q29, Q31, Q33, Q35, Q37, Q39, Q41).
    % We've created a shorter headache-free version as well (Q132, Q133, Q134, Q135).
    binaryCriterionQuestions={'During your headaches or discomfort episodes, do you feel a greater sense of glare or dazzle in your eyes than usual by bright lights?',...
        'During your headaches or discomfort episodes, do flickering lights, glare, specific colors or high contrast striped patterns bother you or your eyes?',...
        'During your headaches or discomfort episodes, do you turn off the lights or draw a curtain to avoid bright conditions?',...
        'During your headaches or discomfort episodes, do you have to wear sunglasses even in normal daylight?',...
        'During your headaches or discomfort episodes, do bright lights hurt your eyes?',...
        'Is your headache or discomfort episode worsened by bright lights?',...
        'Is your headache or discomfort episode triggered by bright lights?'};
    clear diagnosticResponses
    diagnosticResponses={'Yes','Yes','Yes','Yes','Yes','Yes','Yes'};
    emptyResponses={'','','','','','',''};
    
    %HF version
    binaryCriterionQuestionsHF={'Do flickering lights, glare, specific colors or high contrast striped patterns bother you or your eyes?',...
        'Do you turn off the lights or draw a curtain to avoid bright conditions?',...
        'Do you have to wear sunglasses even in normal daylight?',...
        'Do bright lights hurt your eyes?'};
    clear diagnosticResponsesHF
    diagnosticResponsesHF={'Yes','Yes','Yes','Yes'};
    emptyResponsesHF={'','','',''};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryCriterionQuestions);
    questionExistHF = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryCriterionQuestionsHF);
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExist) && all(questionExistHF)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        questionColumnIdxHF = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestionsHF);
        % Test if any of these columns are empty. If so, this subject has
        % not completed the Choi survey and is assigned a NaN score
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);
        emptyAnswerTestHF = strcmp(table2cell(T(thisSubject,questionColumnIdxHF)),emptyResponsesHF);
        if any(emptyAnswerTest) && any(emptyAnswerTestHF)
            ChoiIctalPhotophobiaScore(thisSubject) = nan;
        elseif any(emptyAnswerTest)
            % count how many of these columns contain the diagnostic responses (HF version)
            diagnosticAnswerTestHF = strcmp(table2cell(T(thisSubject,questionColumnIdxHF)),diagnosticResponsesHF);
            ChoiIctalPhotophobiaScore(thisSubject) = sum(diagnosticAnswerTestHF);
        else
            % count how many of these columns contain the diagnostic responses
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
            ChoiIctalPhotophobiaScore(thisSubject) = sum(diagnosticAnswerTest);
        end % binary test
    else
        % If no subject has gone answered the Choi survey questions, then
        % one or more columns in the table may not be present for these
        % questions. If this is the case, mark Choi score as NaN.
        ChoiIctalPhotophobiaScore(thisSubject) = nan;
    end
    
    
    %% Interictal photophobia
    %  (Q43)
    binaryCriterionQuestions={'Do you have any of the above symptoms even during your headache-free interval?'};
    clear diagnosticResponses
    diagnosticResponses={'Yes'};
    emptyResponses={''};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryCriterionQuestions);
    
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        % Test if any of these columns are empty. If so, this subject has
        % not completed the Choi survey and is assigned a false value
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);
        diagnosticTrue = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
        if any(emptyAnswerTest)
            InterictalPhotophobia(thisSubject) = false;
        elseif any(diagnosticTrue)
            InterictalPhotophobia(thisSubject) = true;
        else
            InterictalPhotophobia(thisSubject) = false;
        end % binary test
    else
        % If no subject has gone answered the Choi survey questions, then
        % one or more columns in the table may not be present for these
        % questions. If this is the case, mark value as false.
        InterictalPhotophobia(thisSubject) = false;
    end
    
    
    %% Allodynia Symptom Checklist (ASC-12) questions
    % The Allodynia Symptom Checklist (2008) consists of twelve questions
    % that assess cutaneous allodynia. Response options were never (0),
    % rarely (0), less than 50% of the time (1), 50% of the time or more
    % (2), and none (0). A scale was developed distinguishing no CA (scores 0–2),
    % mild (3–5), moderate (6–8), and severe (>=9) (Q118 - Q129).
    % We've created a headache-free version as well (Q136 - Q147).
    multiCriterionQuestions={'During your most severe headaches or discomfort episodes, how often do you experience increased pain or an unpleasant sensation on your skin when combing your hair?',...
        'During your most severe headaches or discomfort episodes, how often do you experience increased pain or an unpleasant sensation on your skin when pulling your hair back (e.g., ponytail)?',...
        'During your most severe headaches or discomfort episodes, how often do you experience increased pain or an unpleasant sensation on your skin when shaving your face?',...
        'During your most severe headaches or discomfort episodes, how often do you experience increased pain or an unpleasant sensation on your skin when wearing eyeglasses?',...
        'During your most severe headaches or discomfort episodes, how often do you experience increased pain or an unpleasant sensation on your skin when wearing contact lenses?',...
        'During your most severe headaches or discomfort episodes, how often do you experience increased pain or an unpleasant sensation on your skin when wearing earrings?',...
        'During your most severe headaches or discomfort episodes, how often do you experience increased pain or an unpleasant sensation on your skin when wearing a necklace?',...
        'During your most severe headaches or discomfort episodes, how often do you experience increased pain or an unpleasant sensation on your skin when wearing tight clothing?',...
        'During your most severe headaches or discomfort episodes, how often do you experience increased pain or an unpleasant sensation on your skin when taking a shower (when shower water hits your face)?',...
        'During your most severe headaches or discomfort episodes, how often do you experience increased pain or an unpleasant sensation on your skin when resting your face or head on a pillow?',...
        'During your most severe headaches or discomfort episodes, how often do you experience increased pain or an unpleasant sensation on your skin when exposed to heat (e.g., cooking, washing your face with hot water)?',...
        'During your most severe headaches or discomfort episodes, how often do you experience increased pain or an unpleasant sensation on your skin when exposed to cold (e.g., using an ice pack, washing your face with cold water)?'};
    
    clear diagnosticAnswers
    diagnosticAnswers(1,:) ={'Less than half the time','Half the time or more'};
    diagnosticAnswers(2,:) ={'Less than half the time','Half the time or more'};
    diagnosticAnswers(3,:) ={'Less than half the time','Half the time or more'};
    diagnosticAnswers(4,:) ={'Less than half the time','Half the time or more'};
    diagnosticAnswers(5,:) ={'Less than half the time','Half the time or more'};
    diagnosticAnswers(6,:) ={'Less than half the time','Half the time or more'};
    diagnosticAnswers(7,:) ={'Less than half the time','Half the time or more'};
    diagnosticAnswers(8,:) ={'Less than half the time','Half the time or more'};
    diagnosticAnswers(9,:) ={'Less than half the time','Half the time or more'};
    diagnosticAnswers(10,:)={'Less than half the time','Half the time or more'};
    diagnosticAnswers(11,:)={'Less than half the time','Half the time or more'};
    diagnosticAnswers(12,:)={'Less than half the time','Half the time or more'};
    emptyAnswers={'','','','','','','','','','','',''};
    
    %HF version
    multiCriterionQuestionsHF={'How often do you experience increased pain or an unpleasant sensation on your skin when combing your hair?',...
        'How often do you experience increased pain or an unpleasant sensation on your skin when pulling your hair back (e.g., ponytail)?',...
        'How often do you experience increased pain or an unpleasant sensation on your skin when shaving your face?',...
        'How often do you experience increased pain or an unpleasant sensation on your skin when wearing eyeglasses?',...
        'How often do you experience increased pain or an unpleasant sensation on your skin when wearing contact lenses?',...
        'How often do you experience increased pain or an unpleasant sensation on your skin when wearing earrings?',...
        'How often do you experience increased pain or an unpleasant sensation on your skin when wearing a necklace?',...
        'How often do you experience increased pain or an unpleasant sensation on your skin when wearing tight clothing?',...
        'How often do you experience increased pain or an unpleasant sensation on your skin when taking a shower (when shower water hits your face)?',...
        'How often do you experience increased pain or an unpleasant sensation on your skin when resting your face or head on a pillow?',...
        'How often do you experience increased pain or an unpleasant sensation on your skin when exposed to heat (e.g., cooking, washing your face with hot water)?',...
        'How often do you experience increased pain or an unpleasant sensation on your skin when exposed to cold (e.g., using an ice pack, washing your face with cold water)?'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, multiCriterionQuestions);
    questionExistHF = cellfun(@(x) sum(strcmp(QuestionText,x))==1, multiCriterionQuestionsHF);
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExist) && all(questionExistHF)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), multiCriterionQuestions);
        questionColumnIdxHF = cellfun(@(x) find(strcmp(QuestionText,x)), multiCriterionQuestionsHF);
        % Test if any of these columns are empty. If so, this subject has
        % not completed the ASC-12 survey and is assigned a NaN score
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyAnswers);
        emptyAnswerTestHF = strcmp(table2cell(T(thisSubject,questionColumnIdxHF)),emptyAnswers);
        if any(emptyAnswerTest) && any(emptyAnswerTestHF)
            IctalAllodyniaScore(thisSubject) = nan;
        elseif any(emptyAnswerTest)
            % count how many of these columns contain diagnostic answers
            % and add their values (HF version)
            diagnosticAnswer1TestHF = strcmp(table2cell(T(thisSubject,questionColumnIdxHF)),diagnosticAnswers(:,1)'); %column 1 has a value of 1
            diagnosticAnswer2TestHF = strcmp(table2cell(T(thisSubject,questionColumnIdxHF)),diagnosticAnswers(:,2)'); %column 2 has a value of 2
            IctalAllodyniaScore(thisSubject) = sum(diagnosticAnswer1TestHF) + sum(diagnosticAnswer2TestHF * 2);
        else
            % count how many of these columns contain diagnostic answers
            % and add their values
            diagnosticAnswer1Test = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticAnswers(:,1)'); %column 1 has a value of 1
            diagnosticAnswer2Test = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticAnswers(:,2)'); %column 2 has a value of 2
            IctalAllodyniaScore(thisSubject) = sum(diagnosticAnswer1Test) + sum(diagnosticAnswer2Test * 2);
        end % diagnostic test
    else
        % If no subject has gone answered the ASC-12 survey questions, then
        % one or more columns in the table may not be present for these
        % questions. If this is the case, mark Allodynia score as NaN.
        IctalAllodyniaScore(thisSubject) = nan;
    end
    
    
    %% Interictal allodynia
    %  (Q130)
    binaryCriterionQuestions={'Do you ever have any of the above symptoms in between your headaches or discomfort episodes?'};
    clear diagnosticResponses
    diagnosticResponses={'Yes'};
    emptyResponses={''};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryCriterionQuestions);
    
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        % Test if any of these columns are empty. If so, this subject has
        % not completed the ASC-12 survey and is assigned a false value
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);
        diagnosticTrue = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
        if any(emptyAnswerTest)
            InterictalAllodynia(thisSubject) = false;
        elseif any(diagnosticTrue)
            InterictalAllodynia(thisSubject) = true;
        else
            InterictalAllodynia(thisSubject) = false;
        end % binary test
    else
        % If no subject has gone answered the ASC-12 survey questions, then
        % one or more columns in the table may not be present for these
        % questions. If this is the case, mark value as false.
        InterictalAllodynia(thisSubject) = false;
    end
    
    
    %% Eyes sensitive to light
    % What was the response? (Q77)
    
    binaryCriterionQuestions={'Are your eyes sensitive to light?'};
    emptyResponses={''};
    
    % Test if there is a single column in the table for this question
    questionExist = sum(strcmp(QuestionText,binaryCriterionQuestions{1}))==1;
    
    % QuestionExist will all be true if a column was found for each question
    if questionExist
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        % Test if this column is empty. If so, this subject has
        % not completed the family history question (which should never
        % happen)
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);
        if any(emptyAnswerTest)
            LightSensitiveEyes(thisSubject) = {''};
        else
            % Copy over the response string
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
            LightSensitiveEyes(thisSubject) = table2cell(T(thisSubject,questionColumnIdx));
        end % binary test
    else
        % If no subject has answered the family history question, then
        % make sure that all entries continue to be empty
        LightSensitiveEyes(thisSubject) = {''};
    end
    
    
    %% History of childhood motion sickness
    % The subject answers this if they did not go down a migraine path (Q63)
    
    binaryCriterionQuestions={'Did you get motion sick (e.g. car sick) when you were a child?'};
    emptyResponses={''};
    
    % Test if there is a single column in the table for this question
    questionExist = sum(strcmp(QuestionText,binaryCriterionQuestions{1}))==1;
    
    % QuestionExist will all be true if a column was found for each question
    if questionExist
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        % Test if this column is empty. If so, this subject has
        % not completed the family history question (which should never
        % happen)
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);
        if any(emptyAnswerTest)
            ChildhoodMotionSickness(thisSubject) = {''};
        else
            % Copy over the response string
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
            ChildhoodMotionSickness(thisSubject) = table2cell(T(thisSubject,questionColumnIdx));
        end % binary test
    else
        % If no subject has answered the family history question, then
        % make sure that all entries continue to be empty
        ChildhoodMotionSickness(thisSubject) = {''};
    end
    
    
    %% Family history of migraine or headache
    % What was the subject response to the family history of headache q? (Q65)
    
    binaryCriterionQuestions={'Do your parents, children, brothers, or sisters get migraines?'};
    emptyResponses={''};
    
    % Test if there is a single column in the table for this question
    questionExist = sum(strcmp(QuestionText,binaryCriterionQuestions{1}))==1;
    
    % QuestionExist will all be true if a column was found for each question
    if questionExist
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        % Test if this column is empty. If so, this subject has
        % not completed the family history question (which should never
        % happen)
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);
        if any(emptyAnswerTest)
            FamHxOfHeadache(thisSubject) = {''};
        else
            % Copy over the response string
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
            FamHxOfHeadache(thisSubject) = table2cell(T(thisSubject,questionColumnIdx));
        end % binary test
    else
        % If no subject has answered the family history question, then
        % make sure that all entries continue to be empty
        FamHxOfHeadache(thisSubject) = {''};
    end
    
    
    %% Ophthalmology
    %  (Q73, Q76)
    binaryCriterionQuestions={'Have you ever been seen by an ophthalmologist for an eye disease, other than for a routine check-up or to receive a prescription for glasses?'};
    openCriterionQuestions={'If yes, please provide details and any diagnosis given.'};
    diagnosticResponses={'Yes'};
    emptyResponses={''};

    % Test if there is a column in the table for each question
    questionExist(1) = sum(strcmp(QuestionText,binaryCriterionQuestions{1}))==1;
    questionExist(2) = sum(strcmp(QuestionText,openCriterionQuestions{1}))==1;
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx(1) = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        questionColumnIdx(2) = cellfun(@(x) find(strcmp(QuestionText,x)), openCriterionQuestions);
        % Test if any of these columns are empty. If so, this subject has
        % not completed the family history question (which should never
        % happen)
        diagnosticTrue = strcmp(table2cell(T(thisSubject,questionColumnIdx(1))),diagnosticResponses);
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx(2))),emptyResponses);
        if emptyAnswerTest && diagnosticTrue
            Ophthalmology(thisSubject) = table2cell(T(thisSubject,questionColumnIdx(1)));
        elseif emptyAnswerTest
            Ophthalmology(thisSubject) = {''};
        else
            % Copy over the response string
            Ophthalmology(thisSubject) = table2cell(T(thisSubject,questionColumnIdx(2)));
        end % binary test
    else
        % If no subject has answered the headache recency question, then
        % make sure that all entries continue to be empty
        Ophthalmology(thisSubject) = {''};
    end
    
    
    %% Monthly Frequency
    %  Should endorse headache frequency between 10-20 days a month (Q117)
    multiCriterionQuestions={'How often do you have these headaches or discomfort episodes in a typical month?'};
    emptyResponses={''};
    
    % Test if there is a single column in the table for this question
    questionExist = sum(strcmp(QuestionText,multiCriterionQuestions{1}))==1;
    
    % QuestionExist will all be true if a column was found for each question
    if questionExist
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), multiCriterionQuestions);
        % Test if this column is empty. If so, this subject has
        % not completed the family history question (which should never
        % happen)
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);
        if any(emptyAnswerTest)
            FrequencyMonthly(thisSubject) = {''};
        else
            % Copy over the response string
            FrequencyMonthly(thisSubject) = table2cell(T(thisSubject,questionColumnIdx));
        end % binary test
    else
        % If no subject has answered the headache recency question, then
        % make sure that all entries continue to be empty
        FrequencyMonthly(thisSubject) = {''};
    end


    %% Headache recency
    %  (Q38)
    binaryCriterionQuestions={'When is the last time you had one of these headaches or discomfort episodes?'};
    emptyResponses={''};
    
    % Test if there is a single column in the table for this question
    questionExist = sum(strcmp(QuestionText,binaryCriterionQuestions{1}))==1;
    
    % QuestionExist will all be true if a column was found for each question
    if questionExist
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        % Test if this column is empty. If so, this subject has
        % not completed the family history question (which should never
        % happen)
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);
        if any(emptyAnswerTest)
            RecencyMigraine(thisSubject) = {''};
        else
            % Copy over the response string
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
            RecencyMigraine(thisSubject) = table2cell(T(thisSubject,questionColumnIdx));
        end % binary test
    else
        % If no subject has answered the headache recency question, then
        % make sure that all entries continue to be empty
        RecencyMigraine(thisSubject) = {''};
    end
    
    
    %% Aura recency
    %  Should endorse aura recency within the past week, month, or year (Q47, Q48, Q88)
    binaryCriterionQuestions={'When was the last time you had these vision changes?',...
        'When was the last time you had this numbness and/or tingling?',...
        'When was the last time you had difficulty speaking?'};
    clear diagnosticAnswers
    diagnosticAnswers(1,:) = {'Within the past week','Within the past month','Within the past year'};
    diagnosticAnswers(2,:) = {'Within the past week','Within the past month','Within the past year'};
    diagnosticAnswers(3,:) = {'Within the past week','Within the past month','Within the past year'};
    emptyResponses={'','',''};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryCriterionQuestions);
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        % Test if any of these columns are empty. If so, this subject has
        % not completed the family history question (which should never
        % happen)
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);

        if ~(emptyAnswerTest(1))
            % Test if at least one kind of aura is recent. Within the past
            % week, month, or year is considered recent.
            diagnosticAnswerTest=cellfun(@(x) strcmp(table2cell(T(thisSubject,questionColumnIdx(1))), x), diagnosticAnswers(1,:));
            if any(diagnosticAnswerTest)
                RecencyAnyAura(thisSubject) = true;
            end
        end

        if ~(emptyAnswerTest(2))
            % Test if at least one kind of aura is recent. Within the past
            % week, month, or year is considered recent.
            diagnosticAnswerTest=cellfun(@(x) strcmp(table2cell(T(thisSubject,questionColumnIdx(2))), x), diagnosticAnswers(2,:));
            if any(diagnosticAnswerTest)
                RecencyAnyAura(thisSubject) = true;
            end
        end

        if ~(emptyAnswerTest(3))
            % Test if at least one kind of aura is recent. Within the past
            % week, month, or year is considered recent.
            diagnosticAnswerTest=cellfun(@(x) strcmp(table2cell(T(thisSubject,questionColumnIdx(3))), x), diagnosticAnswers(3,:));
            if any(diagnosticAnswerTest)
                RecencyAnyAura(thisSubject) = true;
            end
        end
    end
    
    
    %% Question regarding errors or sincerity
    % What was the response? (Q68)
    
    binaryCriterionQuestions={'Are your answers sincere? Are they correct?'};
    emptyResponses={''};
    
    % Test if there is a single column in the table for this question
    questionExist = sum(strcmp(QuestionText,binaryCriterionQuestions{1}))==1;
    
    % QuestionExist will all be true if a column was found for each question
    if questionExist
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        % Test if this column is empty. If so, this subject has
        % not completed the family history question (which should never
        % happen)
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);
        if any(emptyAnswerTest)
            SincerityQuestion(thisSubject) = {''};
        else
            % Copy over the response string
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
            SincerityQuestion(thisSubject) = table2cell(T(thisSubject,questionColumnIdx));
        end % binary test
    else
        % If no subject has answered the family history question, then
        % make sure that all entries continue to be empty
        SincerityQuestion(thisSubject) = {''};
    end
    
    
    %% Question regarding contact in future studies
    % What was the response? (Q69)
    
    binaryCriterionQuestions={'May we contact you about future projects in headache research?'};
    emptyResponses={''};
    
    % Test if there is a single column in the table for this question
    questionExist = sum(strcmp(QuestionText,binaryCriterionQuestions{1}))==1;
    
    % QuestionExist will all be true if a column was found for each question
    if questionExist
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        % Test if this column is empty. If so, this subject has
        % not completed the family history question (which should never
        % happen)
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);
        if any(emptyAnswerTest)
            FutureContact(thisSubject) = {''};
        else
            % Copy over the response string
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
            FutureContact(thisSubject) = table2cell(T(thisSubject,questionColumnIdx));
        end % binary test
    else
        % If no subject has answered the family history question, then
        % make sure that all entries continue to be empty
        FutureContact(thisSubject) = {''};
    end
    
end % loop over subjects


%% Assemble diagnosisTable
diagnosisTable=table(HeadacheFreeFlag, ...
    MildNonMigrainousHeadacheFlag, ...
    HeadacheNOSFlag, ...
    MigraineWithoutAuraFlag, ...
    MigraineWithVisualAuraFlag, ...
    MigraineWithOtherAuraFlag, ...
    ChoiIctalPhotophobiaScore, ...
    InterictalPhotophobia, ...
    IctalAllodyniaScore, ...
    InterictalAllodynia, ...
    LightSensitiveEyes, ...
    ChildhoodMotionSickness, ...
    FamHxOfHeadache, ...
    Ophthalmology, ...
    FrequencyMonthly, ...
    RecencyMigraine, ...
    RecencyAnyAura, ...
    SincerityQuestion, ...
    FutureContact);
diagnosisTable.Properties.VariableNames=diagnoses;
diagnosisTable.Properties.RowNames=T.Properties.RowNames;


end % function



