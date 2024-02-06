function [T, notesText] = poemAnalysis_preProcess_v3(spreadSheetName, varargin)
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

% parse
p.parse(spreadSheetName,varargin{:})


%% Hardcoded variables and housekeeping
notesText=cellstr(spreadSheetName);

% This is the format of time stamps returned by Qualtrics
dateTimeFormatA='yyyy-MM-dd HH:mm:SS';
dateTimeFormatB='MM/dd/yy HH:mm';

%% Read in the table. Suppress some routine warnings.
warning('off','MATLAB:table:ModifiedAndSavedVarnames');
warning('off','MATLAB:table:ModifiedVarnames');
T=readtable(spreadSheetName);

%% Clean the table
% replace variable names, and switch data to categorical


T.Properties.VariableNames = {'StartDate','EndDate','Status','IPAddress','Progress','DurationToCompleteSec',...
    'Finished','RecordedDate','ResponseID','LastName','FirstName','Email','ExternalReference','LocationLatitude',...
    'LocationLongitude','DistributionChannel','UserLanguage','Q_RecaptchaScore','Age','Zip','RaceEth','AIAN','AIANtxt',...
    'AIANtribe','AIANtribe_txt','Asian','Asian_txt','Black','Black_txt','Hispanic','Hispanic_txt','MENA','MENA_txt',...
    'NHPI','NHPI_txt','White','White_txt','RaceEth_txt','GenderID','GenderID2','GenderID_txt','SAAB','SAAB_txt','SO',...
    'SO2','SO_txt','HA_yn','unprovokedHA_yn','MigCritB','MigCritC','MigCritD','MigCritC2','MigCritD2','MigCritA',...
    'MigFreq','MigRecent','VisAura','SensAura','SpeechAura','MultiSxAura_sametime','VisAura2orMore','VisAuraHArelation',...
    'VisAuraRecent','VisAuraDur','VisAuraUni','VisAuraSpread','VisAuraDur_yn','SensAura2orMore','SensAuraHArelation',...
    'SensAuraRecent','SensAuraDur','SensAuraUni','SensAuraSpread','SensAuraDur_yn','SpeechAura2orMore','SpeechAuraHArelation','SpeechAuraHArecent'...
    'SpeechAuraDur','SpeechAuraDur_yn','menstrualMig','CAMS','contHA','contHAsomeBreaks','HAmissedWork3mo','HAimpactWork3mo','HAmissedHousework3mo',...
    'HAimpactHousework3mo','HAmissedSocial3mo','HAdays3mo','SeverityHA','MotionSick','MigFamHx','Choi_HA','Choi_Dizzy','Choi_EyeStrain',...
    'Choi_BlurryVision','Choi_LightIntolerant','Choi_Anxiety','Fluorescent','Flicker','Headlight','OutdoorGlare','Screen','Sunlight',...
    'FlickeringTrees','LightSensitivity','SunglassesSunlight','SunglassesIndoors','SeekDarkness','LightTvLimit','LightDeviceLimit',...
    'LightShopsLimit','LightDriveLimit','LightWorkLimit','LightOutdoorLimit','AllodyniaComb','AllodyniaPonytail','AllodyniaShave',...
    'AllodyniaEyeGlasses','AllodyniaContacts','AllodyniaEarrings','AllodyniaNecklace','AllodyniaTightClothes','AllodyniaShower',...
    'AllodyniaPillow','AllodyniaHeat','AllodyniaCold','AllodyniaNoHA','AnsCorrect','Research','AllodyniaComb_noHA','AllodyniaPonytail_noHA',...
    'AllodyniaShave_noHA','AllodyniaEyeGlasses_noHA','AllodyniaContacts_noHA','AllodyniaEarrings_noHA','AllodyniaNecklace_noHA','AllodyniaTightClothes_noHA',...
    'AllodyniaShower_noHA','AllodyniaPillow_noHA','AllodyniaHeat_noHA','AllodyniaCold_noHA','everHA','everDiscomfort'};

