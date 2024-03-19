close all
clear variables

poemAnalysis_main_v3

figSaveDir = '~/Desktop';


nBoots = 100;
nBins = 7;

migraineDx = {'migraine w/out aura','migraine w/aura'};
haFDx = {'no headache'};
migraineIdx = or(strcmp(migraineDx{1},cellstr(Results.DxFull)),...
    strcmp(migraineDx{2},cellstr(Results.DxFull)));
haFIdx = strcmp(haFDx,cellstr(Results.DxFull));
allIdx = or(migraineIdx,haFIdx);

%% US Map of Migraine respondants
figHandle = figure();
set(gcf, 'color', 'none');
figuresize(4,3,'inches');
latVec = double(T.LocationLatitude);
lonVec = double(T.LocationLongitude);
gp = geoplot(latVec(migraineIdx),lonVec(migraineIdx),'o','MarkerSize',5,'MarkerEdgeColor','none','MarkerFaceColor',[1 0 0]);
geobasemap darkwater
geolimits([25 50],[-130 -60]);
a = gca();
a.AxisColor = 'none';
a.Grid = 'off';
a.Scalebar.Visible = 'off';
plotFileName = fullfile(figSaveDir,'POEM_v3.1_MapMigraineRespondents.pdf');
saveas(figHandle,plotFileName);


%% Conditional symptom scores, version 1
varsToPlot = {'MIDAS','AllodyniaScore','LightSensScore'};
scoreLabel = {'MIDAS','allodynia','light sensitivity'};
ylimMax = [0.75,0.75,0.75,];
xlimMax = [400,25,75];
xtickSpacing = [100 5 25];
conditionOn = {'PhoticSneeze','interAllodynia','MotionSick'};
conditionPairs = {...
    {'No','Yes'},...
    {'No','Yes'},...
    {'No','Yes'},...
    };
plotPatchColors = {...
    {'k','b'},...
    {'k','m'},...
    {'k','g'}};
plotLineColors = {...
    {[0.5 0.5 0.5],[0.5 0.5 0.75]},...
    {[0.5 0.5 0.5],[0.75 0.5 0.75]},...
    {[0.5 0.5 0.5],[0.5 0.55 0.5]},...
    };

figHandle = figure();
set(gcf, 'color', 'none');
figuresize(6,6,'inches');
tiledlayout(3,3,'TileSpacing','tight','Padding','tight');

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
            idx = and(migraineIdx,strcmp(thisPair{pp},cellstr(Results.(thisCondition))));

            % Store the vals for a subsequent KS test
            veridicalVals{pp} = vals(idx);

            nSubs(pp) = sum(idx);
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
        [~,p,ks2stat] = kstest2(veridicalVals{1},veridicalVals{2});

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
        if cc == 3
            xlabel(scoreLabel{vv});
            a.XTick = 0:xtickSpacing(vv):xlimMax(vv);
            a.XTickLabelRotation = 45;
        else
            a.XTick = [];
            a.XAxis.Visible = 'off';
        end

        kstext = sprintf('KS = %2.2f, p = %0.2e',ks2stat,p);
        text(xlimMax(vv)*0.05,0.6,kstext,'HorizontalAlignment','left');


    end

end

plotFileName = fullfile(figSaveDir,'POEM_v3.1_ConditionSymptomHistograms.pdf');
saveas(figHandle,plotFileName);


%% Contingent symptom count
fprintf('Condition counts:\n');
for ii = 1:2
    for jj = 1:2
        idx = and(...
            strcmp(conditionPairs{1}{ii},cellstr(Results.(conditionOn{1}))),...
            strcmp(conditionPairs{2}{jj},cellstr(Results.(conditionOn{2})))...
            );
        idx = and(migraineIdx,idx);
        fprintf([conditionOn{1} ' - ' conditionPairs{1}{ii} '; ' conditionOn{2} ' - ' conditionPairs{2}{jj} ': n = %d\n' ],sum(idx));
    end
end


