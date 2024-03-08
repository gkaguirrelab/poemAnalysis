function Results = runPolychor(MSCORES,var_names,varargin)

    %% input parser
    q = inputParser;
    q.addParameter('missing',99,@isnumeric); % how missing data are identified
    q.addParameter('repetitions',1000,@isnumeric); % number of times polychoric analysis is replicated
    q.addParameter('smoothing',1,@isnumeric); % 1 = polychoric analysis is not smoothed, 2 = smoothed
    q.addParameter('centered',0,@isnumeric); % 0 = data are raw, 1 = data are mean subtracted
    
    q.parse(varargin{:});
    
    %%
    [PA,EIGENS,MCORR] = polychoric_CPGadapted(MSCORES,q.Results.missing,q.Results.repetitions,q.Results.smoothing,q.Results.centered);
    
    % calculate coefficients
    coefficients = zeros(size(MSCORES,1),PA);
    for x = 1:size(MSCORES,1)
        for y = 1:size(MSCORES,2)
            temp1 = MSCORES(x,:);
            temp2 = MCORR(:,y);
            r = temp1*temp2;
            coefficients(x,y) = r;
        end
    end
    
    
    Results.mscores = MSCORES;
    Results.pa = PA;
    Results.eigens = EIGENS;
    Results.mcorr = MCORR;
    Results.coefficients = coefficients;
    
    % plots the eigen values (bars) and random eigen values (line) for each
    % dimension
    figure
    bar(1:length(EIGENS),EIGENS(:,1))
    hold on
    plot(1:length(EIGENS),EIGENS(:,2),'--k')
    
    % plots the first two dimensions
    figure
    biplot(MCORR(:,1:2),'Scores',coefficients(:,1:2),'VarLabels',var_names)

end