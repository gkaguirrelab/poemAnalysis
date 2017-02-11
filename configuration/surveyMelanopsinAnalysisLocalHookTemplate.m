function surveyMelanopsinAnalysisLocalHook
% surveyMelanopsinAnalysisLocalHook
%
% Configure things for processing MELA project surveys.
%
% For use with the ToolboxToolbox.  Copy this into your
% ToolboxToolbox localToolboxHooks directory (by defalut,
% ~/localToolboxHooks) and delete "Template" from the filename
%
% The thing that this does is add subfolders of the project to the path as
% well as define Matlab preferences that specify input and output
% directories.
%
% You will need to edit the project location and i/o directory locations
% to match what is true on your computer.

%% Say hello
fprintf('Running surveyMelanopsinAnalysisLocalHook\n');

%% Set preferences

% Point at the code
projectDir = tbLocateProject('surveyMelanopsinAnalysis');
setpref('surveyAnalysis', 'surveyMelanopsinAnalysisBaseDir', fullfile(projectDir,'code'));

% Add the code to the path
addpath(genpath(projectDir));