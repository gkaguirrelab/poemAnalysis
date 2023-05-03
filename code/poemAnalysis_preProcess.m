function [T, notesText] = poemAnalysis_preProcess(spreadSheetName, varargin)
% Cleans and organizes data from a raw POEM responses spreadsheet
%
% Syntax:
%  [T, notesText] = qualtricsAnalysis_preProcess(spreadSheetName)
%
% Description:
%   Loads csv file into which Qualtrics migraine assessment data has been
%   stored. Cleans and organizes the data
%
% Inputs:
%   spreadSheetName       - String variable with the full path to the csv file
%
% Optional key/value pairs:
%   retainDuplicateSubjectIDs - Flag that controls how dupicate subject IDs
%                           should be handled. If set to false, only the
%                           most recent (by date) response for this subject
%                           ID will be retained.
%
% Outputs:
%   T                     - The table
%   notesText             - A cell array with notes regarding the table conversion
%

%% Parse input and define variables
p = inputParser;

% required input
p.addRequired('spreadSheetName',@ischar);

% Optional analysis params
p.addParameter('retainDuplicateSubjectIDs',true,@islogical);
p.addParameter('formatString','',@(x)(isempty(x) | ischar(x)));

% parse
p.parse(spreadSheetName,varargin{:})


%% Hardcoded variables and housekeeping
notesText=cellstr(spreadSheetName);

subjectIDQuestionText={'External Data Reference'};
subjectIDLabel='SubjectID';
emailAddressQuestionText = {'Please provide an email address at which we can contact you.','Please enter a contact email address:','Recipient Email'};
responseIDQuestionText = {'Response ID'};

% This is the format of time stamps returned by Qualtrics
dateTimeFormatA='yyyy-MM-dd HH:mm:SS';
dateTimeFormatB='MM/dd/yy HH:mm';

%% Read in the table. Suppress some routine warnings.
orig_state = warning;
warning('off','MATLAB:table:ModifiedAndSavedVarnames');
warning('off','MATLAB:table:ModifiedVarnames');
if isempty(p.Results.formatString)
    T=readtable(spreadSheetName,'DatetimeType','text','Format','auto');
else
    T=readtable(spreadSheetName,'DatetimeType','text','Format',p.Results.formatString);
end
warning(orig_state);

%% Stick the question text into the UserData field of the Table
T.Properties.UserData.QuestionText=table2cell(T(1,:));

%% Clean and Sanity check the table
% Remove empty rows
T=rmmissing(T,'MinNumMissing',size(T,2));

% Remove empty columns
T=rmmissing(T,2,'MinNumMissing',size(T,1));

% Identify the column with the Subject ID, and standardize the label
for ii=1:length(T.Properties.UserData.QuestionText)
    idx=find(strcmp(subjectIDQuestionText,T.Properties.UserData.QuestionText{ii}));
    if ~isempty(idx)
        T.Properties.VariableNames{ii}=subjectIDLabel;
        subjectIDColumnIdx = ii;
    end
end

% If there is an email address field, then we are dealing with a survey
% version of the POEM (i.e., v1.Xs). In this case, the email address field
% should be used as the subject ID. We copy over the email and over-write
% the contents of the external reference field, which should be empty. The
% order of preference in setting the subject ID is that explicit subject ID
% declaration takes precedence over email address
emailAddressColumnIdx = [];
for ii=1:length(T.Properties.UserData.QuestionText)
    idx=find(strcmp(emailAddressQuestionText,T.Properties.UserData.QuestionText{ii}));
    if ~isempty(idx)
        % Test to make sure that the current entries in the subject ID
        % column are indeed empty
        emptyIdx = cellfun(@(x) isempty(x),T{3:end,subjectIDColumnIdx});
        if any(emptyIdx)
            T(find(emptyIdx)+2,subjectIDColumnIdx)=T(find(emptyIdx)+2,ii);
            emailAddressColumnIdx = ii;
        end
    end
end

% Detect if we are dealing with a table of simulated survey responses. If
% so, every email address is the same, so set the emailAddressColumnIdx
% back to empty.
if ~isempty(emailAddressColumnIdx)
    if all(strcmp('testemail@qemailserver.com',table2array(T(3:end,subjectIDColumnIdx))))
        emailAddressColumnIdx = [];
    end
end

