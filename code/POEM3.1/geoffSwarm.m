function geoffSwarm(x,y,width,plotColor,markerSize,markerAlpha)

k = unique(y);
dist = arrayfun(@(x) sum(y==x),k);
maxDist = max(dist);
for ii = 1:length(k)
    subx = x + linspace(-width/2,width/2,dist(ii)) * dist(ii) / maxDist;
    suby = repmat(k(ii),size(subx));
    if maxDist>20
        suby=suby+(mod(1:1:dist(ii),2)-0.5)*max(k)/100;
    end
    scatter(subx,suby,markerSize,'o',...
        'MarkerEdgeColor','none','MarkerFaceColor',plotColor,...
        'MarkerFaceAlpha',markerAlpha);
end
end