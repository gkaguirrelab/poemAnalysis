function [responseTable] = poemAnalysis_perception( T )
%
% This function takes the table variable "T" and extracts responses to
% some questions

numSubjects = size(T,1);

responseTypes={'zipFirstThree',...
    'foo',...
    'ageInYears'};

columnQuestionText={'What are the first three numbers of your zip-code? Example: If your zipcode is 19104, enter 191.',...
    'What is your age (in years)?'};


% Pull the QuestionText out of the table properties
QuestionText=T.Properties.UserData.QuestionText;

responseTable = table();
responseTable.SubjectID = T.SubjectID;


for thisSubject = 1:numSubjects
    for qq = 1:length(responseTypes)
        
        % Test if there is a column in the table for each question
        questionExist = cellfun(@(x) strcmp(columnQuestionText{qq},x), QuestionText);
        
        % QuestionExist will all be true of a column was found for each question
        if sum(questionExist)==1
            % Identify which columns of the table contain the relevant questions.
            questionColumnIdx = find(questionExist);
            % Copy over the response string
            responseTable(thisSubject,qq) = T(thisSubject,questionColumnIdx);
        end
    end
    
end % loop over subjects


responseTable.Properties.RowNames=T.Properties.RowNames;
responseTable.Properties.VariableNames = responseTypes;

end % function



