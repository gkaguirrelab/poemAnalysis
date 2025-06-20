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

%% Read in the table. Suppress some routine warnings.
warning('off','MATLAB:table:ModifiedAndSavedVarnames');
warning('off','MATLAB:table:ModifiedVarnames');
T = readtable(spreadSheetName, 'ReadVariableNames', true);

%% Organize the table
% replace variable names, and switch data to categorical

if width(T)==144   
    T.Properties.VariableNames = {'StartDate','EndDate','Status','IPAddress','Progress','DurationToCompleteSec',...
        'Finished','RecordedDate','ResponseID','LastName','FirstName','Email','ExternalReference','LocationLatitude',...
        'LocationLongitude','DistributionChannel','UserLanguage','Q_RecaptchaScore','Age','Subject ID','RaceEth','AIAN','AIANtxt',...
        'AIANtribe','AIANtribe_txt','Asian','Asian_txt','Black','Black_txt','Hispanic','Hispanic_txt','MENA','MENA_txt',...
        'NHPI','NHPI_txt','White','White_txt','RaceEth_txt','GenderID','GenderID2','GenderID_txt','SAAB','SAAB_txt','SO',...
        'SO2','SO_txt','HA_yn','unprovokedHA_yn','MigCritB','MigCritC','MigCritD','MigCritC2','MigCritD2','MigCritA',...
        'MigFreq','MigRecent','VisAura','SensAura','SpeechAura','MultiSxAura_sametime','VisAura2orMore','VisAuraHArelation',...
        'VisAuraRecent','VisAuraDur','VisAuraUni','VisAuraSpread','VisAuraDur_yn','SensAura2orMore','SensAuraHArelation',...
        'SensAuraRecent','SensAuraDur','SensAuraUni','SensAuraSpread','SensAuraDur_yn','SpeechAura2orMore','SpeechAuraHArelation','SpeechAuraHArecent'...
        'SpeechAuraDur','SpeechAuraDur_yn','menstrualMig','CAMS','contHA','contHAsomeBreaks','HAmissedWork3mo','HAimpactWork3mo','HAmissedHousework3mo',...
        'HAimpactHousework3mo','HAmissedSocial3mo','HAdays3mo','SeverityHA','MotionSick','MigFamHx','Light_HA','Light_Dizzy','Light_EyeStrain',...
        'Light_BlurryVision','Light_LightIntolerant','Light_Anxiety','Fluorescent','Flicker','Headlight','OutdoorGlare','Screen','Sunlight',...
        'FlickeringTrees','LightSensitivity','SunglassesSunlight','SunglassesIndoors','SeekDarkness','LightTvLimit','LightDeviceLimit',...
        'LightShopsLimit','LightDriveLimit','LightWorkLimit','LightOutdoorLimit','AllodyniaComb','AllodyniaPonytail','AllodyniaShave',...
        'AllodyniaEyeGlasses','AllodyniaContacts','AllodyniaEarrings','AllodyniaNecklace','AllodyniaTightClothes','AllodyniaShower',...
        'AllodyniaPillow','AllodyniaHeat','AllodyniaCold','AllodyniaNoHA','AnsCorrect','Research','AllodyniaComb_noHA','AllodyniaPonytail_noHA',...
        'AllodyniaShave_noHA','AllodyniaEyeGlasses_noHA','AllodyniaContacts_noHA','AllodyniaEarrings_noHA','AllodyniaNecklace_noHA','AllodyniaTightClothes_noHA',...
        'AllodyniaShower_noHA','AllodyniaPillow_noHA','AllodyniaHeat_noHA','AllodyniaCold_noHA','everHA','everDiscomfort'};
