close all
clear variables

poemAnalysis_main_v3

nBoots = 100;
nBins = 7;

migraineDx = {'migraine w/out aura','migraine w/aura'};
haFDx = {'no headache'};
migraineIdx = or(strcmp(migraineDx{1},cellstr(Results.DxFull)),...
    strcmp(migraineDx{2},cellstr(Results.DxFull)));
haFIdx = strcmp(haFDx,cellstr(Results.DxFull));
allIdx = or(migraineIdx,haFIdx);

varsToPlot = {'LightSensScore','AllodyniaScore','MIDAS'};
scoreLabel = {'light sensitivity','allodynia','MIDAS'};
ylimMax = [0.5,0.75,0.75];
conditionOn = {'PhoticSneeze','MotionSick','interAllodynia'};
conditionPairs = {...
    {'No','Yes'},...
    {'No','Yes'},...
    {'No','Yes'},...
    };
plotPairColors = {'k','r'};

for vv = 1:length(varsToPlot)

    figure
    figuresize(6,2,'inches');
    tiledlayout(1,length(conditionOn),'TileSpacing','tight','Padding','tight');

    vals = double(Results.(varsToPlot{vv}));
    [~,edges] = discretize(vals(migraineIdx),nBins);
    X = edges(1:end-1) + diff(edges)/2;

    for cc = 1:length(conditionOn)

        nexttile
        thisCondition = conditionOn{cc};
        thisPair = conditionPairs{cc};

        for pp = 1:length(thisPair)
            
            idx = and(migraineIdx,strcmp(thisPair{pp},cellstr(Results.(thisCondition))));
            Yboot = [];
            for bb = 1:nBoots
                bootIdx = datasample(find(idx),sum(idx));
                Y = histcounts(vals(bootIdx),edges);
                Yboot(bb,:) = Y ./ sum(Y);
            end
            Y = mean(Yboot,1);
            Ysem = std(Yboot,[],1);
            patch([X,fliplr(X)],[Y+Ysem,fliplr(Y-Ysem)],plotPairColors{pp},'FaceAlpha',0.2,'EdgeColor','none');
            hold on
            plot(X,Y,'-o','Color',plotPairColors{pp});
        end
        
        title(conditionOn{cc});
        xlabel(scoreLabel{vv}); ylabel('Proportion subjects');
        ylim([0,ylimMax(vv)]);
        a = gca();
        a.YTick = 0:0.25:ylimMax(vv);
    end

end