% At this stage if we still do not have a defined subject ID, we use
% Response ID instead
emptyIdx = cellfun(@(x) isempty(x),T{3:end,subjectIDColumnIdx});
if any(emptyIdx)
    idx=find(strcmp(T.Properties.UserData.QuestionText,responseIDQuestionText));
    if ~isempty(idx)
        T(find(emptyIdx)+2,subjectIDColumnIdx)=T(find(emptyIdx)+2,idx);
    end
end

% Remove the first two rows, which are now junk column labels
T=T(3:end,:);

% Remove rows with empty subject ID
idxNotEmptySubjectIDs=cellfun(@(x) ~strcmp(x,''), T.SubjectID);
T=T(idxNotEmptySubjectIDs,:);

% Remove rows for which "Finished" is False
idxTrueFinishedStatus=cellfun(@(x) ~strcmpi(x,'FALSE'), T.Finished);
T=T(idxTrueFinishedStatus,:);

% Check for duplicate subject ID names. There are two choices as to how to
% handle duplicates. The first option is to assign unique subjectID names
% to each duplicated original subjectID. The second option is to simply
% discard all duplicates except for the most recent set of responses for
% that subject.
uniqueSubjectIDs=unique(T.SubjectID);
k=cellfun(@(x) find(strcmp(T.SubjectID, x)==1), unique(T.SubjectID), 'UniformOutput', false);
replicateSubjectIDsIdx=find(cellfun(@(x) x>1,cellfun(@(x) size(x,1),k,'UniformOutput', false)));

% We have detected duplicates. What should we do?
if ~isempty(replicateSubjectIDsIdx)
    
    % Append index numbers to render duplicated subject IDs unique
    if p.Results.retainDuplicateSubjectIDs
        for ii=1:length(replicateSubjectIDsIdx)
            SubjectIDText=uniqueSubjectIDs{replicateSubjectIDsIdx(ii)};
            subjectIDColumn=find(strcmp(T.SubjectID,SubjectIDText));
            for jj=1:length(subjectIDColumn)
                T.SubjectID{subjectIDColumn(jj)}=[T.SubjectID{subjectIDColumn(jj)} '___' char(48+jj)];
            end
        end
        
    % Alternatively, delete rows that are duplicates, retaining only the
    % final set of responses for this subjectID
    % THIS IS A BAD HACK. IT CURRENTLY ONLY DISCARDS THE FIRST OF n
    % DUPLICATES. NEED TO RE-WRITE TO USE TIME THE TEST WAS TAKEN TO GUIDE
    % THIS.
    
    else
        for ii=1:length(replicateSubjectIDsIdx)
            SubjectIDText=uniqueSubjectIDs{replicateSubjectIDsIdx(ii)};
            subjectIDColumn=find(strcmp(T.SubjectID,SubjectIDText));
            idxToKeep = ((1:1:size(T,1)) ~= subjectIDColumn(1));
            T = T(idxToKeep,:);
        end
    end
end

% Assign subject ID as the row name property for the table
T.Properties.RowNames=T.SubjectID;

% Convert the timestamps to datetime format
timeStampLabels={'StartDate','EndDate'};
for ii=1:length(timeStampLabels)
    subjectIDColumn=find(strcmp(T.Properties.VariableNames,timeStampLabels{ii}));
    if ~isempty(subjectIDColumn)
        columnHeader = T.Properties.VariableNames(subjectIDColumn(1));
        cellTextTimetamp=table2cell(T(:,subjectIDColumn(1)));
        % Not sure what the format is of the date time string. Try one. If
        % error try the other. I am aware that this is an ugly hack.
        try
            tableDatetime=table(datetime(cellTextTimetamp,'InputFormat',dateTimeFormatA));
        catch
            tableDatetime=table(datetime(cellTextTimetamp,'InputFormat',dateTimeFormatB));
        end
        tableDatetime.Properties.VariableNames{1}=columnHeader{1};
        tableDatetime.Properties.RowNames=T.SubjectID;
        switch subjectIDColumn(1)
            case 1
                subTableRight=T(:,subjectIDColumn(1)+1:end);
                T=[tableDatetime subTableRight];
            case size(T,2)
                subTableLeft=T(:,1:subjectIDColumn(1)-1);
                T=[subTableLeft tableDatetime];
            otherwise
                subTableLeft=T(:,1:subjectIDColumn(1)-1);
                subTableRight=T(:,subjectIDColumn(1)+1:end);
                T=[subTableLeft tableDatetime subTableRight];
        end % switch
    end
end

% Transpose the notesText for ease of subsequent display
notesText=notesText';

end % function