% Remove empty rows
T=rmmissing(T,'MinNumMissing',size(T,2));

% Remove empty columns
T=rmmissing(T,2,'MinNumMissing',size(T,1));

% Convert categories to categorical
T.UserLanguage = categorical(T.UserLanguage); T.RaceEth = categorical(T.RaceEth); T.GenderID = categorical(T.GenderID); T.SAAB = categorical(T.SAAB); 
T.SO = categorical(T.SO);

% Organize Migraine ICHD-3 criteria
T.migICHD_A = zeros(height(T),1);
T.migICHD_A(categorical(T.MigCritA)=='Yes') = 1;
T.migICHD_B = zeros(height(T),1);
T.migICHD_B(categorical(T.MigCritB)=='Yes') = 1;
T.migICHD_C1 = zeros(height(T),1);
T.migICHD_C1(contains(string(T.MigCritC),'worse on one side')==1) = 1;
T.migICHD_C2 = zeros(height(T),1);
T.migICHD_C2(contains(string(T.MigCritC),'pounding, pulsating, or throbbing')==1) = 1;
T.migICHD_C3 = zeros(height(T),1);
T.migICHD_C3(contains(string(T.MigCritC),'moderate or severe in intensity')==1) = 1;
T.migICHD_C4 = zeros(height(T),1);
T.migICHD_C4(contains(string(T.MigCritC),'made worse by routine activities')==1) = 1;
T.migICHD_C = sum([T.migICHD_C1 T.migICHD_C2 T.migICHD_C3 T.migICHD_C4],2);
T.migICHD_Dp = zeros(height(T),1);
T.migICHD_Dp(contains(string(T.MigCritD),'Sensitivity to light')==1 & contains(string(T.MigCritD),'Sensitivity to sound')==1) = 1;
T.migICHD_Dnv = zeros(height(T),1);
T.migICHD_Dnv(contains(string(T.MigCritD),'Nausea and/or vomiting')==1) = 1;
T.migICHD_D = zeros(height(T),1);
T.migICHD_D(T.migICHD_Dp==1|T.migICHD_Dnv==1) = 1;

% Organize Migraine Aura ICHD-3 criteria
T.visAuraICHD_A = zeros(height(T),1);
T.visAuraICHD_A(categorical(T.VisAura2orMore)=='Yes') = 1;
T.sensAuraICHD_A = zeros(height(T),1);
T.sensAuraICHD_A(categorical(T.SensAura2orMore)=='Yes') = 1;
T.speechAuraICHD_A = zeros(height(T),1);
T.speechAuraICHD_A(categorical(T.SpeechAura2orMore)=='Yes' & (contains(string(T.SpeechAura),'Trouble saying words')==1|contains(string(T.SpeechAura),'Unable to speak')==1)) = 1;
T.visAuraICHD_C1 = zeros(height(T),1);
T.visAuraICHD_C1(categorical(T.VisAuraSpread)=='Yes') = 1;
T.sensAuraICHD_C1 = zeros(height(T),1);
T.sensAuraICHD_C1(categorical(T.SensAuraSpread)=='Yes') = 1;
T.AuraICHD_C2 = zeros(height(T),1);
T.AuraICHD_C2(contains(string(T.MultiSxAura_sametime),'No')==1) = 1;
T.visAuraICHD_C3 = zeros(height(T),1);
T.visAuraICHD_C3(categorical(T.VisAuraDur_yn)=='Yes') = 1;
T.sensAuraICHD_C3 = zeros(height(T),1);
T.sensAuraICHD_C3(categorical(T.SensAuraDur_yn)=='Yes') = 1;
T.speechAuraICHD_C3 = zeros(height(T),1);
T.speechAuraICHD_C3(categorical(T.SpeechAuraDur_yn)=='Yes') = 1;
T.visAuraICHD_C4 = zeros(height(T),1);
T.visAuraICHD_C4(categorical(T.VisAuraUni)=='Yes') = 1;
T.sensAuraICHD_C4 = zeros(height(T),1);
T.sensAuraICHD_C4(categorical(T.SensAuraUni)=='Yes') = 1;
T.speechAuraICHD_C4 = zeros(height(T),1);
T.speechAuraICHD_C4(contains(string(T.SpeechAura),'Unable to speak')==1) = 1;
T.visAuraICHD_C5 = zeros(height(T),1);
T.visAuraICHD_C5(contains(string(T.VisAura),'Zigzag lines')==1|contains(string(T.VisAura),'Spots')==1|contains(string(T.VisAura),'Stars')==1|...
    contains(string(T.VisAura),'Flashing lights')==1|contains(string(T.VisAura),'Lines')==1|contains(string(T.VisAura),'Heat waves')==1) = 1;
