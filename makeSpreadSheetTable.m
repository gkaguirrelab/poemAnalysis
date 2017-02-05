function [T, notesText] = makeSpreadSheetTable(spreadSheetName)
% function [T, notesText] = makeSpreadSheetTable(spreadSheetName)
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

subjectIDVarieties={'SubjectID_','SubjectName','SubjectNumber','SubjectID'};
subjectIDLabel='SubjectID';

%% Read in the table. Suppress some routine warnings.
warnID='MATLAB:table:ModifiedVarnames';
orig_state = warning;
warning('off',warnID);
T=readtable(spreadSheetName);
warning(orig_state);
tRows=size(T,1);  tColumns=size(T,2);

%% Clean and Sanity check the table

% Test if the first column just contains row index values, and if so remove
if strcmp(T.Properties.VariableNames{1},'x1')
    T.x1=[];
    tColumns=size(T,2);
end

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

% If a row lacks a subject ID, the values in the row are to be joined
% with values in the first row above that has a suject ID. This is because
% the Google spreadhseet will save a list of responses for an item as
% multiple rows in a column
idxRowsToJoin=find(ismissing(T.SubjectID));
if ~isempty(idxRowsToJoin)
    for ii=length(idxRowsToJoin):-1:1
        % Check that the concatenation is only for strings
        notEmptyColumns=find(~ismissing(T(idxRowsToJoin(ii),:)));
        if ~iscellstr(table2cell(T(idxRowsToJoin(ii),notEmptyColumns)))
            errorText=['Row ' strtrim(num2str(idxRowsToJoin(ii))) ' has no Subject ID and has non-string entries that cannot be concatenated with other rows.'];
            error(errorText);
        end
        % Loop over columns and join the strings into the row above
        for jj=1:length(notEmptyColumns)
            tableCellsToJoin = T(idxRowsToJoin(ii)-1:idxRowsToJoin(ii),notEmptyColumns(jj));
            joinedText=strjoin(table2cell(tableCellsToJoin),joinDelimiter);
            T{idxRowsToJoin(ii)-1,notEmptyColumns(jj)} = cellstr(joinedText);
        end
    end % Loop over rows to join
    % Remove the rows whose contents have been joined to rows with a subject ID
    T(idxRowsToJoin,:)=[];
    % Assemble the notesText
    warningText=['The text from rows ' num2str(idxRowsToJoin') ' was merged into the next row above.'];
    notesText=[notesText,cellstr(warningText)];
end % There are rows to join


% Find duplicate subject IDs and merge their data
[uniqueIDs,idxInUniqueOfTable,idxInTableOfUnique] = unique(T.SubjectID);
for ii=1:length(uniqueIDs)
    idxDuplicates=find(strcmp(T.SubjectID,uniqueIDs{ii}));
    if length(idxDuplicates) > 1
        % fill any missing values with non-missing values from other rows
        subT=T(idxDuplicates,:);
        subT=fillmissing(subT,'next');
        % Identify the most recent row entry for this subject ID
        mostRecentTimestamp=max(subT.Timestamp);
        rowIdx=find(subT.Timestamp==mostRecentTimestamp);
        % Update the master index to use the most recent row in building
        % the unique table
        idxInUniqueOfTable(ii)=idxDuplicates(rowIdx);
        % Check if there are any columns there have unequal values
        % (excluding the timestamp column)
        columnsToTest=find(~strcmp(T.Properties.VariableNames,'Timestamp'));
        notEqualFlag=0;
        badColumns=[];
        for jj=1:length(columnsToTest)
            [~,uniqueCount,~]=unique(subT(:,columnsToTest(jj)));
            if ~isequal(uniqueCount,1)
                notEqualFlag=1;
                badColumns=[badColumns,columnsToTest(jj)];
            end
        end
        % Build the warning notes
        warningText=[uniqueIDs{ii} ' has multiple entries. ' ...
            'Using values from timestamp entry ' datestr(subT.Timestamp(rowIdx)) '. '];
        if notEqualFlag
            warningText=[warningText 'Additionally, these columns have unequal values: ' ...
                strjoin(T.Properties.VariableNames(badColumns),joinDelimiter)];
        end % check if there were unequal values across rows
        notesText=[notesText,cellstr(warningText)];
    end % Duplicate subject IDs were found
end % Loop through the unique subject IDs
T=T(idxInUniqueOfTable,:);

% Assign subject ID as the row name property for the table
T.Properties.RowNames=T.SubjectID;

% Transpose the notesText for ease of subsequent display
notesText=notesText';

end % function