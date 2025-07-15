close all
clear variables

poemAnalysis_main_v3




figSaveDir = '~/Desktop';


nBoots = 100;
nBins = 7;

migraineDx = {'migraine w/out aura','migraine w/aura'};
probMigraineDx = {'probable migraine w/out aura','probable migraine w/aura'};
haFDx = {'no headache'};
nonMigHaDx = {'non-migraine headache'};
migraineIdx = or(strcmp(migraineDx{1},cellstr(Results.DxFull)),...
    strcmp(migraineDx{2},cellstr(Results.DxFull)));
probMigIdx = or(strcmp(probMigraineDx{1},cellstr(Results.DxFull)),...
    strcmp(probMigraineDx{2},cellstr(Results.DxFull)));
otherHaIdx = strcmp(nonMigHaDx,cellstr(Results.DxFull));
haFIdx = strcmp(haFDx,cellstr(Results.DxFull));
allIdx = 1:size(Results,1);




%% Create symptom score plots for each group
varsToPlot = {'MIDAS','LightSensScore','AllodyniaScore',};
scoreLabel = {'MIDAS','light sensitivity','allodynia'};
groups = {'haFIdx','otherHaIdx','migraineIdx','probMigIdx'};
groupLabels = {'HAF','otherHA','migr','probMig'};
ylimMax = [0.75 0.75 0.75];
xlimMax = [400,75,25];
xtickSpacing = [100 25 5];
plotPatchColors = {'k','y','r','b'};
plotLineColors = {[0.5 0.5 0.5],[0.75 0.75 0.5],[0.75 0.5 0.75],[0.5 0.5 0.75]};
figHandle = figure();
set(gcf, 'color', 'none');
figuresize(length(varsToPlot)*2,2,'inches');
tiledlayout(1,length(varsToPlot),'TileSpacing','tight','Padding','tight');
idxSet = [1 3];
for vv = 1:3

    vals = double(Results.(varsToPlot{vv}));
    [~,edges] = discretize(vals(allIdx),nBins);
    X = edges(1:end-1) + diff(edges)/2;
    nexttile(vv)
    plot([0 xlimMax(vv)],[0 0],':k');
    veridicalVals = [];
    lineHandles = [];
    for gg = idxSet

        idx = eval(groups{gg});
        veridicalVals{gg} = vals(idx);
        nSubs(gg) = sum(idx);

        if vv == 1 && gg == 1
           continue
        end

        Yboot = [];
        for bb = 1:nBoots
            bootIdx = datasample(find(idx),sum(idx));
            Y = histcounts(vals(bootIdx),edges);
            Yboot(bb,:) = Y ./ sum(Y);
        end
        Y = mean(Yboot,1);
        Ysem = std(Yboot,[],1);
        patch([X,fliplr(X)],[Y+Ysem,fliplr(Y-Ysem)],plotPatchColors{gg},'FaceAlpha',0.1,'EdgeColor','none');
        hold on
            lineHandles(gg) = plot(X,Y,'.-','Color',plotLineColors{gg},'MarkerSize',10,'LineWidth',1.5);
    end

    % Clean up
    a = gca();
    a.Color = 'none';
    box off
    a.YTick = 0:0.75:ylimMax(vv);
    switch vv
        case 1
            ylabel('Proportion subjects');
                        a.YTick = 0:0.75:ylimMax(vv);

        case 2
            a.YTick = [];
            for gg = [1 3]
                lgndText{gg} = sprintf([groupLabels{gg} ', n=%d'],nSubs(gg));
            end
           lh = legend(lineHandles(idxSet),lgndText(idxSet),'Location','north');
           lh.Box = 'off';
        case 3
            a.YTick = [];
    end
    ylim([-0.05,ylimMax(vv)]);
    xlim([0,xlimMax(vv)]);
    a.TickDir = 'out';
       title(varsToPlot{vv});
    xlabel(scoreLabel{vv});
    a.XTick = 0:xtickSpacing(vv):xlimMax(vv);
    a.XTickLabelRotation = 45;
    axis square
end
plotFileName = fullfile(figSaveDir,'POEM_v3.1_GroupSymptomHistograms.pdf');
saveas(figHandle,plotFileName);



%% Conditional symptom scores
varsToPlot = {'MIDAS','LightSensScore','AllodyniaScore'};
scoreLabel = {'MIDAS','light sensitivity','allodynia'};
ylimMax = [0.75,0.75,0.75,];
xlimMax = [400,75,25];
xtickSpacing = [100 25 5];
conditionOn = {'PhoticSneeze','interAllodynia','MotionSick','DxFull'};
conditionPairs = {...
    {'No','Yes'},...
    {'No','Yes'},...
    {'No','Yes'},...
    {'w/out','w/aura'},...
    };
plotPatchColors = {...
    {'k','b'},...
    {'k','m'},...
    {'k','g'},...
    {'r','b'},...
    };
plotLineColors = {...
    {[0.5 0.5 0.5],[0.5 0.5 0.75]},...
    {[0.5 0.5 0.5],[0.75 0.5 0.75]},...
    {[0.5 0.5 0.5],[0.5 0.55 0.5]},...
    {[0.75 0.5 0.5],[0.5 0.5 0.75]},...
    };