T.sensAuraICHD_C5 = zeros(height(T),1);
T.sensAuraICHD_C5(contains(string(T.SensAura),'Tingling')==1) = 1;
T.visAuraICHD_C6 = zeros(height(T),1);
T.visAuraICHD_C6(contains(string(T.VisAuraHArelation),'Before the headache')==1|contains(string(T.VisAuraHArelation),'During the headache')==1) = 1;
T.sensAuraICHD_C6 = zeros(height(T),1);
T.sensAuraICHD_C6(contains(string(T.SensAuraHArelation),'Before the headache')==1|contains(string(T.SensAuraHArelation),'During the headache')==1) = 1;
T.speechAuraICHD_C6 = zeros(height(T),1);
T.speechAuraICHD_C6(contains(string(T.SpeechAuraHArelation),'Before the headache')==1|contains(string(T.SpeechAuraHArelation),'During the headache')==1) = 1;

% organize pseudo MIDAS scores
T.MIDAS1 = zeros(height(T),1);
T.MIDAS1(contains(string(T.HAmissedWork3mo),'4 - 11 days')==1) = 7;
T.MIDAS1(contains(string(T.HAmissedWork3mo),'12 - 24 days')==1) = 18;
T.MIDAS1(contains(string(T.HAmissedWork3mo),'25 - 48 days')==1) = 36;
T.MIDAS1(contains(string(T.HAmissedWork3mo),'49 - 72 days')==1) = 60;
T.MIDAS1(contains(string(T.HAmissedWork3mo),'73 - 89 days')==1) = 81;
T.MIDAS1(contains(string(T.HAmissedWork3mo),'90+ days')==1) = 90;
T.MIDAS2 = zeros(height(T),1);
T.MIDAS2(contains(string(T.HAimpactWork3mo),'4 - 11 days')==1) = 7;
T.MIDAS2(contains(string(T.HAimpactWork3mo),'12 - 24 days')==1) = 18;
T.MIDAS2(contains(string(T.HAimpactWork3mo),'25 - 48 days')==1) = 36;
T.MIDAS2(contains(string(T.HAimpactWork3mo),'49 - 72 days')==1) = 60;
T.MIDAS2(contains(string(T.HAimpactWork3mo),'73 - 89 days')==1) = 81;
T.MIDAS2(contains(string(T.HAimpactWork3mo),'90+ days')==1) = 90;
T.MIDAS3 = zeros(height(T),1);
T.MIDAS3(contains(string(T.HAmissedHousework3mo),'4 - 11 days')==1) = 7;
T.MIDAS3(contains(string(T.HAmissedHousework3mo),'12 - 24 days')==1) = 18;
T.MIDAS3(contains(string(T.HAmissedHousework3mo),'25 - 48 days')==1) = 36;
T.MIDAS3(contains(string(T.HAmissedHousework3mo),'49 - 72 days')==1) = 60;
T.MIDAS3(contains(string(T.HAmissedHousework3mo),'73 - 89 days')==1) = 81;
T.MIDAS3(contains(string(T.HAmissedHousework3mo),'90+ days')==1) = 90;
T.MIDAS4 = zeros(height(T),1);
T.MIDAS4(contains(string(T.HAimpactHousework3mo),'4 - 11 days')==1) = 7;
T.MIDAS4(contains(string(T.HAimpactHousework3mo),'12 - 24 days')==1) = 18;
T.MIDAS4(contains(string(T.HAimpactHousework3mo),'25 - 48 days')==1) = 36;
T.MIDAS4(contains(string(T.HAimpactHousework3mo),'49 - 72 days')==1) = 60;
T.MIDAS4(contains(string(T.HAimpactHousework3mo),'73 - 89 days')==1) = 81;
T.MIDAS4(contains(string(T.HAimpactHousework3mo),'90+ days')==1) = 90;
T.MIDAS5 = zeros(height(T),1);
T.MIDAS5(contains(string(T.HAmissedSocial3mo),'4 - 11 days')==1) = 7;
T.MIDAS5(contains(string(T.HAmissedSocial3mo),'12 - 24 days')==1) = 18;
T.MIDAS5(contains(string(T.HAmissedSocial3mo),'25 - 48 days')==1) = 36;
T.MIDAS5(contains(string(T.HAmissedSocial3mo),'49 - 72 days')==1) = 60;
T.MIDAS5(contains(string(T.HAmissedSocial3mo),'73 - 89 days')==1) = 81;
T.MIDAS5(contains(string(T.HAmissedSocial3mo),'90+ days')==1) = 90;
T.MIDAS_score = sum([T.MIDAS1 T.MIDAS2 T.MIDAS3 T.MIDAS4 T.MIDAS5],2);

