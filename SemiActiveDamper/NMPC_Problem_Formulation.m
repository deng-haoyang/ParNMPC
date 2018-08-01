clear all
addpath('../ParNMPC/')
%% Formulate an OCP using Class OptimalControlProblem

% Create an OptimalControlProblem object
OCP = OptimalControlProblem(1,... % constraints dim
                            2,... % inputs dim
                            2,... % states dim
                            0,... % parameters dim
                            5,... % T: prediction horizon
                            40);  % N: num of discritization grids

% Set the dynamic function f
a = -1;
b = -1;
f = [OCP.x(2); a * OCP.x(1) + b * OCP.x(2) * OCP.u(1)];
OCP.setf(f);
OCP.setDiscretizationMethod('Euler');

% Set the equality constraint function C
uMax =  1;
uMin =  0;
uBar = (uMax + uMin)/2;
C    = (OCP.u(1) - uBar)^2 + OCP.u(2)^2 - (uMax - uBar)^2;
OCP.setC(C);

% Set the cost function L
Q    = diag([1, 10]); 
R    = diag([0.1, 0.1]);
r    = [0,0.1];
xRef = [0;0];
uRef = [0;uMax];
L    =  0.5*(OCP.x-xRef).'*Q*(OCP.x-xRef)...
       +0.5*(OCP.u-uRef).'*R*(OCP.u-uRef)...
       -0.5*r*OCP.u;
OCP.setL(L);

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
x0 =   [1;0];

% Set the parameters
lambdaDim = OCP.dim.lambda;
muDim     = OCP.dim.mu;
uDim      = OCP.dim.u;
xDim      = OCP.dim.x;
pDim      = OCP.dim.p;
N         = OCP.N;
discretizationMethod = OCP.discretizationMethod;
isMEnabled = OCP.isMEnabled;
par      = zeros(pDim,N);

% Create an OCPSolver object
ocpSolver = OCPSolver(OCP,nmpcSolver,x0,par);

% Choose one of the following methods to provide an initial guess:
% 1. init guess by input
% lambdaInitGuess = repmat(randn(lambdaDim,1),1,N);
% muInitGuess     = repmat(randn(muDim,1),1,N);
% uInitGuess      = repmat(uRef,1,N);
% xInitGuess      = repmat(xRef,1,N);

% 2. init guess by interpolation
lambdaStart = randn(xDim,1);
muStart     = randn(muDim,1);
uStart      = uRef;
xStart      = x0;
lambdaEnd   = zeros(lambdaDim,1);
muEnd       = zeros(muDim,1);
uEnd        = uRef;
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
                                     40);
plot(x([1 2],:).');

% Get the dependent variable LAMBDA
LAMBDA = ocpSolver.getLAMBDA(x0,lambda,mu,u,x,par);

% Save to file
save GEN_initData.mat  ...
     lambdaDim muDim uDim xDim pDim N...
     x0 lambda mu u x par LAMBDA
 %% Define the controlled plant using Class DynamicSystem

% M(u,x,p)\dot(x) = f(u,x,p)
% Create a DynamicSystem object
plant = DynamicSystem(1,2,0);

% Set the dynamic function f
a = -1;
b = -1;
fPlant = [plant.x(2); a * plant.x(1) + b * plant.x(2) * plant.u(1)];
plant.setf(fPlant); % same model 

% Generate necessary files
isSIMReGen = true;
if isSIMReGen
    plant.codeGen();
end