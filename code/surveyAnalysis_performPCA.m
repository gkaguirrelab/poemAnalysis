function [ output_args ] = surveyAnalysis_performPCA( valuesTable )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


% Get table dimensions
nRows=size(valuesTable,1);
nCols=size(valuesTable,2);

% Remove rows that have no values (except for subjectID)
valuesTable=rmmissing(valuesTable,'MinNumMissing',nCols-1);
nRows=size(valuesTable,1);

% z-transform each column, accounting for NaNs, and excluding the first
% column which contains subject IDs
for cc=2:nCols
    colMean=nanmean(valuesTable{:,cc});
    colStd=nanstd(valuesTable{:,cc});
    valuesTable{:,cc}=(valuesTable{:,cc}-colMean)/colStd;
end

% Perform the PCA
[coeff,score,latent,tsquared,explained,mu] = pca(valuesTable{:,2:nCols});

% Plot the variance explained
figure
plot(explained,'-or')

% Plot the subjects in the space of the first three dimensions
figure
scatter3(score(:,1),score(:,2),score(:,3))

end % function