elseif width(T)==145   % POEM v3.3, with CHYPS (TheraSpecs questions have been removed)
    T.Properties.VariableNames = {'StartDate','EndDate','Status','IPAddress','Progress','DurationToCompleteSec',...
        'Finished','RecordedDate','ResponseID','LastName','FirstName','Email','ExternalReference','LocationLatitude',...
        'LocationLongitude','DistributionChannel','UserLanguage','Q_RecaptchaScore','Age','Subject ID','RaceEth','AIAN','AIANtxt',...
        'AIANtribe','AIANtribe_txt','Asian','Asian_txt','Black','Black_txt','Hispanic','Hispanic_txt','MENA','MENA_txt',...
        'NHPI','NHPI_txt','White','White_txt','RaceEth_txt','GenderID','GenderID2','GenderID_txt','SAAB','SAAB_txt','SO',...
        'SO2','SO_txt','HA_yn','unprovokedHA_yn','MigCritB','MigCritC','MigCritD','MigCritC2','MigCritD2','MigCritA',...
        'MigFreq','MigRecent','VisAura','SensAura','SpeechAura','MultiSxAura_sametime','VisAura2orMore','VisAuraHArelation',...
        'VisAuraRecent','VisAuraDur','VisAuraUni','VisAuraSpread','VisAuraDur_yn','SensAura2orMore','SensAuraHArelation',...
        'SensAuraRecent','SensAuraDur','SensAuraUni','SensAuraSpread','SensAuraDur_yn','SpeechAura2orMore','SpeechAuraHArelation','SpeechAuraHArecent'...
        'SpeechAuraDur','SpeechAuraDur_yn','menstrualMig','CAMS','contHA','contHAsomeBreaks','HAmissedWork3mo','HAimpactWork3mo','HAmissedHousework3mo',...
        'HAimpactHousework3mo','HAmissedSocial3mo','HAdays3mo','SeverityHA','HAageOnset','MotionSick','MigFamHx','LightSneeze', ...
        'Uncomfy_Def', 'Incorrect_Ans','Stripy_discomfort','TV_discomfort','Lights_discomfort', 'Sports_discomfort', 'Stripy_shimmer', ...
        'Avoid_Flash','Sun_discomfort','Color_discomfort','Change_discomfort','Motion_discomfort','Clutter_discomfort','Pattern_discomfort', ...
        'Crowds_discomfort','Reflection_discomfort','Features_discomfort','Flicker_discomfort','Store_discomfort', 'Venue_discomfort', ...
        'BrightLight_discomfort','Clothing_discomfort', 'AllodyniaComb','AllodyniaPonytail','AllodyniaShave',...
        'AllodyniaEyeGlasses','AllodyniaContacts','AllodyniaEarrings','AllodyniaNecklace','AllodyniaTightClothes','AllodyniaShower',...
        'AllodyniaPillow','AllodyniaHeat','AllodyniaCold','AllodyniaNoHA','AnsCorrect','Research','AllodyniaComb_noHA','AllodyniaPonytail_noHA',...
        'AllodyniaShave_noHA','AllodyniaEyeGlasses_noHA','AllodyniaContacts_noHA','AllodyniaEarrings_noHA','AllodyniaNecklace_noHA','AllodyniaTightClothes_noHA',...
        'AllodyniaShower_noHA','AllodyniaPillow_noHA','AllodyniaHeat_noHA','AllodyniaCold_noHA','everHA','everDiscomfort'};
else  % TheraSpecs scale
        T.Properties.VariableNames = {'StartDate','EndDate','Status','IPAddress','Progress','DurationToCompleteSec',...
        'Finished','RecordedDate','ResponseID','LastName','FirstName','Email','ExternalReference','LocationLatitude',...
        'LocationLongitude','DistributionChannel','UserLanguage','Q_RecaptchaScore','Age','Subject ID','RaceEth','AIAN','AIANtxt',...
        'AIANtribe','AIANtribe_txt','Asian','Asian_txt','Black','Black_txt','Hispanic','Hispanic_txt','MENA','MENA_txt',...
        'NHPI','NHPI_txt','White','White_txt','RaceEth_txt','GenderID','GenderID2','GenderID_txt','SAAB','SAAB_txt','SO',...
        'SO2','SO_txt','HA_yn','unprovokedHA_yn','MigCritB','MigCritC','MigCritD','MigCritC2','MigCritD2','MigCritA',...
        'MigFreq','MigRecent','VisAura','SensAura','SpeechAura','MultiSxAura_sametime','VisAura2orMore','VisAuraHArelation',...
        'VisAuraRecent','VisAuraDur','VisAuraUni','VisAuraSpread','VisAuraDur_yn','SensAura2orMore','SensAuraHArelation',...
        'SensAuraRecent','SensAuraDur','SensAuraUni','SensAuraSpread','SensAuraDur_yn','SpeechAura2orMore','SpeechAuraHArelation','SpeechAuraHArecent'...
        'SpeechAuraDur','SpeechAuraDur_yn','menstrualMig','CAMS','contHA','contHAsomeBreaks','HAmissedWork3mo','HAimpactWork3mo','HAmissedHousework3mo',...
        'HAimpactHousework3mo','HAmissedSocial3mo','HAdays3mo','SeverityHA','HAageOnset','MotionSick','MigFamHx','LightSneeze','Light_HA','Light_Dizzy','Light_EyeStrain',...
        'Light_BlurryVision','Light_LightIntolerant','Light_Anxiety','Fluorescent','Flicker','Headlight','OutdoorGlare','Screen','Sunlight',...
        'FlickeringTrees','LightSensitivity','SunglassesSunlight','SunglassesIndoors','SeekDarkness','LightTvLimit','LightDeviceLimit',...
        'LightShopsLimit','LightDriveLimit','LightWorkLimit','LightOutdoorLimit','AllodyniaComb','AllodyniaPonytail','AllodyniaShave',...
        'AllodyniaEyeGlasses','AllodyniaContacts','AllodyniaEarrings','AllodyniaNecklace','AllodyniaTightClothes','AllodyniaShower',...
        'AllodyniaPillow','AllodyniaHeat','AllodyniaCold','AllodyniaNoHA','AnsCorrect','Research','AllodyniaComb_noHA','AllodyniaPonytail_noHA',...
        'AllodyniaShave_noHA','AllodyniaEyeGlasses_noHA','AllodyniaContacts_noHA','AllodyniaEarrings_noHA','AllodyniaNecklace_noHA','AllodyniaTightClothes_noHA',...
        'AllodyniaShower_noHA','AllodyniaPillow_noHA','AllodyniaHeat_noHA','AllodyniaCold_noHA','everHA','everDiscomfort'};

