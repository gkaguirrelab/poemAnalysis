function [cams] = runCAMS(tbl,var_pres,var_abs,varargin)

% input parser
q = inputParser;
q.addParameter('MCA_no',4,@isnumeric); % number of MCA dimensions to save
q.addParameter('Title','CAMS',@isstring); % graph title
q.addParameter('xColor',0.7,@isnumeric); % color multiplier for third graphed dimension
q.addParameter('xBubble',60,@isnumeric); % size multiplier for the bubble
q.addParameter('graphDim',1:3,@isnumeric); % 3 dimensions to graph
q.addParameter('Sn',[1 1 1],@isnumeric); % controls the sign of the three dimensions

q.parse(varargin{:});


%% 
Sx = table2array(tbl);

binary_hx = cell(size(Sx));
binary_struct = NaN*ones(size(Sx,2),1);
for x = 1:size(Sx,2)
    temp = Sx(:,x);
    outcome=unique(temp);
        for y=1:size(Sx,1)
            binary_struct(x,:) = 2;
                switch temp(y)
                    case outcome(1)
                        binary_hx{y,x} = [1 0];
                    case outcome(2)
                        binary_hx{y,x} = [0 1];
                end
        end
end


% concatonate each subjects binary outcomes
binary_Hx = NaN*ones(size(binary_hx,1),size(var_pres,1)*2);
temp = [];
for x=1:size(binary_hx,1)
    for y=1:size(binary_hx,2)
        temp = cat(2,temp,cell2mat(binary_hx(x,y)));
    end
    binary_Hx(x,:) = temp;
    temp=[];
end

[~,~,x2,PI,~,MCA,scores_pres,scores_abs] = mcorran3(binary_Hx,binary_struct','var_names',var_pres);

MCA_score = NaN*ones(size(binary_Hx,1),q.Results.MCA_no);
for x = 1:size(binary_Hx,1)
    for y = 1:q.Results.MCA_no
        temp1 = binary_Hx(x,:);
        temp2 = MCA(:,y);
        r=temp1*temp2;
        MCA_score(x,y) = r;
    end
end

MCA_score(:,1) = q.Results.Sn(1)*MCA_score(:,1);
MCA_score(:,2) = q.Results.Sn(2)*MCA_score(:,2);
MCA_score(:,3) = q.Results.Sn(3)*MCA_score(:,3);

figure
hold on
ax = gca; ax.TickDir = 'out'; ax.Box = 'off'; ax.XLim = [-3 3]; ax.YLim = [-3 3];
title(q.Results.Title)
xlabel('Dimension 1')
ylabel('Dimension 2')



for x = 1:size(var_pres,1)
    C = q.Results.Sn(3)*scores_pres(q.Results.graphDim(3),x)*q.Results.xColor;
    if C>0
        dim3 = [1 1-C 1-C];
    else
        dim3 = [1+C 1+C 1];
    end
    aSx = Sx(:,x);
    HAa_prct = length(aSx(aSx==1))./length(aSx);
    plot(q.Results.Sn(1)*scores_pres(q.Results.graphDim(1),x),q.Results.Sn(2)*scores_pres(q.Results.graphDim(2),x),'ok','MarkerSize',round(q.Results.xBubble*HAa_prct),'MarkerFaceColor',dim3)
    text(q.Results.Sn(1)*scores_pres(q.Results.graphDim(1),x)+0.01,q.Results.Sn(2)*scores_pres(q.Results.graphDim(2),x)+0.01,var_pres(x,:))
    plot(q.Results.Sn(1)*scores_abs(q.Results.graphDim(1),x),q.Results.Sn(2)*scores_abs(q.Results.graphDim(2),x),'ok','MarkerSize',2,'MarkerFaceColor','k')
    text(q.Results.Sn(1)*scores_abs(q.Results.graphDim(1),x)+0.01,q.Results.Sn(2)*scores_abs(q.Results.graphDim(2),x)+0.01,var_abs(x,:))
end

cams.x2 = x2;
cams.PI = PI;
cams.scores_pres = scores_pres;
cams.scores_abs = scores_abs;
cams.MCA_model = MCA;
cams.MCA_score = MCA_score;

end