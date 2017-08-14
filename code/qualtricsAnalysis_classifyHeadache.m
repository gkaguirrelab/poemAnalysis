function [diagnosisTable] = qualtricsAnalysis_classifyHeadache( T )
%
% This function takes the table variable "T" and performs a decision tree
% analysis to classify each subject into headache categories.

numSubjects = size(T,1);

diagnoses={'MigraineWithoutAura',...
    'MigraineWithVisualAura',...
    'MigraineWithOtherAura',...
    'HeadacheFree',...
    'MildHeadache',...
    'HeadacheNOS',...
    'ChoiIctalPhotophobiaScore',...
    'ChildhoodMotionSickness',...
    'FamHxOfHeadache'};

% Pull the QuestionText out of the table properties
QuestionText=T.Properties.UserData.QuestionText;

% At the outset of processing, all subjects are candidates for all
% diagnoses. We set these flags to true.
MigraineWithoutAuraFlag=true(numSubjects, 1);
MigraineWithVisualAuraFlag=true(numSubjects, 1);
MigraineWithOtherAuraFlag=true(numSubjects, 1);
HeadacheFreeFlag=true(numSubjects, 1);
MildHeadacheFlag=true(numSubjects, 1);
HeadacheNOSFlag=true(numSubjects, 1);
% The Choi questions are a score; default to nan
ChoiIctalPhotohobiaScore=nan(numSubjects, 1);
% Family history and childhood motion sickness responses are 
% 'Yes', 'No', 'I don't know' or empty string; default to empty
ChildhoodMotionSickness = cell(numSubjects, 1);
FamHxOfHeadacheFlag = cell(numSubjects, 1);

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
        'Do you get headaches that are NOT caused by a head injury, hangover, or an illness such as the cold or the flu?',...
        'Have you ever seen any spots, stars, lines, flashing lights, zigzag lines, or heat waves around the time of your headaches?',...
        'Have you experienced these visual phenomena with your headaches two or more times in your life?',...
        'How long do these visual phenomena typically last?'};
    diagnosticResponses={'Yes','Yes','Yes','Yes','5 min to 1 hour'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryQuestions);
    
    % QuestionExist will all be true if a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryQuestions);
        % determine if these columns contain the diagnostic responses
        diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
        if sum(diagnosticAnswerTest) == length(diagnosticAnswerTest) && MigraineWithVisualAuraFlag(thisSubject)
            fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' met the first criterion for migraine with visual aura!\n']);
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
    clear diagnosticAnswers
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
                fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' met the second criterion for migraine with visual aura!\n']);
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
        'Have you experienced these phenomena with your headaches two or more times in your life?',...
        'How long do these phenomena typically last?'};
    diagnosticResponses={'Yes','Yes','Yes','5 min to 1 hour'};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryQuestions);
        % determine if these columns contain the diagnostic responses
        diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
        if sum(diagnosticAnswerTest) == length(diagnosticAnswerTest) && MigraineWithOtherAuraFlag(thisSubject)
            fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' met the first criterion for migraine with other aura!\n']);
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
    multiCriterionQuestions={'When do you experience these phenomena in relation to your headache? Please mark all that apply.', ...
        'Around the time of your headaches, have you ever had:'};
    diagnosticNumberNeeded=[1,1];
    clear diagnosticAnswers
    diagnosticAnswers(1,:) = {'Before the headache','',''};
    diagnosticAnswers(2,:) = {'Numbness or tingling of your body or face','Weakness of your arm, leg, face, or half of your body.','Difficulty speaking'};
    
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
                fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' passed multiCriterionQuestion #' num2str(qq) ' for the second criterion for migraine with other aura!\n']);
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
    %  other aura. They then must meet these criteria:
    %       1) give a specific set of yes/no responses
    %       2) endorse 2/4 from symptom list 1
    %       3) endorse 1/3 from symptom list 2
    
    if ~MigraineWithVisualAuraFlag(thisSubject) && ~MigraineWithOtherAuraFlag(thisSubject)
        
        % Define the binary questions and the diagnostic responses
        binaryQuestions={'Do you get headaches?',...
            'Do you get headaches that are NOT caused by a head injury, hangover, or an illness such as the cold or the flu?',...
            'Do your headaches ever last more than 4 hours?',...
            'Have you had this headache 5 or more times in your life?'};
        diagnosticResponses={'Yes','Yes','Yes','Yes'};
        
        % Test if there is a column in the table for each question
        questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryQuestions);
        
        % QuestionExist will all be true of a column was found for each question
        if all(questionExist)
            % Identify which columns of the table contain the relevant questions.
            questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryQuestions);
            % determine if these columns contain the diagnostic responses
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
            if sum(diagnosticAnswerTest) == length(diagnosticAnswerTest) && MigraineWithoutAuraFlag(thisSubject)
                fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' met the first criterion for migraine without aura!\n']);
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
        multiCriterionQuestions={'Do any of the following statements describing your pain and other symptoms apply to your headaches that are longer than 4 hours? Please mark all that apply.',...
            'During your headaches that are longer than 4 hours, do you ever experience the following symptoms? Please mark all that apply.'};
        diagnosticNumberNeeded=[2,1];
        clear diagnosticAnswers
        diagnosticAnswers(1,:) = {'The pain is worse on one side',...
            'The pain is pounding, pulsating, or throbbing',...
            'The pain is of moderate or severe intensity',...
            'The pain is made worse by routine activities such as walking or climbing stairs'};
        diagnosticAnswers(2,:) = {'Nausea or vomiting',...
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
                diagnosticAnswerTest=cellfun(@(x) strfind(answerString, x), diagnosticAnswers(qq,:));
                if sum(cellfun(@(x) ~isempty(x),diagnosticAnswerTest)) >= diagnosticNumberNeeded(qq) && MigraineWithoutAuraFlag(thisSubject)
                    fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' passed multiCriterionQuestion #' num2str(qq) ' for the second criterion for migraine without aura!\n']);
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
    % Define the binary questions and the diagnostic response patterns
    binaryCriterionQuestions={'Do you get headaches?',...
        'Do you get headaches that are NOT caused by a head injury, hangover, or an illness such as the cold or the flu?',...
        'Have you ever had a headache?',...
        'Have you ever had a headache that was NOT caused by a head injury, hangover, or an illness such as the cold or the flu?',...
        'Have you ever had episodes of discomfort, pressure, or pain around your eyes or sinuses?'};
    clear diagnosticResponses
    diagnosticResponses(1,:) = {'No','' ,'No','' ,'No'};
    diagnosticResponses(2,:) = {'No','' ,'Yes','No','No'};
    diagnosticResponses(3,:) = {'Yes','No','', '' ,'No'};
    
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
            fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' met the criterion for headache free!\n']);
        else
            HeadacheFreeFlag(thisSubject) = false;
        end % binary test
    else
        % If no subject has gone down this particular branch of the survey,
        % then one or more columns in the table may not be present for these
        % questions. If this is the case, mark the diagnosis as false.
        HeadacheFreeFlag(thisSubject) = false;
    end
    
    
    %% mildHeadache vs. HeadacheNOS
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
        % for MildHeadache
    
        % The first four multiCriterionQuestions derive from the
        % pathways that follow answering no to "Do you get headaches" or no
        % to "Do you get headaches that are not caused by ..."
        % The second XXX multiCriterionQuestions derive from the pathway
        % that begins with answering no to "do your headaches last longer
        % than 4 hours?".
        % We also explicity exclude from the mild headache diagnosis anyone
        % who reports that their headaches last longer than 4 hour.
        multiCriterionQuestions={...
        'Do your headaches ever last more than 4 hours?',...    
        'How would you describe this pain or discomfort?',...
        'How intense would you rate this pain or discomfort?',...
        'During these episodes, do you ever experience the following symptoms? Please mark all that apply.',...
        'Do you usually get headaches around your menstrual periods?',...
        'For your MOST SEVERE type of headache, do any of the following statements describe your pain and symptoms? Please mark all that apply.',...
        'During your MOST SEVERE headaches, do you ever experience the following symptoms? Please mark all that apply.',...
        'How would you describe your MOST SEVERE headaches?',...
        };
    
        exclusionNumberNeeded=[1,1,1,1,1,1,1,1];
        clear exclusionAnswers
        exclusionAnswers(1,:)={'Yes','',''};        
        exclusionAnswers(2,:)={'Throbbing pain','Stabbing Pain',''};
        exclusionAnswers(3,:)={'Moderate','Severe',''};
        exclusionAnswers(4,:)={'Nausea and/or vomiting','Sensitivity to light','Sensitivity to sound'};
        exclusionAnswers(5,:)={'Yes','',''};
        exclusionAnswers(6,:)={'The pain is pounding, pulsating, or throbbing','The pain is of moderate or severe intensity','The pain is made worse by routine activities such as walking or climbing stairs'};
        exclusionAnswers(7,:)={'Nausea or vomiting','Sensitivity to light','Sensitivity to noise'};
        exclusionAnswers(8,:)={'Throbbing pain','Stabbing Pain',''};
        
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
                if sum(cellfun(@(x) ~isempty(x),exclusionAnswerTest)) >= exclusionNumberNeeded(qq) && MildHeadacheFlag(thisSubject)
                    fprintf(['Subject ' T.Properties.RowNames{thisSubject} ' has an exclusionary criterion for MildHeadache!\n']);
                    MildHeadacheFlag(thisSubject) = false;
                end % symptom inventory test
            end % loop over symptom inventory tests
        else
            % No subject has gone down any branch of the survey that could
            % be used to evaluate for MildHeadache. Mark all subjects as
            % false for this diagnosis.
            MildHeadacheFlag(thisSubject) = false;
        end
        
        % If the subject has met criteria for MildHeadache, then set
        % HeadacheNOSFlag to false
        if MildHeadacheFlag(thisSubject)
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
        MildHeadacheFlag(thisSubject) = false;
    end
    
    %% Choi photophobia questions
    % The Choi (2009) survey consists of seven questions that assess
    % photophobia during migraine. The score is the number of 'yes'
    % responses out of seven.
    binaryCriterionQuestions={'During your headache, do you feel a greater sense of glare or dazzle in your eyes than usual by bright lights?',...
        'During your headache, do flickering lights, glare, specific colors or high contrast striped patterns bother you or your eyes?',...
        'During your headache, do you turn off the lights or draw a curtain to avoid bright conditions?',...
        'During your headache, do you have to wear sunglasses even in normal daylight?',...
        'During your headache, do bright lights hurt your eyes?',...
        'Is your headache worsened by bright lights?',...
        'Is your headache triggered by bright lights?'};
    clear diagnosticResponses
	diagnosticResponses={'Yes','Yes','Yes','Yes','Yes','Yes','Yes'};
    emptyResponses={'','','','','','',''};
    
    % Test if there is a column in the table for each question
    questionExist = cellfun(@(x) sum(strcmp(QuestionText,x))==1, binaryCriterionQuestions);
    
    % QuestionExist will all be true of a column was found for each question
    if all(questionExist)
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        % Test if any of these columns are empty. If so, this subject has
        % not completed the Choi survey and is assigned a NaN score
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);
        if any(emptyAnswerTest)
            ChoiIctalPhotohobiaScore(thisSubject) = nan;
        else
            % count how many of these columns contain the diagnostic responses
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
            ChoiIctalPhotohobiaScore(thisSubject) = sum(diagnosticAnswerTest);
        end % binary test
    else
        % If no subject has gone answered the Choi survey questions, then
        % one or more columns in the table may not be present for these
        % questions. If this is the case, mark Choi score as NaN.
        ChoiIctalPhotohobiaScore(thisSubject) = nan;
    end

    %% History of childhood motion sickness
    % The subject answers this if they did not go down a migraine path
    
    binaryCriterionQuestions={'Did you get motion sick easily as a child?'};
    emptyResponses={''};
    
    % Test if there is a single column in the table for this question
    questionExist = sum(strcmp(QuestionText,binaryCriterionQuestions{1}))==1;
    
    % QuestionExist will all be true of a column was found for each question
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
    % What was the subject response to the family history of headache q?
    
    binaryCriterionQuestions={'Do any of your first-degree relatives (parents, brothers, sisters, or children) get migraines?'};
    emptyResponses={''};
    
    % Test if there is a single column in the table for this question
    questionExist = sum(strcmp(QuestionText,binaryCriterionQuestions{1}))==1;
    
    % QuestionExist will all be true of a column was found for each question
    if questionExist
        % Identify which columns of the table contain the relevant questions.
        questionColumnIdx = cellfun(@(x) find(strcmp(QuestionText,x)), binaryCriterionQuestions);
        % Test if this column is empty. If so, this subject has
        % not completed the family history question (which should never
        % happen)
        emptyAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),emptyResponses);
        if any(emptyAnswerTest)
            FamHxOfHeadacheFlag(thisSubject) = {''};
        else
            % Copy over the response string
            diagnosticAnswerTest = strcmp(table2cell(T(thisSubject,questionColumnIdx)),diagnosticResponses);
            FamHxOfHeadacheFlag(thisSubject) = table2cell(T(thisSubject,questionColumnIdx));
        end % binary test
    else
        % If no subject has answered the family history question, then
        % make sure that all entries continue to be empty
        FamHxOfHeadacheFlag(thisSubject) = {''};
    end
    
    
end % loop over subjects

% Assemble diagnosisTable
diagnosisTable=table(MigraineWithoutAuraFlag, ...
    MigraineWithVisualAuraFlag, ...
    MigraineWithOtherAuraFlag, ...
    HeadacheFreeFlag, ...
    MildHeadacheFlag, ...
    HeadacheNOSFlag, ...
    ChoiIctalPhotohobiaScore, ...
    ChildhoodMotionSickness, ...
    FamHxOfHeadacheFlag);
diagnosisTable.Properties.VariableNames=diagnoses;
diagnosisTable.Properties.RowNames=T.Properties.RowNames;


end % function