end
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
T.visAuraICHD_C3(contains(string(T.VisAuraDur),'5 minutes to 1')==1) = 1;
% T.visAuraICHD_C3(categorical(T.VisAuraDur_yn)=='Yes') = 1;
T.sensAuraICHD_C3 = zeros(height(T),1);
T.sensAuraICHD_C3(contains(string(T.SensAuraDur),'5 minutes to 1')==1) = 1;
% T.sensAuraICHD_C3(categorical(T.SensAuraDur_yn)=='Yes') = 1;
T.speechAuraICHD_C3 = zeros(height(T),1);
% T.speechAuraICHD_C3(categorical(T.SpeechAuraDur_yn)=='Yes') = 1;
T.speechAuraICHD_C3(contains(string(T.VisAuraDur),'5 minutes to 1')==1) = 1;
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
T.visAuraICHD_C = sum([T.visAuraICHD_C1 T.AuraICHD_C2 T.visAuraICHD_C3 T.visAuraICHD_C4 T.visAuraICHD_C5 T.visAuraICHD_C6],2);
T.sensAuraICHD_C = sum([T.sensAuraICHD_C1 T.AuraICHD_C2 T.sensAuraICHD_C3 T.sensAuraICHD_C4 T.sensAuraICHD_C5 T.sensAuraICHD_C6],2);
T.speechAuraICHD_C = sum([T.AuraICHD_C2 T.speechAuraICHD_C3 T.speechAuraICHD_C4 T.speechAuraICHD_C6],2);

% organize pseudo MIDAS scores
T.MIDAS1 = zeros(height(T),1);
T.MIDAS1(contains(string(T.HAmissedWork3mo),'1 - 3 days')==1) = 2;
T.MIDAS1(contains(string(T.HAmissedWork3mo),'4 - 11 days')==1) = 7;
T.MIDAS1(contains(string(T.HAmissedWork3mo),'12 - 24 days')==1) = 18;
T.MIDAS1(contains(string(T.HAmissedWork3mo),'25 - 48 days')==1) = 36;
T.MIDAS1(contains(string(T.HAmissedWork3mo),'49 - 72 days')==1) = 60;
T.MIDAS1(contains(string(T.HAmissedWork3mo),'73 - 90 days')==1) = 81;
T.MIDAS2 = zeros(height(T),1);
T.MIDAS2(contains(string(T.HAimpactWork3mo),'1 - 3 days')==1) = 2;
T.MIDAS2(contains(string(T.HAimpactWork3mo),'4 - 11 days')==1) = 7;
T.MIDAS2(contains(string(T.HAimpactWork3mo),'12 - 24 days')==1) = 18;
T.MIDAS2(contains(string(T.HAimpactWork3mo),'25 - 48 days')==1) = 36;
T.MIDAS2(contains(string(T.HAimpactWork3mo),'49 - 72 days')==1) = 60;
T.MIDAS2(contains(string(T.HAimpactWork3mo),'73 - 90 days')==1) = 81;
T.MIDAS3 = zeros(height(T),1);
T.MIDAS3(contains(string(T.HAmissedHousework3mo),'1 - 3 days')==1) = 2;
T.MIDAS3(contains(string(T.HAmissedHousework3mo),'4 - 11 days')==1) = 7;
T.MIDAS3(contains(string(T.HAmissedHousework3mo),'12 - 24 days')==1) = 18;
T.MIDAS3(contains(string(T.HAmissedHousework3mo),'25 - 48 days')==1) = 36;
T.MIDAS3(contains(string(T.HAmissedHousework3mo),'49 - 72 days')==1) = 60;
T.MIDAS3(contains(string(T.HAmissedHousework3mo),'73 - 90 days')==1) = 81;
T.MIDAS4 = zeros(height(T),1);
T.MIDAS4(contains(string(T.HAimpactHousework3mo),'1 - 3 days')==1) = 2;
T.MIDAS4(contains(string(T.HAimpactHousework3mo),'4 - 11 days')==1) = 7;
T.MIDAS4(contains(string(T.HAimpactHousework3mo),'12 - 24 days')==1) = 18;
T.MIDAS4(contains(string(T.HAimpactHousework3mo),'25 - 48 days')==1) = 36;
T.MIDAS4(contains(string(T.HAimpactHousework3mo),'49 - 72 days')==1) = 60;
T.MIDAS4(contains(string(T.HAimpactHousework3mo),'73 - 90 days')==1) = 81;
T.MIDAS5 = zeros(height(T),1);
T.MIDAS5(contains(string(T.HAmissedSocial3mo),'1 - 3 days')==1) = 2;
T.MIDAS5(contains(string(T.HAmissedSocial3mo),'4 - 11 days')==1) = 7;
T.MIDAS5(contains(string(T.HAmissedSocial3mo),'12 - 24 days')==1) = 18;
T.MIDAS5(contains(string(T.HAmissedSocial3mo),'25 - 48 days')==1) = 36;
T.MIDAS5(contains(string(T.HAmissedSocial3mo),'49 - 72 days')==1) = 60;
T.MIDAS5(contains(string(T.HAmissedSocial3mo),'73 - 90 days')==1) = 81;
T.MIDAS_score = sum([T.MIDAS1 T.MIDAS2 T.MIDAS3 T.MIDAS4 T.MIDAS5],2);

