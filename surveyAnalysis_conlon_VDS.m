function [ resultTable, summaryMeasureFieldName ] = surveyAnalysis_conlon_VDS( T )
% function [ processedTable ] = surveyAnalysis_VDS( T )
%
% Details regarding the VDS here
%

subjectIDField={'SubjectID_subjectIDList'};

summaryMeasureFieldName='VDS_Conlon_1999';

questions={'x3__DoYourEyesEverFeelWatery_Red_Sore_Strained_Tired_Dry_Gritty',...
'x4_DoYourEyesEverFeelWatery_Red_Sore_Strained_Tired_DryOrGritty',...
'x5_DoYourEyesEverFeelWatery_Red_Sore_Strained_Tired_DryOrGritty',...
'x6_HowOftenDoYouGetAHeadacheWhenWorkingUnderFluorescentLight___',...
'x7_DoYouEverGetAHeadacheFromReadingANewspaperOrMagazineWithClea',...
'x8_WhenReading_DoYouEverUnintentionallyRereadTheSameWordsInALin',...
'x9_DoYouHaveToUseAPencilOrYourFingerToKeepFromLosingYourPlaceWh',...
'x10_WhenReading_DoYouEverUnintentionallyRereadTheSameLine___',...
'x11_WhenReading_DoYouEverHaveToSquintToKeepTheWordsOnAPageOfCle',...
'x12_WhenReading_DoTheWordsOnAPageOfClearTextEverAppearToFadeInt',...
'x13_DoTheLettersOnAPageOfClearTextEverGoBlurryWhenYouAreReading',...
'x14_DoTheLettersOnAPageEverAppearAsADoubleImageWhenYouAreReadin',...
'x15_WhenReading_DoTheWordsOnThePageEverBeginToMoveOrFloat___',...
'x16_WhenReading_DoYouEverHaveDifficultyKeepingTheWordsOnThePage',...
'x17_WhenYouAreReadingAPageThatConsistsOfBlackPrintOnAWhiteBackg',...
'x18_WhenReadingBlackPrintOnAWhiteBackground_DoYouEverHaveToMove',...
'x19_DoYouEverHaveDifficultySeeingMoreThanOneOrTwoWordsOnALineIn',...
'x20_DoYouEverHaveDifficultyReadingTheWordsOnAPageBecauseTheyBeg',...
'x21_WhenReadingUnderFluorescentLightsOrInBrightSunlight_DoesThe',...
'x22_DoYouHaveToMoveYourEyesAroundThePage_OrContinuallyBlinkOrRu',...
'x23_DoesTheWhiteBackgroundBehindTheTextEverAppearToMove_Flicker',...
'x24_WhenReading_DoTheWordsOrLettersInTheWordsEverAppearToSpread',...
'x25_AsAResultOfAnyOfTheAboveDifficulties_DoYouFindReadingASlowT'};

textResponses={'0 = Never',...
'1 = Occasionally',...
'2 = Often',...
'3 = Almost always'};

% This is the offset between the index number of the textResponses
% [1, 2, 3, ...] and the assigned score value (e.g.) [0, 1, 2, ...]
scoreOffset=-1;

% Check that the column headings match the list of questions
questionsStartIdx=find(strcmp(T.Properties.VariableNames,questions{1}));
if ~isempty(questionsStartIdx)
    if ~isequal(T.Properties.VariableNames(questionsStartIdx:questionsStartIdx+length(questions)-1),questions)
    errorText='The list of hard-coded column headings does not match the headings in the passed table';
    error(errorText);
    end
else
    errorText='The list of hard-coded column headings does not match the headings in the passed table';
    error(errorText);
end

% Check that we have the right name for the subjectID field
subjectIDIdx=find(strcmp(T.Properties.VariableNames,subjectIDField),1);
if isempty(subjectIDIdx)
    errorText='The hard-coded subjectID field name is not present in this table';
    error(errorText);
end

% Convert the text responses to integers. Sadly, this
% has to be done in a loop as Matlah does not have a way to address an
% array of dynamically identified field names of a structure

% The group index converts the list of text responses into v

for qq=1:length(questions)
    T.(questions{qq})=grp2idx(categorical(T.(questions{qq}),textResponses,'Ordinal',true))+scoreOffset;
end

% Calculate the VDS score.
% Sum (instead of nansum) is used so that the presence of any NaN values in
% the responses for a subject result in an undefined total score.
scoreMatrix=table2array(T(:,questionsStartIdx:questionsStartIdx+length(questions)-1));
sumScore=sum(scoreMatrix,2);

% Create a little table with the subject IDs and VDS scores
resultTable=T(:,subjectIDIdx);
resultTable=[resultTable,cell2table(num2cell(sumScore))];
resultTable.Properties.VariableNames{2}=summaryMeasureFieldName;

end

