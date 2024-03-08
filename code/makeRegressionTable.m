function Results = makeRegressionTable(tbl,predictor1,outcome1,covariates,varargin)

    %% input parser
    q = inputParser;
    q.addParameter('predictor_type',1,@isnumeric); % data format of primary predictor: 1 = linear, 2 = binomial
    q.addParameter('outcome_type',1,@isnumeric);  % data format of primary outcome: 1 = linear, 2 = binomial
    q.addParameter('smoothing',1,@isnumeric); % 1 = polychoric analysis is not smoothed, 2 = smoothed
    q.addParameter('centered',0,@isnumeric); % 0 = data are raw, 1 = data are mean subtracted
    
    q.parse(varargin{:});
    
    %% univariable analysis of primary predictor
    univar = table('Size',[nVar 4],'VariableTypes',{'double','double','double','double'},'VariableNames',{'estimate','low95','hi95','p_val'},'RowNames',VarNames);
    VarNames = mdl.CoefficientNames;
    interceptNo = length(mdl.CoefficientNames(contains(mdl.CoefficientNames,"Intercept")==1));
    nVar = length(mdl.CoefficientNames)-interceptNo;
    VarNames = VarNames(interceptNo+1:end);

    if q.Results.predictor_type==1

        for i = 1:size(covariates,1)
            for j = 1:nVar
                predicted = mdl.Coefficients.Value(i+interceptNo);
                se = mdl.Coefficients.SE(i+interceptNo);
                univar.estimate(j) = exp(predicted);
                univar.low95(j) = exp(predicted - (1.96*se));
                univar.hi95(j) = exp(predicted + (1.96*se));
                univar.p_val(j) = mdl.Coefficients.pValue(i+interceptNo);
            end
        end
    end

    %% univeriable analysis of primary outcome

    %% multiple regression analysis

end