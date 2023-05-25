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
    'ChildhoodMotionSickness',...
    'FamHxOfHeadache',...
    'Ophthalmology',...
    'FrequencyMonthly',...
    'RecencyMigraine',...
    'RecencyVisualAura',...
    'RecencySensoryAura',...
    'RecencySpeakingAura',...
    'RecencyAnyAura',...
    'SeriousnessQuestion'};

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
%A variable to hold the response to this question from ASC-12
InterictalAllodynia=false(numSubjects, 1);
%A variable to hold if at least one kind of aura is recent
RecencyAnyAura = false(numSubjects, 1);
% These next set of data columns contain the strings copied over from the
% answer text, and default to empty.
ChildhoodMotionSickness = cell(numSubjects, 1);
FamHxOfHeadache = cell(numSubjects, 1);
Ophthalmology = cell(numSubjects, 1);
FrequencyMonthly = cell(numSubjects, 1);
RecencyMigraine = cell(numSubjects, 1);
RecencyVisualAura = cell(numSubjects, 1);
RecencySensoryAura = cell(numSubjects, 1);
RecencySpeakingAura = cell(numSubjects, 1);
SeriousnessQuestion = cell(numSubjects, 1);

for thisSubject = 1:numSubjects
    
    
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
        'Do you get headaches or episodes of eye or face discomfort that are NOT caused by a head injury, hangover, or illness such as the cold or the flu?',...
        'Have you had these vision changes with your headaches or discomfort episodes two or more times in your life?',...
        'How long do these vision changes usually last?'};
    diagnosticResponses={'Yes','Yes','Yes','5 min to 1 hour'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryQuestions);
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryQuestions);
        % determine if these columns contain the diagnostic responses
        diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
        if sum(diagnosticAnswerTest) == length(diagnosticAnswerTest) && MigraineWithVisualAuraFlag(thisSubject)
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
    multiCriterionQuestions={'Around the time of your headaches or discomfort episodes, have you ever seen any of the following? (check all that apply)',...
        'When do you see these visual phenomena in relation to your headaches or discomfort episodes? Please check all that apply.'};
    diagnosticNumberNeeded=[1,1];
    clear diagnosticAnswers
    diagnosticAnswers(1,:) = {'Spots','Stars','Lines','Flashing lights','Zigzag lines','Heat waves','Vision loss'};
    diagnosticAnswers(2,:) = {'Before the headache/discomfort','','','','','',''};
    
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
            if sum(cellfun(@(x) ~isempty(x),diagnosticAnswerTest)) >= diagnosticNumberNeeded(qq) && MigraineWithVisualAuraFlag(thisSubject)
                if verbose
                    fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' met the second criterion for migraine with visual aura!\n']);
                end
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
    %       3) multiple choice radio button, with two diagnostic answers:
    %          report aura duration between 5 and 60 min or longer than 60
    %          minutes (Q26). The >60 minute answer is acceptable as it is one
    %          can meet criteria by having two types of aura that are
    %          sequential and together last more than 60 minutes.
    
    % Define the binary questions and the diagnostic responses
    binaryQuestions={'Do you get headaches?',...
        'Do you get headaches or episodes of eye or face discomfort that are NOT caused by a head injury, hangover, or illness such as the cold or the flu?',...
        'Have you had this numbness and/or tingling with your headaches or discomfort episodes two or more times in your life?'};
    diagnosticResponses={'Yes','Yes','Yes'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryQuestions);
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryQuestions);
        % determine if these columns contain the diagnostic responses
        diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
        if sum(diagnosticAnswerTest) == length(diagnosticAnswerTest) && MigraineWithOtherAuraFlag(thisSubject)
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
    multiCriterionQuestions={'When do you have this numbness and/or tingling? Please check all that apply.', ...
        'Have you ever had any of the following happen around the time of your headaches or discomfort episodes? (check all that apply)',...
        'How long does the numbness and/or tingling last?'};
    diagnosticNumberNeeded=[1,1,1];
    clear diagnosticAnswers
    diagnosticAnswers(1,:) = {'Before the headache/discomfort',''};
    diagnosticAnswers(2,:) = {'Numbness of your body or face','Tingling of your body or face'};
    diagnosticAnswers(3,:) = {'5 min to 1 hour','More than 1 hour'};
    
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
            if sum(cellfun(@(x) ~isempty(x),diagnosticAnswerTest)) >= diagnosticNumberNeeded(qq) && MigraineWithOtherAuraFlag(thisSubject)
                if verbose
                    fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' passed multiCriterionQuestion #' num2str(qq) ' for the second criterion for migraine with other aura!\n']);
                end
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
    
    
    %% Migrane without aura
    % To qualify for migraine without aura, the candidate must not have
    %  received a diagnosis of Migraine with visual aura or Migraine with
    %  other aura (Q1, Q3). They then must meet these criteria:
    %       1) give a specific set of yes/no responses (Q4, Q7)
    %       2) endorse 2/4 from symptom list 1 (Q5)
    %       3) endorse 1/3 from symptom list 2 (Q6)
    
    if ~MigraineWithVisualAuraFlag(thisSubject) && ~MigraineWithOtherAuraFlag(thisSubject)
        
        % Define the binary questions and the diagnostic responses
        binaryQuestions={'Do you get headaches?',...
            'Do you get headaches or episodes of eye or face discomfort that are NOT caused by a head injury, hangover, or illness such as the cold or the flu?',...
            'Do your headaches or discomfort episodes ever last more than 4 hours?',...
            'Have you had these headaches or discomfort episodes 5 or more times in your life?'};
        diagnosticResponses={'Yes','Yes','Yes','Yes'};
        
        % Test if there is a column in the table for each question
        questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryQuestions);
        
        % QuestionExist will all be true if a column was found for each question
        if all(questionExist)
            % Identify which columns of the table contain the relevant questions.
            questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryQuestions);
            % determine if these columns contain the diagnostic responses
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
            if sum(diagnosticAnswerTest) == length(diagnosticAnswerTest) && MigraineWithoutAuraFlag(thisSubject)
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
    % Define the binary questions and the diagnostic response patterns (Q1, Q3, Q39, Q40, Q41)
    binaryCriterionQuestions={'Do you get headaches?',...
        'Do you get headaches or episodes of eye or face discomfort that are NOT caused by a head injury, hangover, or illness such as the cold or the flu?',...
        'Have you ever had a headache?',...
        'Do you get headaches or episodes of eye or face discomfort that are NOT caused by a head injury, hangover, or illness like the cold or flu?',...
        'Have you ever had episodes of discomfort, pressure, or pain around your eyes or face?'};
    clear diagnosticResponses
    %For this section, binaryCriterionQuestions correspond to diagnosticResponses' columns (not rows)
    diagnosticResponses(1,:) = {'No','','No','','No'};
    diagnosticResponses(2,:) = {'No','','Yes','No','No'};
    diagnosticResponses(3,:) = {'Yes','No','','','No'};
    
    % Test if there is a column in the table for each question
    % KNOWN BUG - If no subjects have followed a path resulting in
    % responses in one or more of the criterion questions, then the test
    % for headache free status will be skipped for every subject!
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryCriterionQuestions);
    
    % QuestionExist will all be true if a column was found for each question
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
        %       meet formal criteria for migraine with aura (Q8, Q23)
        % 3. endorses any of the migraine characteristics of sensory
        %       sensivity, nausea/vomitting, exacerbation with activity (Q6, Q51, Q52)
        multiCriterionQuestions={'Do your headaches or discomfort episodes ever last more than 4 hours?',...
            'Around the time of your headaches or discomfort episodes, have you ever seen any of the following? (check all that apply)',...
            'Have you ever had any of the following happen around the time of your headaches or discomfort episodes? (check all that apply)',...
            'During headaches or discomfort episodes that last longer than 4 hours, do you ever experience the following symptoms? Please check all that apply.',...
            'For your WORST type of headache or discomfort episode, do any of the following statements describe your pain and symptoms? Please check all that apply.',...
            'During your WORST type of headache or discomfort episode, do you ever experience the following symptoms? Please check all that apply.'};
        
        exclusionNumberNeeded=[1,1,1,1,1,1];
        clear exclusionAnswers
        exclusionAnswers(1,:) ={'Yes','','','','','',''};
        exclusionAnswers(2,:) ={'Spots','Stars','Lines','Flashing lights','Zigzag lines','Heat waves','Vision loss'};
        exclusionAnswers(3,:) ={'Numbness of your body or face','Tingling of your body or face','','','','',''};
        exclusionAnswers(4,:) ={'Nausea and/or vomiting','Sensitivity to light','Sensitivity to sound','','','',''};
        exclusionAnswers(5,:) ={'The pain is pounding, pulsating, or throbbing','The pain is moderate or severe in intensity','The pain is made worse by routine activities such as walking or climbing stairs','','','',''};
        exclusionAnswers(6,:) ={'Nausea and/or vomiting','Sensitivity to light','Sensitivity to sound','','','',''};
        
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
    % responses out of seven. (Q29, Q31, Q33, Q35, Q37, Q39, Q41)
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
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryCriterionQuestions);
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        % Test if any of these columns are empty. If so, this subject has
        % not completed the Choi survey and is assigned a NaN score
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);
        if any(emptyAnswerTest)
            ChoiIctalPhotophobiaScore(thisSubject) = nan;
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
    % mild (3–5), moderate (6–8), and severe (>=9). (Q118 - Q129)
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
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, multiCriterionQuestions);
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), multiCriterionQuestions);
        % Test if any of these columns are empty. If so, this subject has
        % not completed the ASC-12 survey and is assigned a NaN score
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyAnswers);
        if any(emptyAnswerTest)
            IctalAllodyniaScore(thisSubject) = nan;
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
    %  (Q47)
    binaryCriterionQuestions={'When was the last time you had these vision changes?'};
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
            RecencyVisualAura(thisSubject) = {''};
        else
            % Copy over the response string
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
            RecencyVisualAura(thisSubject) = table2cell(T(thisSubject,questionColumnIdx));
        end % binary test
    else
        % If no subject has answered the headache recency question, then
        % make sure that all entries continue to be empty
        RecencyVisualAura(thisSubject) = {''};
    end
    
    
    %% Question regarding errors or seriousness
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
            SeriousnessQuestion(thisSubject) = {''};
        else
            % Copy over the response string
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
            SeriousnessQuestion(thisSubject) = table2cell(T(thisSubject,questionColumnIdx));
        end % binary test
    else
        % If no subject has answered the family history question, then
        % make sure that all entries continue to be empty
        SeriousnessQuestion(thisSubject) = {''};
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
    ChildhoodMotionSickness, ...
    FamHxOfHeadache, ...
    Ophthalmology, ...
    FrequencyMonthly, ...
    RecencyMigraine, ...
    RecencyVisualAura, ...
    RecencySensoryAura, ...
    RecencySpeakingAura, ...
    RecencyAnyAura, ...
    SeriousnessQuestion);
diagnosisTable.Properties.VariableNames=diagnoses;
diagnosisTable.Properties.RowNames=T.Properties.RowNames;


end % function



