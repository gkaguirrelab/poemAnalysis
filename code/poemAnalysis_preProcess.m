function [T, notesText] = qualtricsAnalysis_preProcess(spreadSheetName, varargin)
% function [T, notesText] = qualtricsAnalysis_preProcess(spreadSheetName)
%
%  Loads csv file into which Qualtrics migraine assessment data has been
%  stored. Cleans and organizes the data
%
% Inputs:
%   spreadSheetName: String variable with the full path to the csv file
%
% Outputs:
%   T: The table
%   notesText: A cell array with notes regarding the table conversion
%

%% Parse input and define variables
p = inputParser;

% required input
p.addRequired('spreadSheetName',@ischar);

% Optional analysis params
p.addParameter('retainDuplicateSubjectIDs',false,@islogical);

% parse
p.parse(spreadSheetName,varargin{:})


%% Hardcoded variables and housekeeping
notesText=cellstr(spreadSheetName);

subjectIDVarieties={'ExternalReference'};
subjectIDLabel='SubjectID';

% This is the format of time stamps returned by Qualtrics
dateTimeFormatA='yyyy-MM-dd HH:mm:SS';
dateTimeFormatB='MM/dd/yy HH:mm';

%% Read in the table. Suppress some routine warnings.
warnID='MATLAB:table:ModifiedVarnames';
orig_state = warning;
warning('off',warnID);
T=readtable(spreadSheetName,'DatetimeType','text');
warning(orig_state);

%% Stick the question text into the UserData field of the Table
T.Properties.UserData.QuestionText=table2cell(T(1,:));

%% Clean and Sanity check the table
% Remove empty rows
T=rmmissing(T,'MinNumMissing',size(T,2));

% Remove empty columns
T=rmmissing(T,2,'MinNumMissing',size(T,1));

% Identify the column with the Subject ID, and standardize the label
for ii=1:length(T.Properties.VariableNames)
    idx=find(strcmp(subjectIDVarieties,T.Properties.VariableNames{ii}));
    if ~isempty(idx)
        T.Properties.VariableNames{ii}=subjectIDLabel;
    end
end

% Remove the first two rows, which are now junk column labels
T=T(3:end,:);

% Remove rows with empty subject ID
idxNotEmptySubjectIDs=cellfun(@(x) ~strcmp(x,''), T.SubjectID);
T=T(idxNotEmptySubjectIDs,:);

% Remove rows for which "Finished" is False
idxTrueFinishedStatus=cellfun(@(x) ~strcmp(x,'FALSE'), T.Finished);
T=T(idxTrueFinishedStatus,:);

% Check for duplicate subject ID names. There are two choices as to how to
% handle duplicates. The first option is to assign unique subjectID names
% to each duplicated original subjectID. The second option is to simply
% discard all duplicates except for the most recent set of responses for
% that subject.
uniqueSubjectIDs=unique(T.SubjectID);
k=cellfun(@(x) find(strcmp(T.SubjectID, x)==1), unique(T.SubjectID), 'UniformOutput', false);
duplicateSubjectIDsIdx=find(cellfun(@(x) x==2,cellfun(@(x) size(x,1),k,'UniformOutput', false)));

% We have detected duplicates. What should we do?
if ~isempty(duplicateSubjectIDsIdx)
    
    % Append index numbers to render duplicated subject IDs unique
    if p.Results.retainDuplicateSubjectIDs
        for ii=1:length(duplicateSubjectIDsIdx)
            SubjectIDText=uniqueSubjectIDs{duplicateSubjectIDsIdx(ii)};
            idx=find(strcmp(T.SubjectID,SubjectIDText));
            for jj=1:length(idx)
                T.SubjectID{idx(jj)}=[T.SubjectID{idx(jj)} '_' char(48+jj)];
            end
        end
        
    % Alternatively, delete rows that are duplicates, retaining only the
    % final set of responses for this subjectID
    % THIS IS A BAD HACK. IT CURRENTLY ONLY DISCARDS THE FIRST OF n
    % DUPLICATES. NEED TO RE-WRITE TO USE TIME THE TEST WAS TAKEN TO GUIDE
    % THIS.
    
    else
        for ii=1:length(duplicateSubjectIDsIdx)
            SubjectIDText=uniqueSubjectIDs{duplicateSubjectIDsIdx(ii)};
            idx=find(strcmp(T.SubjectID,SubjectIDText));
            idxToKeep = ((1:1:size(T,1)) ~= idx(1));
            T = T(idxToKeep,:);
        end
    end
end

% Assign subject ID as the row name property for the table
T.Properties.RowNames=T.SubjectID;

% Convert the timestamps to datetime format
timeStampLabels={'StartDate','EndDate'};
for ii=1:length(timeStampLabels)
    idx=find(strcmp(T.Properties.VariableNames,timeStampLabels{ii}));
    if ~isempty(idx)
        columnHeader = T.Properties.VariableNames(idx(1));
        cellTextTimetamp=table2cell(T(:,idx(1)));
        % Not sure what the format is of the date time string. Try one. If
        % error try the other. I am aware that this is an ugly hack.
        try
            tableDatetime=table(datetime(cellTextTimetamp,'InputFormat',dateTimeFormatA));
        catch
            tableDatetime=table(datetime(cellTextTimetamp,'InputFormat',dateTimeFormatB));
        end
        tableDatetime.Properties.VariableNames{1}=columnHeader{1};
        tableDatetime.Properties.RowNames=T.SubjectID;
        switch idx(1)
            case 1
                subTableRight=T(:,idx(1)+1:end);
                T=[tableDatetime subTableRight];
            case size(T,2)
                subTableLeft=T(:,1:idx(1)-1);
                T=[subTableLeft tableDatetime];
            otherwise
                subTableLeft=T(:,1:idx(1)-1);
                subTableRight=T(:,idx(1)+1:end);
                T=[subTableLeft tableDatetime subTableRight];
        end % switch
    end
end

% Transpose the notesText for ease of subsequent display
notesText=notesText';

end % function