T.MigraineFrequency = NaN*ones(height(T),1);
T.MigraineFrequency(contains(string(T.MigFreq),'0 - 4 days')==1) = 1;
T.MigraineFrequency(contains(string(T.MigFreq),'5 - 9 days')==1) = 2;
T.MigraineFrequency(contains(string(T.MigFreq),'10 - 15 days')==1) = 3;
T.MigraineFrequency(contains(string(T.MigFreq),'16 - 20 days')==1) = 4;
T.MigraineFrequency(contains(string(T.MigFreq),'More than 20 days')==1) = 5;

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

% photophobia symptoms

% CAMS symptoms
T.photophobia = zeros(height(T),1);
T.photophobia(contains(string(T.MigCritD),'Sensitivity to light')==1) = 1;
T.phonophobia = zeros(height(T),1);
T.phonophobia(contains(string(T.MigCritD),'Sensitivity to sound')==1) = 1;
T.osmophobia = zeros(height(T),1);
T.osmophobia(contains(string(T.CAMS),'Smell sensitivity')==1) = 1;
T.nausea_vomit = zeros(height(T),1);
T.nausea_vomit(contains(string(T.MigCritD),'Nausea')==1) = 1;
T.lightheaded = zeros(height(T),1);
T.lightheaded(contains(string(T.CAMS),'Light headedness')==1) = 1;
T.blurryVision = zeros(height(T),1);
T.blurryVision(contains(string(T.CAMS),'Blurry vision')==1) = 1;
T.thinking = zeros(height(T),1);
T.thinking(contains(string(T.CAMS),'Difficulty thinking')==1) = 1;
T.neckPain = zeros(height(T),1);
T.neckPain(contains(string(T.CAMS),'Neck pain')==1) = 1;
T.balance = zeros(height(T),1);
T.balance(contains(string(T.CAMS),'Balance problems')==1) = 1;
T.spinning = zeros(height(T),1);
T.spinning(contains(string(T.CAMS),'Room spinning')==1) = 1;
T.ringing = zeros(height(T),1);
T.ringing(contains(string(T.CAMS),'Ear ringing')==1) = 1;
T.doubleVision = zeros(height(T),1);
T.doubleVision(contains(string(T.CAMS),'Double vision')==1) = 1;

% visual symptoms
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

% photophobia symptoms