figHandle = figure();
set(gcf, 'color', 'none');
figuresize(length(varsToPlot)*2,2,'inches');
tiledlayout(1,3,'TileSpacing','tight','Padding','tight');

for vv = 1:length(varsToPlot)

    vals = double(Results.(varsToPlot{vv}));
    [~,edges] = discretize(vals(migraineIdx),nBins);
    X = edges(1:end-1) + diff(edges)/2;

    for cc = 4

        nexttile()
        plot([0 xlimMax(vv)],[0 0],':k');

        thisCondition = conditionOn{cc};
        thisPair = conditionPairs{cc};
        lineHandles = [];
        for pp = 1:length(thisPair)

            % Get the indices for this conditional
            idx = and(migraineIdx,contains(cellstr(Results.(thisCondition)),thisPair{pp}));

            % Store the vals for a subsequent KS test
            veridicalVals{pp} = vals(idx);

            nSubs(pp) = sum(idx);

            if nSubs(pp) == 0
                continue
            end

            Yboot = [];
            for bb = 1:nBoots
                bootIdx = datasample(find(idx),sum(idx));
                Y = histcounts(vals(bootIdx),edges);
                Yboot(bb,:) = Y ./ sum(Y);
            end
            Y = mean(Yboot,1);
            Ysem = std(Yboot,[],1);
            patch([X,fliplr(X)],[Y+Ysem,fliplr(Y-Ysem)],plotPatchColors{cc}{pp},'FaceAlpha',0.1,'EdgeColor','none');
            hold on
            lineHandles(pp) = plot(X,Y,'.-','Color',plotLineColors{cc}{pp},'MarkerSize',10,'LineWidth',1.5);
        end


        % Perform a two-tailed KS test of the distributions
        if all(nSubs > 0)
            [~,p,ks2stat] = kstest2(veridicalVals{1},veridicalVals{2});
        else
            p = nan;
            ks2stat = nan;
        end

        % Clean up
        a = gca();
        a.Color = 'none';
        box off
        if vv == 1
            ylabel('Proportion subjects');
            a.YTick = 0:0.75:ylimMax(vv);
        end
        if vv == 2
            a.YTick = [];
            lgndText = {};
            for pp = 1:2
                lgndText{pp} = sprintf([thisPair{pp} ', n=%d'],nSubs(pp));
            end
           lh = legend(lineHandles,lgndText,'Location','north');
           lh.Box = 'off';
        end
        if vv == 3
            a.YTick = [];
        end
        ylim([-0.05,ylimMax(vv)]);
        xlim([0,xlimMax(vv)]);
        a.TickDir = 'out';
        if cc == 1
           title(varsToPlot{vv});
        end
        if cc == length(conditionOn)
            xlabel(scoreLabel{vv});
            a.XTick = 0:xtickSpacing(vv):xlimMax(vv);
            a.XTickLabelRotation = 45;
        else
            a.XTick = [];
            a.XAxis.Visible = 'off';
        end

       kstext = sprintf('KS = %2.2f, p = %0.1e',ks2stat,p);
       text(xlimMax(vv)*0.05,0.7,kstext,'HorizontalAlignment','left');
                  title(varsToPlot{vv});
axis square
    end

end
plotFileName = fullfile(figSaveDir,'POEM_v3.1_ConditionalSymptomHistograms.pdf');
saveas(figHandle,plotFileName);



%% Correlation of measures in people with migraine
[rho,pval]=corr(Results.MIDAS(migraineIdx),Results.AllodyniaScore(migraineIdx),'Type','Spearman');
fprintf('Correlation of MIDAS with ASC-12 in migraine: Spearman rho = %2.2f, p = %0.1e\n',rho,pval);

[rho,pval]=corr(Results.MIDAS(migraineIdx),Results.LightSensScore(migraineIdx),'Type','Spearman');
fprintf('Correlation of MIDAS with Light Sensitivity in migraine: Spearman rho = %2.2f, p = %0.1e\n',rho,pval);



% Plot the light / touch sensitivity scatter for migraine with and without
% aura
wIdx = and(migraineIdx,contains(cellstr(Results.DxFull),'w/aura'));
woIdx = and(migraineIdx,contains(cellstr(Results.DxFull),'w/out'));


set(gcf, 'color', 'none');
figuresize(2*3,3,'inches');
tiledlayout(1,2,'TileSpacing','tight','Padding','tight');


nexttile();
scatter(Results.LightSensScore(woIdx),Results.AllodyniaScore(woIdx),50,...
    'MarkerFaceColor','r','MarkerEdgeColor','none',...
    'MarkerFaceAlpha',.25);
refline
axis square
box off
xlabel('Light sensitivity score');
ylabel('Allodynia score');
a = gca();
a.TickDir = 'out';
a.XTick = 0:20:80;
xlim([-5 80])
ylim([-2.5 25])
a.FontSize = 14;
title(sprintf('M wo/Aura r=%2.2f',corr(Results.LightSensScore(woIdx),Results.AllodyniaScore(woIdx))));


