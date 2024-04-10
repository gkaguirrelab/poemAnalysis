close all
clear variables

poemAnalysis_main_v3

figSaveDir = '~/Desktop';


nBoots = 100;
nBins = 7;

migraineDx = {'migraine w/out aura','migraine w/aura'};
probMigraine = {'probable migraine w/out aura','probable migraine w/aura'};
haFDx = {'no headache'};
nonMigHaDx = {'non-migraine headache'};
migraineIdx = or(strcmp(migraineDx{1},cellstr(Results.DxFull)),...
    strcmp(migraineDx{2},cellstr(Results.DxFull)));
otherHaIdx = or(...
    or(strcmp(probMigraine{1},cellstr(Results.DxFull)),...
    strcmp(probMigraine{2},cellstr(Results.DxFull))),...
    strcmp(nonMigHaDx,cellstr(Results.DxFull)) );
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
varsToPlot = {'MIDAS','AllodyniaScore','LightSensScore'};
scoreLabel = {'MIDAS','allodynia','light sensitivity'};
groups = {'haFIdx','otherHaIdx','migraineIdx'};
groupLabels = {'HAF','otherHA','migr'};
ylimMax = [0.75 0.75 0.75];
xlimMax = [400,25,75];
xtickSpacing = [100 5 25];
plotPatchColors = {'k','y','r'};
plotLineColors = {[0.5 0.5 0.5],[0.75 0.75 0.5],[0.75 0.5 0.5]};
figHandle = figure();
set(gcf, 'color', 'none');
figuresize(length(varsToPlot)*2,2,'inches');
tiledlayout(1,length(varsToPlot),'TileSpacing','tight','Padding','tight');
for vv = 1:length(varsToPlot)

    vals = double(Results.(varsToPlot{vv}));
    [~,edges] = discretize(vals(allIdx),nBins);
    X = edges(1:end-1) + diff(edges)/2;
    nexttile(vv)
    plot([0 xlimMax(vv)],[0 0],':k');

    veridicalVals = [];
    for gg = 1:length(groups)

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
            for gg = 1:length(groups)
                lgndText{gg} = sprintf([groupLabels{gg} ', n=%d'],nSubs(gg));
            end
            lh = legend(lineHandles,lgndText,'Location','northeast');
            lh.Box = 'off';
    end
    ylim([-0.05,ylimMax(vv)]);
    xlim([0,xlimMax(vv)]);
    a.TickDir = 'out';
    title(varsToPlot{vv});
    xlabel(scoreLabel{vv});
    a.XTick = 0:xtickSpacing(vv):xlimMax(vv);
    a.XTickLabelRotation = 45;
end
plotFileName = fullfile(figSaveDir,'POEM_v3.1_GroupSymptomHistograms.pdf');
saveas(figHandle,plotFileName);



%% Conditional symptom scores\
varsToPlot = {'MIDAS','AllodyniaScore','LightSensScore'};
scoreLabel = {'MIDAS','allodynia','light sensitivity'};
ylimMax = [0.75,0.75,0.75,];
xlimMax = [400,25,75];
xtickSpacing = [100 5 25];
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
    {'k','r'},...
    };
plotLineColors = {...
    {[0.5 0.5 0.5],[0.5 0.5 0.75]},...
    {[0.5 0.5 0.5],[0.75 0.5 0.75]},...
    {[0.5 0.5 0.5],[0.5 0.55 0.5]},...
    {[0.5 0.5 0.5],[0.75 0.5 0.5]},...
    };

figHandle = figure();
set(gcf, 'color', 'none');
figuresize(length(varsToPlot)*2,length(conditionOn)*2,'inches');
tiledlayout(length(conditionOn),length(varsToPlot),'TileSpacing','tight','Padding','tight');

for vv = 1:length(varsToPlot)

    vals = double(Results.(varsToPlot{vv}));
    [~,edges] = discretize(vals(migraineIdx),nBins);
    X = edges(1:end-1) + diff(edges)/2;

    for cc = 1:length(conditionOn)

        nexttile((cc-1)*3+vv)
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
            lh = legend(lineHandles,lgndText,'Location','east');
            lh.Box = 'off';
            text(xlimMax(vv)*0.75,0.5,thisCondition,'HorizontalAlignment','right');
        else
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