if  ismember('Stripy_discomfort', T.Properties.VariableNames) % CHYPS-V scale  
    T.StripyDiscomfort = zeros(height(T),1);
    T.StripyDiscomfort(contains(string(T.Stripy_discomfort),'Almost Never')==1) = 0;
    T.StripyDiscomfort(contains(string(T.Stripy_discomfort),'Occasionally')==1) = 1;
    T.StripyDiscomfort(contains(string(T.Stripy_discomfort),'Often')==1) = 2;
    T.StripyDiscomfort(contains(string(T.Stripy_discomfort),'Almost Always')==1) = 3;

    T.TVDiscomfort = zeros(height(T),1);
    T.TVDiscomfort(contains(string(T.TV_discomfort),'Almost Never')==1) = 0;
    T.TVDiscomfort(contains(string(T.TV_discomfort),'Occasionally')==1) = 1;
    T.TVDiscomfort(contains(string(T.TV_discomfort),'Often')==1) = 2;
    T.TVDiscomfort(contains(string(T.TV_discomfort),'Almost Always')==1) = 3;

    T.LightsDiscomfort = zeros(height(T),1);
    T.LightsDiscomfort(contains(string(T.Lights_discomfort),'Almost Never')==1) = 0;
    T.LightsDiscomfort(contains(string(T.Lights_discomfort),'Occasionally')==1) = 1;
    T.LightsDiscomfort(contains(string(T.Lights_discomfort),'Often')==1) = 2;
    T.LightsDiscomfort(contains(string(T.Lights_discomfort),'Almost Always')==1) = 3;
    
    T.SportsDiscomfort = zeros(height(T),1);
    T.SportsDiscomfort(contains(string(T.Sports_discomfort),'Almost Never')==1) = 0;
    T.SportsDiscomfort(contains(string(T.Sports_discomfort),'Occasionally')==1) = 1;
    T.SportsDiscomfort(contains(string(T.Sports_discomfort),'Often')==1) = 2;
    T.SportsDiscomfort(contains(string(T.Sports_discomfort),'Almost Always')==1) = 3;

    T.StripyShimmer = zeros(height(T),1);
    T.StripyShimmer(contains(string(T.Stripy_shimmer),'Almost Never')==1) = 0;
    T.StripyShimmer(contains(string(T.Stripy_shimmer),'Occasionally')==1) = 1;
    T.StripyShimmer(contains(string(T.Stripy_shimmer),'Often')==1) = 2;
    T.StripyShimmer(contains(string(T.Stripy_shimmer),'Almost Always')==1) = 3;

    T.AvoidFlash = zeros(height(T),1);
    T.AvoidFlash(contains(string(T.Avoid_Flash),'Almost Never')==1) = 0;
    T.AvoidFlash(contains(string(T.Avoid_Flash),'Occasionally')==1) = 1;
    T.AvoidFlash(contains(string(T.Avoid_Flash),'Often')==1) = 2;
    T.AvoidFlash(contains(string(T.Avoid_Flash),'Almost Always')==1) = 3;

    T.SunDiscomfort = zeros(height(T),1);
    T.SunDiscomfort(contains(string(T.Sun_discomfort),'Almost Never')==1) = 0;
    T.SunDiscomfort(contains(string(T.Sun_discomfort),'Occasionally')==1) = 1;
    T.SunDiscomfort(contains(string(T.Sun_discomfort),'Often')==1) = 2;
    T.SunDiscomfort(contains(string(T.Sun_discomfort),'Almost Always')==1) = 3;

    T.ColorDiscomfort = zeros(height(T),1);
    T.ColorDiscomfort(contains(string(T.Color_discomfort),'Almost Never')==1) = 0;
    T.ColorDiscomfort(contains(string(T.Color_discomfort),'Occasionally')==1) = 1;
    T.ColorDiscomfort(contains(string(T.Color_discomfort),'Often')==1) = 2;
    T.ColorDiscomfort(contains(string(T.Color_discomfort),'Almost Always')==1) = 3;

    T.ChangeDiscomfort = zeros(height(T),1);
    T.ChangeDiscomfort(contains(string(T.Change_discomfort),'Almost Never')==1) = 0;
    T.ChangeDiscomfort(contains(string(T.Change_discomfort),'Occasionally')==1) = 1;
    T.ChangeDiscomfort(contains(string(T.Change_discomfort),'Often')==1) = 2;
    T.ChangeDiscomfort(contains(string(T.Change_discomfort),'Almost Always')==1) = 3;

    T.MotionDiscomfort = zeros(height(T),1);
    T.MotionDiscomfort(contains(string(T.Motion_discomfort),'Almost Never')==1) = 0;
    T.MotionDiscomfort(contains(string(T.Motion_discomfort),'Occasionally')==1) = 1;
    T.MotionDiscomfort(contains(string(T.Motion_discomfort),'Often')==1) = 2;
    T.MotionDiscomfort(contains(string(T.Motion_discomfort),'Almost Always')==1) = 3;

    T.ClutterDiscomfort = zeros(height(T),1);
    T.ClutterDiscomfort(contains(string(T.Clutter_discomfort),'Almost Never')==1) = 0;
    T.ClutterDiscomfort(contains(string(T.Clutter_discomfort),'Occasionally')==1) = 1;
    T.ClutterDiscomfort(contains(string(T.Clutter_discomfort),'Often')==1) = 2;
    T.ClutterDiscomfort(contains(string(T.Clutter_discomfort),'Almost Always')==1) = 3;
  
    T.PatternDiscomfort = zeros(height(T),1);
    T.PatternDiscomfort(contains(string(T.Pattern_discomfort),'Almost Never')==1) = 0;
    T.PatternDiscomfort(contains(string(T.Pattern_discomfort),'Occasionally')==1) = 1;
    T.PatternDiscomfort(contains(string(T.Pattern_discomfort),'Often')==1) = 2;
    T.PatternDiscomfort(contains(string(T.Pattern_discomfort),'Almost Always')==1) = 3;

    T.CrowdsDiscomfort = zeros(height(T),1);
    T.CrowdsDiscomfort(contains(string(T.Crowds_discomfort),'Almost Never')==1) = 0;
    T.CrowdsDiscomfort(contains(string(T.Crowds_discomfort),'Occasionally')==1) = 1;
    T.CrowdsDiscomfort(contains(string(T.Crowds_discomfort),'Often')==1) = 2;
    T.CrowdsDiscomfort(contains(string(T.Crowds_discomfort),'Almost Always')==1) = 3;

    T.ReflectionDiscomfort = zeros(height(T),1);
    T.ReflectionDiscomfort(contains(string(T.Reflection_discomfort),'Almost Never')==1) = 0;
    T.ReflectionDiscomfort(contains(string(T.Reflection_discomfort),'Occasionally')==1) = 1;
    T.ReflectionDiscomfort(contains(string(T.Reflection_discomfort),'Often')==1) = 2;
    T.ReflectionDiscomfort(contains(string(T.Reflection_discomfort),'Almost Always')==1) = 3;

    T.FeaturesDiscomfort = zeros(height(T),1);
    T.FeaturesDiscomfort(contains(string(T.Features_discomfort),'Almost Never')==1) = 0;
    T.FeaturesDiscomfort(contains(string(T.Features_discomfort),'Occasionally')==1) = 1;
    T.FeaturesDiscomfort(contains(string(T.Features_discomfort),'Often')==1) = 2;
    T.FeaturesDiscomfort(contains(string(T.Features_discomfort),'Almost Always')==1) = 3;

    T.FlickerDiscomfort = zeros(height(T),1);
    T.FlickerDiscomfort(contains(string(T.Flicker_discomfort),'Almost Never')==1) = 0;
    T.FlickerDiscomfort(contains(string(T.Flicker_discomfort),'Occasionally')==1) = 1;
    T.FlickerDiscomfort(contains(string(T.Flicker_discomfort),'Often')==1) = 2;
    T.FlickerDiscomfort(contains(string(T.Flicker_discomfort),'Almost Always')==1) = 3;

    T.StoreDiscomfort = zeros(height(T),1);
    T.StoreDiscomfort(contains(string(T.Store_discomfort),'Almost Never')==1) = 0;
    T.StoreDiscomfort(contains(string(T.Store_discomfort),'Occasionally')==1) = 1;
    T.StoreDiscomfort(contains(string(T.Store_discomfort),'Often')==1) = 2;
    T.StoreDiscomfort(contains(string(T.Store_discomfort),'Almost Always')==1) = 3;

    T.VenueDiscomfort = zeros(height(T),1);
    T.VenueDiscomfort(contains(string(T.Venue_discomfort),'Almost Never')==1) = 0;
    T.VenueDiscomfort(contains(string(T.Venue_discomfort),'Occasionally')==1) = 1;
    T.VenueDiscomfort(contains(string(T.Venue_discomfort),'Often')==1) = 2;
    T.VenueDiscomfort(contains(string(T.Venue_discomfort),'Almost Always')==1) = 3;

    T.BrightLightDiscomfort = zeros(height(T),1);
    T.BrightLightDiscomfort(contains(string(T.BrightLight_discomfort),'Almost Never')==1) = 0;
    T.BrightLightDiscomfort(contains(string(T.BrightLight_discomfort),'Occasionally')==1) = 1;
    T.BrightLightDiscomfort(contains(string(T.BrightLight_discomfort),'Often')==1) = 2;
    T.BrightLightDiscomfort(contains(string(T.BrightLight_discomfort),'Almost Always')==1) = 3;

    T.ClothingDiscomfort = zeros(height(T),1);
    T.ClothingDiscomfort(contains(string(T.Clothing_discomfort),'Almost Never')==1) = 0;
    T.ClothingDiscomfort(contains(string(T.Clothing_discomfort),'Occasionally')==1) = 1;
    T.ClothingDiscomfort(contains(string(T.Clothing_discomfort),'Often')==1) = 2;
    T.ClothingDiscomfort(contains(string(T.Clothing_discomfort),'Almost Always')==1) = 3;

    T.CHYPS_total_score = sum([T.StripyDiscomfort, T.TVDiscomfort, T.LightsDiscomfort, T.SportsDiscomfort, ...
    T.StripyShimmer, T.AvoidFlash, T.SunDiscomfort, T.ColorDiscomfort, T.ChangeDiscomfort, T.MotionDiscomfort, ...
    T.ClutterDiscomfort, T.PatternDiscomfort, T.CrowdsDiscomfort, T.ReflectionDiscomfort, ...
    T.FeaturesDiscomfort, T.FlickerDiscomfort, T.StoreDiscomfort, T.VenueDiscomfort, ...
    T.BrightLightDiscomfort, T.ClothingDiscomfort], 2);

    T.CHYPS_Brightness = sum([T.LightsDiscomfort, T.SunDiscomfort, T.ChangeDiscomfort, ...
        T.ReflectionDiscomfort, T.BrightLightDiscomfort], 2);

    T.CHYPS_Pattern = sum([T.StripyDiscomfort, T.StripyShimmer, T.PatternDiscomfort, ...
        T.FeaturesDiscomfort, T.ClothingDiscomfort], 2);

    T.CHYPS_Strobing = sum([T.TVDiscomfort, T.AvoidFlash, T.MotionDiscomfort, ...
        T.FlickerDiscomfort, T.VenueDiscomfort], 2);

    T.CHYPS_IntenseVisEnviro = sum([T.SportsDiscomfort,  T.ColorDiscomfort, ...
        T.ClutterDiscomfort, T.CrowdsDiscomfort, T.StoreDiscomfort], 2);