nexttile();
scatter(Results.LightSensScore(wIdx),Results.AllodyniaScore(wIdx),50,...
    'MarkerFaceColor','b','MarkerEdgeColor','none',...
    'MarkerFaceAlpha',.25);
refline
axis square
box off
xlabel('Light sensitivity score');
ylabel('Allodynia score');
a = gca();
a.TickDir = 'out';
a.XTick = 0:20:80;
xlim([-5 80])
ylim([-2.5 25])
a.FontSize = 14;
title(sprintf('M w/Aura r=%2.2f',corr(Results.LightSensScore(wIdx),Results.AllodyniaScore(wIdx))));


plotFileName = fullfile(figSaveDir,'POEM_v3.1_SymptomScatterPlot.pdf');
saveas(figHandle,plotFileName);


%% US Map of all respondants
% Different colors for migraine with and without
figHandle = figure();
set(gcf, 'color', 'none');
figuresize(4,3,'inches');
latVec = double(T.LocationLatitude);
lonVec = double(T.LocationLongitude);
gp = geoplot(latVec(wIdx),lonVec(wIdx),'o','MarkerSize',5,'MarkerEdgeColor','none','MarkerFaceColor',[0 0 1]);
hold on
gp = geoplot(latVec(woIdx),lonVec(woIdx),'o','MarkerSize',5,'MarkerEdgeColor','none','MarkerFaceColor',[1 0 0]);
geobasemap grayland
geolimits([25 50],[-130 -60]);
a = gca();
a.AxisColor = 'none';
a.Grid = 'off';
a.Scalebar.Visible = 'off';
plotFileName = fullfile(figSaveDir,'POEM_v3.1_MapAllRespondents.pdf');
saveas(figHandle,plotFileName);


%% Report significance of difference in correlation coefficients
p = compare_correlation_coefficients(...
    corr(Results.LightSensScore(woIdx),Results.AllodyniaScore(woIdx)),...
    corr(Results.LightSensScore(wIdx),Results.AllodyniaScore(wIdx)),...
    sum(woIdx),sum(wIdx));
fprintf('Difference in correlation of light and touch sens between MwA and MwoA: p = %2.4f\n',p)


%% Report differences in headache frequency and severity between groups
[h,p,ci,stats] = ttest2(Results.MigraineFrequency(woIdx),Results.MigraineFrequency(wIdx));
fprintf('Migraine Freq woA = %2.1f, wA = %2.1f, t(%ddf)=%2.2f,p=%2.2f\n',...
    mean(Results.MigraineFrequency(woIdx)),...
    mean(Results.MigraineFrequency(wIdx)),...
    stats.df,stats.tstat,p);

[h,p,ci,stats] = ttest2(Results.HAseverity(woIdx),Results.HAseverity(wIdx));
fprintf('Headache Severity woA = %2.1f, wA = %2.1f, t(%ddf)=%2.2f,p=%2.2f\n',...
    mean(Results.HAseverity(woIdx)),...
    mean(Results.HAseverity(wIdx)),...
    stats.df,stats.tstat,p);

[h,p,ci,stats] = ttest2(Results.MIDAS(woIdx),Results.MIDAS(wIdx));
fprintf('MIDAS woA = %2.1f, wA = %2.1f, t(%ddf)=%2.2f,p=%2.2f\n',...
    mean(Results.MIDAS(woIdx)),...
    mean(Results.MIDAS(wIdx)),...
    stats.df,stats.tstat,p);

%% Build a patient summary table
VarNames = ["n","Age","SAAB-%M","MIDAS","Freq","Sev"];
RowNames = ["woAura","wAuta"];

idxSet = {woIdx,wIdx};
clear Q

VarNames = {'n','SAAB','Age','MIDAS','MigraineFrequency','HAseverity','Chronic','VisualAura','SensAura','SpeechAura'};
for ii = 1:2
    Q{1,ii} = sum(idxSet{ii});
end

for vv = 2:2
for ii = 1:2
    dataSet = Results.(VarNames{vv})(idxSet{ii});
    Q{vv,ii} = sum(dataSet=='Female')/(sum(dataSet=='Male')+sum(dataSet=='Female'));
end
end

for vv = 3:6
for ii = 1:2
    dataSet = Results.(VarNames{vv})(idxSet{ii});
    % Special case to remove weird age of 558
    dataSet = dataSet(dataSet~=558);
    Q{vv,ii}=sprintf('%2.1f ± %2.1f',mean(dataSet),std(dataSet));
end
end

for vv = 7:10
for ii = 1:2
    dataSet = Dx.(VarNames{vv})(idxSet{ii});
    Q{vv,ii} = sum(dataSet==1)/(sum(dataSet==1)+sum(dataSet==0));
end
end



function p = compare_correlation_coefficients(r1,r2,n1,n2)
t_r1 = 0.5*log((1+r1) /(1-r1));
t_r2 = 0.5*log((1+r2) / (1-r2));
z = (t_r1-t_r2) / sqrt(1/(n1-3)+1/(n2-3));
p = (1-normcdf (abs (z) ,0,1))*2;
end