% Organize Allodynia scores
T.allodynia1 = zeros(height(T),1);
T.allodynia1(contains(string(T.AllodyniaComb),'Less than half the time')==1|contains(string(T.AllodyniaComb_noHA),'Less than half the time')==1) = 1;
T.allodynia1(contains(string(T.AllodyniaComb),'Half the time or more')==1|contains(string(T.AllodyniaComb_noHA),'Half the time or more')==1) = 2;
T.allodynia2 = zeros(height(T),1);
T.allodynia2(contains(string(T.AllodyniaPonytail),'Less than half the time')==1|contains(string(T.AllodyniaPonytail_noHA),'Less than half the time')==1) = 1;
T.allodynia2(contains(string(T.AllodyniaPonytail),'Half the time or more')==1|contains(string(T.AllodyniaPonytail_noHA),'Half the time or more')==1) = 2;
T.allodynia3 = zeros(height(T),1);
T.allodynia3(contains(string(T.AllodyniaShave),'Less than half the time')==1|contains(string(T.AllodyniaShave_noHA),'Less than half the time')==1) = 1;
T.allodynia3(contains(string(T.AllodyniaShave),'Half the time or more')==1|contains(string(T.AllodyniaShave_noHA),'Half the time or more')==1) = 2;
T.allodynia4 = zeros(height(T),1);
T.allodynia4(contains(string(T.AllodyniaEyeGlasses),'Less than half the time')==1|contains(string(T.AllodyniaEyeGlasses_noHA),'Less than half the time')==1) = 1;
T.allodynia4(contains(string(T.AllodyniaEyeGlasses),'Half the time or more')==1|contains(string(T.AllodyniaEyeGlasses_noHA),'Half the time or more')==1) = 2;
T.allodynia5 = zeros(height(T),1);
T.allodynia5(contains(string(T.AllodyniaContacts),'Less than half the time')==1|contains(string(T.AllodyniaContacts_noHA),'Less than half the time')==1) = 1;
T.allodynia5(contains(string(T.AllodyniaContacts),'Half the time or more')==1|contains(string(T.AllodyniaContacts_noHA),'Half the time or more')==1) = 2;
T.allodynia6 = zeros(height(T),1);
T.allodynia6(contains(string(T.AllodyniaEarrings),'Less than half the time')==1|contains(string(T.AllodyniaEarrings_noHA),'Less than half the time')==1) = 1;
T.allodynia6(contains(string(T.AllodyniaEarrings),'Half the time or more')==1|contains(string(T.AllodyniaEarrings_noHA),'Half the time or more')==1) = 2;
T.allodynia7 = zeros(height(T),1);
T.allodynia7(contains(string(T.AllodyniaNecklace),'Less than half the time')==1|contains(string(T.AllodyniaNecklace_noHA),'Less than half the time')==1) = 1;
T.allodynia7(contains(string(T.AllodyniaNecklace),'Half the time or more')==1|contains(string(T.AllodyniaNecklace_noHA),'Half the time or more')==1) = 2;
T.allodynia8 = zeros(height(T),1);
T.allodynia8(contains(string(T.AllodyniaTightClothes),'Less than half the time')==1|contains(string(T.AllodyniaTightClothes_noHA),'Less than half the time')==1) = 1;
T.allodynia8(contains(string(T.AllodyniaTightClothes),'Half the time or more')==1|contains(string(T.AllodyniaTightClothes_noHA),'Half the time or more')==1) = 2;
T.allodynia9 = zeros(height(T),1);
T.allodynia9(contains(string(T.AllodyniaShower),'Less than half the time')==1|contains(string(T.AllodyniaShower_noHA),'Less than half the time')==1) = 1;
T.allodynia9(contains(string(T.AllodyniaShower),'Half the time or more')==1|contains(string(T.AllodyniaShower_noHA),'Half the time or more')==1) = 2;
T.allodynia10 = zeros(height(T),1);
T.allodynia10(contains(string(T.AllodyniaPillow),'Less than half the time')==1|contains(string(T.AllodyniaPillow_noHA),'Less than half the time')==1) = 1;
T.allodynia10(contains(string(T.AllodyniaPillow),'Half the time or more')==1|contains(string(T.AllodyniaPillow_noHA),'Half the time or more')==1) = 2;
T.allodynia11 = zeros(height(T),1);
T.allodynia11(contains(string(T.AllodyniaHeat),'Less than half the time')==1|contains(string(T.AllodyniaHeat_noHA),'Less than half the time')==1) = 1;
T.allodynia11(contains(string(T.AllodyniaHeat),'Half the time or more')==1|contains(string(T.AllodyniaHeat_noHA),'Half the time or more')==1) = 2;
T.allodynia12 = zeros(height(T),1);
T.allodynia12(contains(string(T.AllodyniaCold),'Less than half the time')==1|contains(string(T.AllodyniaCold_noHA),'Less than half the time')==1) = 1;
T.allodynia12(contains(string(T.AllodyniaCold),'Half the time or more')==1|contains(string(T.AllodyniaCold_noHA),'Half the time or more')==1) = 2;
T.allodynia_score = sum([T.allodynia1 T.allodynia2 T.allodynia3 T.allodynia4 T.allodynia5 T.allodynia6 T.allodynia7 T.allodynia8 T.allodynia9 T.allodynia10...
    T.allodynia11 T.allodynia12],2);

% Specific symptoms
T.visZigzag = zeros(height(T),1);
T.visZigzag(contains(string(T.VisAura),'Zigzag lines')==1) = 1;
T.visFlash = zeros(height(T),1);
T.visFlash(contains(string(T.VisAura),'Flashing lights')==1) = 1;
T.visHeatWaves = zeros(height(T),1);
T.visHeatWaves(contains(string(T.VisAura),'Heat waves')==1) = 1;
T.visStars = zeros(height(T),1);
T.visStars(contains(string(T.VisAura),'Stars')==1) = 1;
T.visSpots = zeros(height(T),1);
T.visSpots(contains(string(T.VisAura),'Spots')==1) = 1;
T.visLines = zeros(height(T),1);
T.visLines(contains(string(T.VisAura),'Lines')==1) = 1;
T.visLoss = zeros(height(T),1);
T.visLoss(contains(string(T.VisAura),'Vision loss')==1) = 1;
%% Sanity check the table

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