else   % TheraSpecs scale
    T.lightHA = zeros(height(T),1);
    T.lightHA(contains(string(T.Light_HA),'Rarely')==1) = 1;
    T.lightHA(contains(string(T.Light_HA),'Sometimes')==1) = 2;
    T.lightHA(contains(string(T.Light_HA),'Often')==1) = 3;
    T.lightHA(contains(string(T.Light_HA),'Always')==1) = 4;

    T.lightDizzy = zeros(height(T),1);
    T.lightDizzy(contains(string(T.Light_Dizzy),'Rarely')==1) = 1;
    T.lightDizzy(contains(string(T.Light_Dizzy),'Sometimes')==1) = 2;
    T.lightDizzy(contains(string(T.Light_Dizzy),'Often')==1) = 3;
    T.lightDizzy(contains(string(T.Light_Dizzy),'Always')==1) = 4;

    T.lightEyeStrain = zeros(height(T),1);
    T.lightEyeStrain(contains(string(T.Light_EyeStrain),'Rarely')==1) = 1;
    T.lightEyeStrain(contains(string(T.Light_EyeStrain),'Sometimes')==1) = 2;
    T.lightEyeStrain(contains(string(T.Light_EyeStrain),'Often')==1) = 3;
    T.lightEyeStrain(contains(string(T.Light_EyeStrain),'Always')==1) = 4;

    T.lightBlurryVision = zeros(height(T),1);
    T.lightBlurryVision(contains(string(T.Light_BlurryVision),'Rarely')==1) = 1;
    T.lightBlurryVision(contains(string(T.Light_BlurryVision),'Sometimes')==1) = 2;
    T.lightBlurryVision(contains(string(T.Light_BlurryVision),'Often')==1) = 3;
    T.lightBlurryVision(contains(string(T.Light_BlurryVision),'Always')==1) = 4;

    T.lightIntolerant = zeros(height(T),1);
    T.lightIntolerant(contains(string(T.Light_LightIntolerant),'Rarely')==1) = 1;
    T.lightIntolerant(contains(string(T.Light_LightIntolerant),'Sometimes')==1) = 2;
    T.lightIntolerant(contains(string(T.Light_LightIntolerant),'Often')==1) = 3;
    T.lightIntolerant(contains(string(T.Light_LightIntolerant),'Always')==1) = 4;

    T.lightAnxiety = zeros(height(T),1);
    T.lightAnxiety(contains(string(T.Light_Anxiety),'Rarely')==1) = 1;
    T.lightAnxiety(contains(string(T.Light_Anxiety),'Sometimes')==1) = 2;
    T.lightAnxiety(contains(string(T.Light_Anxiety),'Often')==1) = 3;
    T.lightAnxiety(contains(string(T.Light_Anxiety),'Always')==1) = 4;

    T.lightFluorescent = zeros(height(T),1);
    T.lightFluorescent(contains(string(T.Fluorescent),'Rarely')==1) = 1;
    T.lightFluorescent(contains(string(T.Fluorescent),'Sometimes')==1) = 2;
    T.lightFluorescent(contains(string(T.Fluorescent),'Often')==1) = 3;
    T.lightFluorescent(contains(string(T.Fluorescent),'Always')==1) = 4;

    T.lightFlicker = zeros(height(T),1);
    T.lightFlicker(contains(string(T.Flicker),'Rarely')==1) = 1;
    T.lightFlicker(contains(string(T.Flicker),'Sometimes')==1) = 2;
    T.lightFlicker(contains(string(T.Flicker),'Often')==1) = 3;
    T.lightFlicker(contains(string(T.Flicker),'Always')==1) = 4;

    T.lightHeadlight = zeros(height(T),1);
    T.lightHeadlight(contains(string(T.Headlight),'Rarely')==1) = 1;
    T.lightHeadlight(contains(string(T.Headlight),'Sometimes')==1) = 2;
    T.lightHeadlight(contains(string(T.Headlight),'Often')==1) = 3;
    T.lightHeadlight(contains(string(T.Headlight),'Always')==1) = 4;

    T.lightOutdoorGlare = zeros(height(T),1);
    T.lightOutdoorGlare(contains(string(T.OutdoorGlare),'Rarely')==1) = 1;
    T.lightOutdoorGlare(contains(string(T.OutdoorGlare),'Sometimes')==1) = 2;
    T.lightOutdoorGlare(contains(string(T.OutdoorGlare),'Often')==1) = 3;
    T.lightOutdoorGlare(contains(string(T.OutdoorGlare),'Always')==1) = 4;

    T.lightScreen = zeros(height(T),1);
    T.lightScreen(contains(string(T.Screen),'Rarely')==1) = 1;
    T.lightScreen(contains(string(T.Screen),'Sometimes')==1) = 2;
    T.lightScreen(contains(string(T.Screen),'Often')==1) = 3;
    T.lightScreen(contains(string(T.Screen),'Always')==1) = 4;

    T.lightSunlight = zeros(height(T),1);
    T.lightSunlight(contains(string(T.Sunlight),'Rarely')==1) = 1;
    T.lightSunlight(contains(string(T.Sunlight),'Sometimes')==1) = 2;
    T.lightSunlight(contains(string(T.Sunlight),'Often')==1) = 3;
    T.lightSunlight(contains(string(T.Sunlight),'Always')==1) = 4;

    T.lightTrees = zeros(height(T),1);
    T.lightTrees(contains(string(T.FlickeringTrees),'Rarely')==1) = 1;
    T.lightTrees(contains(string(T.FlickeringTrees),'Sometimes')==1) = 2;
    T.lightTrees(contains(string(T.FlickeringTrees),'Often')==1) = 3;
    T.lightTrees(contains(string(T.FlickeringTrees),'Always')==1) = 4;

    T.lightGlassesSun = zeros(height(T),1);
    T.lightGlassesSun(contains(string(T.SunglassesSunlight),'Rarely')==1) = 1;
    T.lightGlassesSun(contains(string(T.SunglassesSunlight),'Sometimes')==1) = 2;
    T.lightGlassesSun(contains(string(T.SunglassesSunlight),'Often')==1) = 3;
    T.lightGlassesSun(contains(string(T.SunglassesSunlight),'Always')==1) = 4;

    T.lightGlassesInd = zeros(height(T),1);
    T.lightGlassesInd(contains(string(T.SunglassesIndoors),'Rarely')==1) = 1;
    T.lightGlassesInd(contains(string(T.SunglassesIndoors),'Sometimes')==1) = 2;
    T.lightGlassesInd(contains(string(T.SunglassesIndoors),'Often')==1) = 3;
    T.lightGlassesInd(contains(string(T.SunglassesIndoors),'Always')==1) = 4;

    T.lightSeekDark = zeros(height(T),1);
    T.lightSeekDark(contains(string(T.SeekDarkness),'Rarely')==1) = 1;
    T.lightSeekDark(contains(string(T.SeekDarkness),'Sometimes')==1) = 2;
    T.lightSeekDark(contains(string(T.SeekDarkness),'Often')==1) = 3;
    T.lightSeekDark(contains(string(T.SeekDarkness),'Always')==1) = 4;

    T.lightLimTV = zeros(height(T),1);
    T.lightLimTV(contains(string(T.LightTvLimit),'Rarely')==1) = 1;
    T.lightLimTV(contains(string(T.LightTvLimit),'Sometimes')==1) = 2;
    T.lightLimTV(contains(string(T.LightTvLimit),'Often')==1) = 3;
    T.lightLimTV(contains(string(T.LightTvLimit),'Always')==1) = 4;

    T.lightLimDevice = zeros(height(T),1);
    T.lightLimDevice(contains(string(T.LightDeviceLimit),'Rarely')==1) = 1;
    T.lightLimDevice(contains(string(T.LightDeviceLimit),'Sometimes')==1) = 2;
    T.lightLimDevice(contains(string(T.LightDeviceLimit),'Often')==1) = 3;
    T.lightLimDevice(contains(string(T.LightDeviceLimit),'Always')==1) = 4;

    T.lightLimShops = zeros(height(T),1);
    T.lightLimShops(contains(string(T.LightShopsLimit),'Rarely')==1) = 1;
    T.lightLimShops(contains(string(T.LightShopsLimit),'Sometimes')==1) = 2;
    T.lightLimShops(contains(string(T.LightShopsLimit),'Often')==1) = 3;
    T.lightLimShops(contains(string(T.LightShopsLimit),'Always')==1) = 4;

    T.lightLimDrive = zeros(height(T),1);
    T.lightLimDrive(contains(string(T.LightDriveLimit),'Rarely')==1) = 1;
    T.lightLimDrive(contains(string(T.LightDriveLimit),'Sometimes')==1) = 2;
    T.lightLimDrive(contains(string(T.LightDriveLimit),'Often')==1) = 3;
    T.lightLimDrive(contains(string(T.LightDriveLimit),'Always')==1) = 4;

    T.lightLimWork = zeros(height(T),1);
    T.lightLimWork(contains(string(T.LightWorkLimit),'Rarely')==1) = 1;
    T.lightLimWork(contains(string(T.LightWorkLimit),'Sometimes')==1) = 2;
    T.lightLimWork(contains(string(T.LightWorkLimit),'Often')==1) = 3;
    T.lightLimWork(contains(string(T.LightWorkLimit),'Always')==1) = 4;

    T.lightLimOutdoor = zeros(height(T),1);
    T.lightLimOutdoor(contains(string(T.LightOutdoorLimit),'Rarely')==1) = 1;
    T.lightLimOutdoor(contains(string(T.LightOutdoorLimit),'Sometimes')==1) = 2;
    T.lightLimOutdoor(contains(string(T.LightOutdoorLimit),'Often')==1) = 3;
    T.lightLimOutdoor(contains(string(T.LightOutdoorLimit),'Always')==1) = 4;

    % Calculating TheraSpecs scores
    T.lightSx_score = sum([T.lightHA T.lightDizzy T.lightEyeStrain T.lightBlurryVision T.lightIntolerant T.lightAnxiety],2);
    T.lightBother_score = sum([T.lightFluorescent T.lightFlicker T.lightOutdoorGlare T.lightTrees T.lightSunlight T.lightHeadlight T.lightScreen],2);
    T.lightAvoidance_score = sum([T.lightGlassesSun T.lightGlassesInd T.lightSeekDark T.lightLimTV T.lightLimDevice...
        T.lightLimShops T.lightLimDrive T.lightLimWork T.lightLimOutdoor],2);
    T.lightFlicker_score = sum([T.lightFluorescent T.lightFlicker T.lightTrees T.lightScreen],2);
    T.lightStatic_score = sum([T.lightOutdoorGlare T.lightSunlight T.lightHeadlight],2);
    
end

T.ContinuousHA = zeros(height(T),1);
T.ContinuousHA(contains(string(T.contHAsomeBreaks),'no breaks')==1) = 1;

%% Sanity check the table

% Remove rows for which "Finished" is False
idxTrueFinishedStatus=cellfun(@(x) ~strcmpi(x,'FALSE'), T.Finished);
T=T(idxTrueFinishedStatus,:);

% Remove rows for which answers were not correct
idxTrueCorrectStatus=cellfun(@(x) ~contains(x,'No'), T.AnsCorrect);
T=T(idxTrueCorrectStatus,:);

% Remove rows for which status is 'Survey Preview'
idxFalsePreviewStatus=cellfun(@(x) ~contains(x,'Survey Preview'), T.Status);
T=T(idxFalsePreviewStatus,:);


end % function