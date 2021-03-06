%% poemAnalysis_main
% Analysis code for the Penn Online Evaluation of Migraine (POEM)
%
% Description:
%   This routine loads the .csv files generated by Qualtrics that have the
%   results of the migraine diagnostic pathway. The link the data for the
%   Aguirre lab can be found here:
%
%       https://upenn.co1.qualtrics.com/jfe/form/SV_4NQzKbssiT8qqVf
%
%   Subsequent functions called from this main script are responsible for
%   pre-processing of the data fields and then implementing the headache
%   classification pathway.
%

%% Housekeeping
clear variables
close all

%% Set paths to data and output
analysisDir = '/Users/brianahaggerty/Box/MELA_Protected/POEM_analysis/POEM_v1.1s_2021_06_24_Analysis/';

% Set the output filenames
outputResultExcelName=fullfile(analysisDir, 'POEM_v1.1_results.xlsx');
rawDataSheets={'POEM_v1.1_raw.csv'};

% get the full path to thisDataSheet
thisDataSheetFileName=fullfile(analysisDir, rawDataSheets{1});


%% load and pre-process thisDataSheet, returning table "T"
[T, notesText] = poemAnalysis_preProcess(thisDataSheetFileName);


%% classify headache based upon table T
diagnosisTable = poemAnalysis_classify( T );
writetable(diagnosisTable,outputResultExcelName,'Range','A4','WriteRowNames',true)

