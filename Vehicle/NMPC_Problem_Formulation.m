clear all
addpath('../ParNMPC/')
%% Formulate an OCP using Class OptimalControlProblem

% Create an OptimalControlProblem object
OCP = OptimalControlProblem(1,... % dim of equality constraints
                            4,... % dim of inputs 
                            4,... % dim of states 
                            5,... % dim of parameters
                            3,... % T: prediction horizon
                            64);  % N: num of discritization grids
% Give names to x, u, p
[y,z,v,theta] = ...
    OCP.setStateName({'y','z','v','theta'});
[F, s, slackC1,slackslackC1] = ...
    OCP.setInputName({'F','s', 'slackC1','slackslackC1'});

% Set the dynamic function f
m = 1;
I = 1;
f = [   v*cos(theta);...
        v*sin(theta);...
        F/m;...
        s/I];
OCP.setf(f);
OCP.setDiscretizationMethod('Euler');

% Set the equality constraint function C
C = [y^2 + z^2 - slackC1];
OCP.setC(C);

% Set the cost function L
xRef = [2;1;0;0];
Q = diag([10,10,0.1,0.1]);
L =  (OCP.x-xRef)'*Q*(OCP.x-xRef)...
    + 0.01*F^2 + 0.01*s^2 ...
    + 10000*slackslackC1^2;
OCP.setL(L);

% Set the bound constraints
uMax = [ 5;  1;  Inf; Inf];
uMin = [-5; -1; -Inf; 0];
uBarrierPara = ones(OCP.dim.u,1)*OCP.p(1);
OCP.setUpperBound('u',uMax,uBarrierPara);
OCP.setLowerBound('u',uMin,uBarrierPara);

% Set the linear constraints G(u,x,p)
G = [slackC1 - slackslackC1;...
     slackC1 + slackslackC1];
GMax = [ Inf; Inf];
GMin = [-Inf;  1];
GBarrierPara = ones(2,1)*OCP.p(1);
OCP.setG(G);
OCP.setUpperBound('G',GMax,GBarrierPara);
OCP.setLowerBound('G',GMin,GBarrierPara);

% Generate necessary files
isReGen = true; % is re-gen?
if isReGen
    OCP.codeGen();
end
%% Configrate the solver using Class NMPCSolver

% Create a NMPCSolver object
nmpcSolver = NMPCSolver(OCP);

% Configurate the Hessian approximation method
nmpcSolver.setHessianApproximation('Newton');

% Generate necessary files
isReGen = true; % is re-gen?
if isReGen
    nmpcSolver.codeGen();
end
%% Solve the very first OCP for a given initial state and given parameters using Class OCPSolver

% Set the initial state
x0 =   [-2; 0; 0; 0];

% Set the parameters
lambdaDim = OCP.dim.lambda;
muDim     = OCP.dim.mu;
uDim      = OCP.dim.u;
xDim      = OCP.dim.x;
pDim      = OCP.dim.p;
N         = OCP.N;
par       = zeros(pDim,N);
par(1,:)  = 1; % barrier parameter

% Create an OCPSolver object
ocpSolver = OCPSolver(OCP,nmpcSolver,x0,par);

% Choose one of the following methods to provide an initial guess:
% 1. init guess by input
% lambdaInitGuess = repmat(rand(lambdaDim,1),1,N);
% muInitGuess     = repmat(rand(muDim,1),1,N);
% uInitGuess      = repmat([0;0;0.1],1,N);
    % xInitGuess      = repmat(xRef,1,N);

% 2. init guess by interpolation
lambdaStart = rand(xDim,1);
muStart     = rand(muDim,1);
uStart      = [0;0;3;1];
xStart      = x0;
lambdaEnd   = zeros(lambdaDim,1);
muEnd       = zeros(muDim,1);
uEnd        = [0;0;3;1];
xEnd        = xRef;
[lambdaInitGuess,muInitGuess,uInitGuess,xInitGuess] = ...
    ocpSolver.initFromStartEnd(lambdaStart,muStart,uStart,xStart,...
                               lambdaEnd,  muEnd,  uEnd,  xEnd);
% 3. init guess from file
% [lambdaInitGuess,muInitGuess,uInitGuess,xInitGuess] = ...
%                         ocpSolver.initFromMatFile('GEN_initData.mat');

% Solve the OCP
[lambda,mu,u,x] = ocpSolver.OCPSolve(lambdaInitGuess,...
                                     muInitGuess,...
                                     uInitGuess,...
                                     xInitGuess,...
                                     'NMPC_Iter',...
                                     100);

plot(x(1,:).',x(2,:).');
hold on
circle(0,0,sqrt(1));
% Get the dependent variable LAMBDA
LAMBDA = ocpSolver.getLAMBDA(x0,lambda,mu,u,x,par);

% Save to file
save GEN_initData.mat  ...
     lambdaDim muDim uDim xDim pDim N...
     x0 lambda mu u x par LAMBDA
%% Define the controlled plant using Class DynamicSystem

% M(u,x,p)\dot(x) = f(u,x,p)
% Create a DynamicSystem object
plant = DynamicSystem(2,4,0);

% Give names to x, u
[y,z,v,theta] = ...
    plant.setStateName({'y','z','v','theta'});
[F,s] = ...
    plant.setInputName({'F','s'});

% Set the dynamic function f
plant.setf(f); % same model 

% Generate necessary files
isSIMReGen = true;
if isSIMReGen
    plant.codeGen();
end