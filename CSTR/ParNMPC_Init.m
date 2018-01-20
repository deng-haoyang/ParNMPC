%% For solving the very first optimal control problem
% Date: Jan 21, 2018
% Author: Haoyang Deng
%__________________________________________________________________
% parameters need to be defined: all of the global variables
% functions need to be defined: none
%__________________________________________________________________
addpath('./Functions/');

%% Initialize
%__________________________________________________________________
% sizes of parameters:
% initMethod: 1 x 1
% lambdaInitGuess: N*lambdaDim x 1
% muInitGuess: N*muDim x 1
% uInitGuess: N*uDim x 1
% xInitGuess: N*xDim x 1
% lambdaStartValueGuess lambdaFinalValueGuess: lambdaDim x 1
% muStartValueGuess muFinalValueGuess: muDim x 1
% uStartValueGuess uFinalValueGuess: uDim x 1
% xStartValueGuess xFinalValueGuess: xDim x 1
%__________________________________________________________________

global initMethod lambdaInitGuess muInitGuess uInitGuess xInitGuess...
       lambdaStartValueGuess  lambdaFinalValueGuess  muStartValueGuess...
       muFinalValueGuess  uStartValueGuess uFinalValueGuess ...
       xStartValueGuess  xFinalValueGuess
   
INIT_BY_INPUT        = 0;
INIT_BY_REF_GUESS    = 1;
INIT_BY_FILE         = 2;

%>>>>>>------------------FOR_USER---------------------------->>>>>>
initMethod = INIT_BY_FILE;
% INIT_BY_INPUT 
lambdaInitGuess = repmat(randn(lambdaDim,1),N,1);
muInitGuess     = repmat(randn(muDim,1),N,1);
uInitGuess      = repmat(randn(uDim,1),N,1);
xInitGuess      = repmat(x0Value,N,1);
% INIT_BY_REF_GUESS
lambdaStartValueGuess = randn(xDim,1);
lambdaFinalValueGuess = zeros(lambdaDim,1);
muStartValueGuess     = randn(muDim,1);
muFinalValueGuess     = zeros(muDim,1);
uStartValueGuess      = randn(uDim,1);
uFinalValueGuess      = uRef;
xStartValueGuess      = x0Value;
xFinalValueGuess      = xRef;
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

% init solution by the selected method
run('./Functions/Func_InitSolution.m');
%% Find the 1st optimal solution by fsolve
disp('Finding the optimal solution by fsolve......');
fun = @Func_KKTs;
% trust-region-dogleg levenberg-marquardt  trust-region-reflective
options = optimoptions( 'fsolve',...
                        'Algorithm','levenberg-marquardt',...
                        'Display','final',...
                        'PlotFcn',@optimplotfirstorderopt,...
                        'Diagnostics','off',...
                        'MaxFunctionEvaluations',300000,...
                        'MaxIterations',2000);
[s_fslove,fval,exitflag,output] = fsolve(fun,initSolution,options);
%% Init NMPC
if exitflag >= -1%% if optimum found or program stoped
    initSolution = s_fslove;
    save('initialSolution.mat','initSolution');
    % init variables
    run('./Functions/Func_InitNMPC.m');
    % plot
    run('./Functions/Func_PlotInitSolution.m');
    % save problem structures
    save GEN_initData.mat  ...
         lambdaDim muDim uDim xDim pDim subDim uLocation...
         x0Value Ts simuLength...
         currentIteration theta lambdaNextVal xPrevVal ...
         MaxIterNum tolerance pVal N pSimVal pSimDim ...
         isHxxExplicit FDStep 
    disp('Solution found and saved to initialSolution.mat.');
    disp('Maybe it is not optimal. Try to initialize from different methods or values.');
    disp('If you want to initialize from this file, please choose INIT_BY_FILE.');
    disp('Problem initialized!');
else
    disp('Optimal solution NOT FOUND! Please try another initialization method.');
end
%_END_OF_FILE_