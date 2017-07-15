function [T, notesText] = qualtricsAnalysis_preProcess(spreadSheetName)
% function [T, notesText] = qualtricsAnalysis_preProcess(spreadSheetName)
%
%  Loads Excel spreadsheets into which Google Sheets survey data has been
%  stored. Cleans and organizes the data
%
% Inputs:
%   spreadSheetName: String variable with the full path to the spreadsheet
%
% Outputs:
%   T: The table
%   notesText: A cell array with notes regarding the table conversion
%

%% Hardcoded variables and housekeeping
joinDelimiter='; ';
notesText=cellstr(spreadSheetName);

subjectIDVarieties={'Q20','SubjectID'};
subjectIDLabel='SubjectID';

% This is the format of time stamps returned by Qualtrics
dateTimeFormat='yyyy-MM-dd HH:mm:SS';

%% Read in the table. Suppress some routine warnings.
warnID='MATLAB:table:ModifiedVarnames';
orig_state = warning;
warning('off',warnID);
T=readtable(spreadSheetName,'DatetimeType','text');
warning(orig_state);
tRows=size(T,1);  tColumns=size(T,2);

%% Clean and Sanity check the table

% Remove the first two rows, which are junk column labels
T=T(3:end,:);
tRows=size(T,1);

% Remove empty rows
T=rmmissing(T,'MinNumMissing',tColumns);
tRows=size(T,1);

% Remove empty columns
T=rmmissing(T,2,'MinNumMissing',tRows);
tColumns=size(T,2);

% Identify the column with the Subject ID, and standardize the label
for ii=1:length(T.Properties.VariableNames)
    idx=find(strcmp(subjectIDVarieties,T.Properties.VariableNames{ii}));
    if ~isempty(idx)
        T.Properties.VariableNames{ii}=subjectIDLabel;
    end
end

% Remove rows with empty subject ID
idxNotEmptySubjectIDs=cellfun(@(x) ~strcmp(x,''), T.SubjectID);
T=T(idxNotEmptySubjectIDs,:);
tRows=size(T,1);

% Convert the timestamps to datetime format
timeStampLabels={'StartDate','EndDate'};

% Assign subject ID as the row name property for the table
T.Properties.RowNames=T.SubjectID;

for ii=1:length(timeStampLabels)
    idx=find(strcmp(T.Properties.VariableNames,timeStampLabels{ii}));
    if ~isempty(idx)
        columnHeader = T.Properties.VariableNames(idx(1));
        cellTextTimetamp=table2cell(T(:,idx(1)));
        tableDatetime=table(datetime(cellTextTimetamp,'InputFormat',dateTimeFormat));
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