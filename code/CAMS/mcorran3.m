function [SV,EV,x2,PI,PA,Y,var_scores,var_scores2] = mcorran3(X,g,varargin)
%MCORRAN2 (adapted by CPG from MCORRAN1) Multiple Correspondence Analysis Based on the Indicator Matrix.
% Statistic fundamentals of he Correspondence Analysis (CA) is presented in
% the CORRAN m-file you can find in this FEX author''s page. CA can be 
% extended to more than two categorical variables, called Multiple 
% Correspondence Analysis (MCA). 
%
% Karl Pearson (1913) developed the antecedent of CA used by Procter&Gamble
% (Horst 1935). R.A. Fisher (1940) named the approach 'reciprocal averaging'
% because is reciprocally averages row and column percents in table data
% until they are reconciled. Since reciprocal averaging was inefficient,
% Europeans such as Mosaier (1946) and Benzecri (1969) related table data
% with computer programs for principal component (factor) analysis. Burt 
% (1953) developed MCA (homogeneity analysis) of a binary indicator (or Burt)
% matrix.
%
% Here is applied to the indicator matrix (G), a binary coding matrix of the
% factors called dummy variables. The number of rows are the total sample
% items and the columns are the total categories of the variables. The
% elements in G are 1's if the item corresponding to the category of the
% variable or 0's if not.
% 
% As well as in CA, it is a decomposition of chi-square values rather than 
% the variance and is a dual eigenanalysis or Singular Value Decomposition
% (SVD). Where, each singular value is a canonical correlation. The number 
% of nonzero singular values of an indicator matrix is the total number of 
% levels minus the number of categorical variables. 
% 
% The row and column coordinates, with respect to their respective principal
% axes, may be obtained from the singular value decomposition (SVD) of the
% corresponence matrix, transformed by double-centering and standardizing. 
% The squares of the singular values are the principal inertias or 
% eigenvalues.
%
% The rows will be the points projected in a map interpreted in terms of the
% columns as reference points. Row profiles, will be represented by principal
% coordinates, and will be expressed with respect to the column vertices. In
% the same way the colums are interpreted in terms of the rows.
%
% Syntax: [SV,EV,x2,PI,PA] = function mcorran2(X,dim_var,var_names)
% 
%      
%     Input:
%          X - Data matrix=indicator matrix. Size: observations x categorical
%              variables (>2).
%          g - (added by CPG) is the variable dimensions for matrix X so it does
%               not have to be entered mid-function. The number of categories for 
%               each variable needs to be entered as a column vector.
%           var_names - (added by CPG), names of variables for plotting
%           (char)
%     Outputs:
%           SV - singular value
%           EV - inertia
%           x2 - chi squared
%           PI - percent 
%           PC - cumulative percent
%           var_scores - score for each variable across dimensions of interest (CPG added 2/24/22)
%           var_scores2 - score for the absence of each variable across dimensions of interest (CPG added 6/6/23)
%
%          Complete Multiple Correspondence Analysis
%          Pair-wise Dimensions Plots. For the vertical and horizonal lines
%              we use the hline.m and vline.m files kindly published on FEX
%              by Brandon Kuczenski [http://www.mathworks.com/matlabcentral/
%              fileexchange/1039]. For connecting lines to the originwe use
%              the plot2org published on FEX by Jos
%              [http://www.mathworks.com/matlabcentral/fileexchange/11337]
%
%  Example: From the table 15.10 (Rencher, 2002) we have a list of 12 people
%  and their categories on four variables and we are interested to make a 
%  Multiple Correspondence Analysis. NOTE. The inertias and chi-square 
%  decomposition results given in table 15.12 (p. 528) by Rencher (2002)
%  are wrong. Indicator matrix (G) is:
%                              
%       ------------------------------------------------------------
%       Person      Gender     Age     Marital Status     Hair Color
%       ------------------------------------------------------------
%         1         1  0     1  0  0        1  0          0  1  0  0
%         2         1  0     0  0  1        1  0          0  0  0  1
%         3         0  1     0  1  0        0  1          1  0  0  0
%         4         1  0     0  0  1        1  0          0  0  1  0
%         5         0  1     0  1  0        0  1          0  0  1  0
%         6         0  1     0  1  0        1  0          0  1  0  0
%         7         1  0     1  0  0        0  1          0  0  0  1
%         8         1  0     0  0  1        0  1          1  0  0  0
%         9         1  0     0  1  0        1  0          1  0  0  0
%        10         0  1     1  0  0        0  1          0  0  1  0
%        11         0  1     0  0  1        1  0          0  1  0  0
%        12         1  0     1  0  0        0  1          1  0  0  0
%       ------------------------------------------------------------    
%
%  Data matrix must be:
%     X=[1 0 1 0 0 1 0 0 1 0 0;1 0 0 0 1 1 0 0 0 0 1;0 1 0 1 0 0 1 1 0 0 0;
%        1 0 0 0 1 1 0 0 0 1 0;0 1 0 1 0 0 1 0 0 1 0;0 1 0 1 0 1 0 0 1 0 0;
%        1 0 1 0 0 0 1 0 0 0 1;1 0 0 0 1 0 1 1 0 0 0;1 0 0 1 0 1 0 1 0 0 0;
%        0 1 1 0 0 0 1 0 0 1 0;0 1 0 0 1 1 0 0 1 0 0;1 0 1 0 0 0 1 1 0 0 0];
%
%  Calling on Matlab the function: 
%             mcorran1(X)
%  Answer is:
%
%  vect_cat is the vectors for the categories of each variable : [2 3 2 4]
% 
%  Inertia and chi-square decomposition of the Multiple Correspondence Analysis
%  for the indicator matrix given.
%  ------------------------------------------------------------------------
%                                                              Cummulative       
%   Singular Value     Inertia      Chi-square     Percent       Percent   
%  ------------------------------------------------------------------------
%       0.6747          0.4552       21.8500         26.01         26.01
%       0.6568          0.4314       20.7063         24.65         50.66
%       0.5378          0.2893       13.8841         16.53         67.19
%       0.5000          0.2500       12.0000         14.29         81.48
%       0.4190          0.1756        8.4274         10.03         91.51
%       0.3568          0.1273        6.1101          7.27         98.78
%       0.1459          0.0213        1.0221          1.22        100.00
%  ------------------------------------------------------------------------
%       Total           1.7500       84.0000        100.00
%  Variable categories = 2  3  2  4
%                           P-value = 5.5511e-016; degrees of freedom = 6
%  ------------------------------------------------------------------------
% 
%  Are you interested to get the dimensions plots? (y/n): y
%  --------------
%  The pair-wise plots you can get are: 21
%  --------------
%  Dm =
%       1     2
%       1     3
%       1     4
%       1     5
%       1     6
%       1     7
%       2     3
%       2     4
%       2     5
%       2     6
%       2     7
%       3     4
%       3     5
%       3     6
%       3     7
%       4     5
%       4     6
%       4     7
%       5     6
%       5     7
%       6     7
%
%  --------------
%
%  Created by A. Trujillo-Ortiz, R. Hernandez-Walls and K. Barba-Rojo
%             Facultad de Ciencias Marinas
%             Universidad Autonoma de Baja California
%             Apdo. Postal 453
%             Ensenada, Baja California
%             Mexico.
%             atrujo@uabc.mx
%  Copyright. September 24, 2008.
%
%  To cite this file, this would be an appropriate format:
%  Trujillo-Ortiz, A., R. Hernandez-Walls and K. Barba-Rojo. (2008). mcorran1:
%    Multiple Correspondence Analysis Based on the Indicator Matrix. A MATLAB file. [WWW document].
%    URL http://mathworks.com/matlabcentral/fileexchange/22154
%
%  Reference:
%  Rencher, A. C. (2000), Methods of Multivariate Analysis. 2nd ed. 
%       John Wiley & Sons. p. 514-525
%


Q = inputParser;
Q.addParameter('var_names',num2str((1:1:size(X,2))'),@ischar);
Q.addParameter('fig_num',1,@isnumeric);
Q.addParameter('origin_of_ref',true,@islogical);
Q.addParameter('origin_of_quad',true,@islogical);

Q.parse(varargin{:});


p = length(g); %number of categorical variables
b1 = size(X,2); %number of categories
b2 = sum(g); %input number of categories
if b1 ~= b2
    disp('Warning:the number of categories in the input vector doesn''t correspond to the given in the indicator matrix. Please, check.');
    return
end
n = size(X,1);
N = sum(sum(X));
P = X/N; %correspondence matrix
r = sum(P,2); %row total (row mass)
c = sum(P,1); %column total (column mass)
Dr = diag(r); %row diagonal matrix
Dc = diag(c); %column diagonal matrix
Z = sqrt(inv(Dr))*(P-r*c)*sqrt(inv(Dc));
%non-trivial eigenvalues (maximum number of dimensions)
if n >= p
    q = sum(g)-p; 
else
    q = p-n;
end
[U,S,V] = svd(Z); %singular values
SV = diag(S); %singular values
SV = SV(1:q); %singular value equal to zero is deleted
EV = SV.^2; %eigenvalues (inertia)
PI = EV./sum(EV)*100; %percent of inertia
PA = cumsum(PI); %cumulative percent of inertia
x2 = N*EV; %chi-square
A = sqrt(Dr)*U;
B = sqrt(Dc)*V;
X2 = N*trace(inv(Dr)*(P-r*c)*inv(Dc)*(P-r*c)'); %total chi-square
v = prod(g-1); %degrees of freedom
P = 1-chi2cdf(X2,v); %P-value

% MCA table
disp(' ')
disp('Inertia and chi-square decomposition of the Multiple Correspondence Analysis')
disp('for the indicator matrix given.')
fprintf('------------------------------------------------------------------------\n');  
disp('                                                            Cummulative       ');
disp(' Singular Value     Inertia      Chi-square     Percent       Percent   ');  
fprintf('------------------------------------------------------------------------\n');
fprintf(' %10.4f      %10.4f    %10.4f    %10.2f    %10.2f\n',[SV,EV,x2,PI,PA].');
fprintf('------------------------------------------------------------------------\n');
fprintf('     Total   %14.4f %13.4f %13.2f\n', sum(EV),N*sum(EV),sum(PI));
disp(['Variable categories = ',g]);
disp(['                         P-value = ',num2str(P) '; ' 'degrees of freedom = ',num2str(v) '']);
fprintf('------------------------------------------------------------------------\n');
disp(' ');
Dm = [];
for i = 1:q
    for s = i+1:q
        if s ~= i
            d = [i s];
            Dm = [Dm;d];
        end
    end
end

% Scree plot
figure(Q.Results.fig_num)
hold on
bar(1:1:length(PI),PI,'FaceColor',[0.5 0.5 0.5])
plot(1:1:length(PA),PA,'-k')
ax=gca; ax.TickDir='out'; ax.Box='off';
title('Dimensions')
ylabel('Percent Variance')

% plot variables as a function of specified dimensions
co = (q*(q - 1))/2;
doi = input('Highest dimension of interest (must be even number): ');

figure(Q.Results.fig_num+1)
counter=1;
var_scores = zeros(doi,length(g));
var_scores2 = zeros(doi,length(g));
X = inv(Dr)*A*S; %column coordinates (observations)
X = X(:,1:q);
Y = inv(Dc)*B*S'; %row coordinates (categorical variables)
Y = Y(:,1:q);
for I=1:doi/2
    subplot(2,ceil(doi/4),I)
    pol = 0;
    hold on
    for c = 1:length(g)
        plot(Y(1+pol:g(c)+pol,counter),Y(1+pol:g(c)+pol,(counter+1)),'*k');
        A1 = Y(1+pol:g(c)+pol,counter);
        A2 = Y(1+pol:g(c)+pol,(counter+1));
        var_scores(counter,c) = A1(end);
        var_scores(counter+1,c) = A2(end);
        var_scores2(counter,c) = A1(1);
        var_scores2(counter+1,c) = A2(1);
        for Kl = 1:length(A1)
            text(A1(Kl)+.02,A2(Kl)+.02,[num2str(Kl) ' ' Q.Results.var_names(c,:)]);
        end
        pol = g(c)+pol;
    end
    ax=gca; ax.TickDir='out'; ax.Box='off';
    title('Variable levels of MCA');      
    xlabel(['Dimension ' num2str(counter)';]);
    ylabel(['Dimension ' num2str(counter+1)';]);
    
    if Q.Results.origin_of_ref==1
        % origin of reference
            pol = 0;
            for c = 1:length(g)
                hold on
                A1 = Y(1+pol:g(c)+pol,counter);
                A2 = Y(1+pol:g(c)+pol,(counter+1));
                plot2org(A1,A2,'--k'), %this m-file was taken from Jos's plot2org
                pol = g(c)+pol;
            end
    end

    
    if Q.Results.origin_of_ref==1
        % origin quadrature
        hline(0,'k'); %this m-file was taken from Brandon Kuczenski's hline and vline zip
        vline(0,'k'); %this m-file was taken from Brandon Kuczenski's hline and vline zip
    end
    counter=counter+2;
end

end
