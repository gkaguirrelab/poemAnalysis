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



%% US Map of all respondants
figHandle = figure();
set(gcf, 'color', 'none');
figuresize(4,3,'inches');
latVec = double(T.LocationLatitude);
lonVec = double(T.LocationLongitude);
gp = geoplot(latVec(allIdx),lonVec(allIdx),'o','MarkerSize',5,'MarkerEdgeColor','none','MarkerFaceColor',[1 0 0]);
geobasemap darkwater
geolimits([25 50],[-130 -60]);
a = gca();
a.AxisColor = 'none';
a.Grid = 'off';
a.Scalebar.Visible = 'off';
plotFileName = fullfile(figSaveDir,'POEM_v3.1_MapAllRespondents.pdf');
saveas(figHandle,plotFileName);


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
for vv = 1:3

    vals = double(Results.(varsToPlot{vv}));
    [~,edges] = discretize(vals(allIdx),nBins);
    X = edges(1:end-1) + diff(edges)/2;
    nexttile(vv)
    plot([0 xlimMax(vv)],[0 0],':k');

    veridicalVals = [];
    for gg = [1 3]

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
        case 2
            a.YTick = [];
        case 3
            a.YTick = [];
            for gg = [1 3]
                lgndText{gg} = sprintf([groupLabels{gg} ', n=%d'],nSubs(gg));
            end
%            lh = legend(lineHandles,lgndText,'Location','northeast');
%            lh.Box = 'off';
    end
    ylim([-0.05,ylimMax(vv)]);
    xlim([0,xlimMax(vv)]);
    a.TickDir = 'out';
%    title(varsToPlot{vv});
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
            for pp = 1:2
                lgndText{pp} = sprintf([thisPair{pp} ', n=%d'],nSubs(pp));
            end
%            lh = legend(lineHandles,lgndText,'Location','east');
%            lh.Box = 'off';
%            text(xlimMax(vv)*0.75,0.5,thisCondition,'HorizontalAlignment','right');
        else
            a.YTick = [];
        end
        ylim([-0.05,ylimMax(vv)]);
        xlim([0,xlimMax(vv)]);
        a.TickDir = 'out';
        if cc == 1
%            title(varsToPlot{vv});
        end
        if cc == length(conditionOn)
            xlabel(scoreLabel{vv});
            a.XTick = 0:xtickSpacing(vv):xlimMax(vv);
            a.XTickLabelRotation = 45;
        else
            a.XTick = [];
            a.XAxis.Visible = 'off';
        end

%        kstext = sprintf('KS = %2.2f, p = %0.1e',ks2stat,p);
%        text(xlimMax(vv)*0.05,0.7,kstext,'HorizontalAlignment','left');
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

[rho,pval]=corr(Results.AllodyniaScore(migraineIdx),Results.LightSensScore(migraineIdx),'Type','Spearman');
fprintf('Correlation of ASC-12 with Light Sensitivity in migraine: Spearman rho = %2.2f, p = %0.1e\n',rho,pval);

% Plot the light / touch sensitivity scatter for migraine with and without
% aura
figHandle = figure();
set(gcf, 'color', 'none');
figuresize(6,3,'inches');


wIdx = and(migraineIdx,contains(cellstr(Results.DxFull),'w/aura'));
woIdx = and(migraineIdx,contains(cellstr(Results.DxFull),'w/out'));

corr(Results.LightSensScore(woIdx),Results.AllodyniaScore(woIdx))
corr(Results.LightSensScore(wIdx),Results.AllodyniaScore(wIdx))

subplot(1,2,2)
scatter(Results.LightSensScore(wIdx),Results.AllodyniaScore(wIdx),25,...
    'MarkerFaceColor','b','MarkerEdgeColor','none',...
    'MarkerFaceAlpha',.25);
hold on
mdl = fitlm(Results.LightSensScore(wIdx),Results.AllodyniaScore(wIdx),...
    'RobustOpts','on');
xfit = [10:1:75]';
[ypred,yci]=predict(mdl,xfit);
plot(xfit,ypred,'-b','LineWidth',2)
plot(xfit,yci,'-b')
axis square
box off
xlabel('Light sensitivity score');
ylabel('Allodynia score');
a = gca();
a.TickDir = 'out';
a.XTick = 0:20:80;
xlim([-8 80])
ylim([-2.5 25])
a.FontSize = 10;
title('M w/Aura')


subplot(1,2,1)
scatter(Results.LightSensScore(woIdx),Results.AllodyniaScore(woIdx),25,...
    'MarkerFaceColor','r','MarkerEdgeColor','none',...
    'MarkerFaceAlpha',.25);
hold on
mdl = fitlm(Results.LightSensScore(woIdx),Results.AllodyniaScore(woIdx),...
    'RobustOpts','on');
xfit = [0:1:75]';
[ypred,yci]=predict(mdl,xfit);
plot(xfit,ypred,'-r','LineWidth',2)
plot(xfit,yci,'-r')
axis square
box off
xlabel('Light sensitivity score');
ylabel('Allodynia score');
a = gca();
a.TickDir = 'out';
a.XTick = 0:20:80;
xlim([-8 80])
ylim([-2.5 25])
a.FontSize = 10;
title('M wo/Aura')

plotFileName = fullfile(figSaveDir,'POEM_v3.1_touchLightSensCorrelation.pdf');
saveas(figHandle,plotFileName);


% Report some headache burden measures between with and without aura
figHandle = figure();
set(gcf, 'color', 'none');
figuresize(6,3,'inches');

markerSize = 5;
markerAlpha = 1;
swarmWidth = 0.75;

subplot(1,2,1)
hold on
y = Results.HAseverity(woIdx); x = 1;
geoffSwarm(x,y,swarmWidth,'r',markerSize,markerAlpha);
plot(mean(x),mean(y),'xk');
y = Results.HAseverity(wIdx); x = 2;
geoffSwarm(x,y,swarmWidth,'b',markerSize,markerAlpha);
plot(mean(x),mean(y),'xk');
title('Headache severity')
ylim([0 12]);
a=gca();
a.XTick = [1 2];
a.XTickLabel = {'without','with'};

subplot(1,2,2)
hold on
y = Results.MigraineFrequency(woIdx); x = 1;
geoffSwarm(x,y,swarmWidth,'r',markerSize,markerAlpha);
plot(mean(x),mean(y),'xk');
y = Results.MigraineFrequency(wIdx); x = 2;
geoffSwarm(x,y,swarmWidth,'b',markerSize,markerAlpha);
plot(mean(x),mean(y),'xk');
title('Headache frequency')
ylim([0 6]);
a=gca();
a.XTick = [1 2];
a.XTickLabel = {'without','with'};

plotFileName = fullfile(figSaveDir,'POEM_v3.1_freqSeveritySwarm.pdf');
saveas(figHandle,plotFileName);





