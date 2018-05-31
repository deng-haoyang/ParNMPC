clear all
addpath('../ParNMPC/')
%% Formulate an OCP using Class OptimalControlProblem

% Create an OptimalControlProblem object
OCP = OptimalControlProblem(0,... % constraints dim
                            4,... % inputs dim
                            9,... % states dim
                            5,... % parameters dim (position reference)
                            0.5,... % T: prediction horizon
                            40);  % N: num of discritization grids
% Give names to x, u, p
[X,dX,Y,dY,Z,dZ,Gamma,Beta,Alpha] = ...
    OCP.setStateName({'X','dX','Y','dY','Z','dZ','Gamma','Beta','Alpha'});
[a,omegaX,omegaY,omegaZ] = ...
    OCP.setInputName({'a','omegaX','omegaY','omegaZ'});
[XSP,YSP,ZSP,T] = ...
    OCP.setParameterName({'XSP','YSP','ZSP','T'},[1 2 3 5]);

% Reset the prediction horizon T to be variable
OCP.setT(T);

% Set the dynamic function f
g = 9.81;
f = [   dX;...
        a*(cos(Gamma)*sin(Beta)*cos(Alpha) + sin(Gamma)*sin(Alpha));...
        dY;...
        a*(cos(Gamma)*sin(Beta)*sin(Alpha) - sin(Gamma)*cos(Alpha));...
        dZ;...
        a*cos(Gamma)*cos(Beta) - g;...
       (omegaX*cos(Gamma) + omegaY*sin(Gamma))/cos(Beta);...
       -omegaX*sin(Gamma) + omegaY*cos(Gamma);...
        omegaX*cos(Gamma)*tan(Beta) + omegaY*sin(Gamma)*tan(Beta) + omegaZ];
OCP.setf(f);
OCP.setDiscretizationMethod('Euler');

% Set the cost function L
Q = diag([10, 1, 10, 1, 10, 1, 1, 1, 1]);
R = diag([1, 1, 1, 1])*0.1;
uMax = [11;1; 1; 1];
uMin = [0;-1;-1;-1];
xRef = [XSP;0;YSP;0;ZSP;0;0;0;0];
uRef = [g;0;0;0];
L =    0.5*(OCP.x-xRef).'*Q*(OCP.x-xRef)...
     + 0.5*(OCP.u-uRef).'*R*(OCP.u-uRef)...
     - sum(OCP.p(4).*log(uMax-OCP.u))...
     - sum(OCP.p(4).*log(OCP.u-uMin));
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
x0 =   [1;0;1;0;1;0;0;0;0];

% Set the parameters
lambdaDim = OCP.dim.lambda;
muDim     = OCP.dim.mu;
uDim      = OCP.dim.u;
xDim      = OCP.dim.x;
pDim      = OCP.dim.p;
N         = OCP.N;
discretizationMethod = OCP.discretizationMethod;
isMEnabled = OCP.isMEnabled;
xRef = [0;0;0;0;0;0;0;0;0];
par      = zeros(pDim,N);
par(1,:) = 0;   % X setpoint
par(2,:) = 0;   % Y setpoint
par(3,:) = 0;   % Z setpoint 
par(4,:) = 0.5; % barrier parameter
par(5,:) = 0.5; % prediction horizon

% Create an OCPSolver object
ocpSolver = OCPSolver(OCP,nmpcSolver,x0,par);

% Choose one of the following methods to provide an initial guess:
% 1. init guess by input
% lambdaInitGuess = repmat(randn(lambdaDim,1),1,N);
% muInitGuess     = repmat(randn(muDim,1),1,N);
% uInitGuess      = repmat(uRef,1,N);
% xInitGuess      = repmat(xRef,1,N);
% 2. init guess by interpolation
% lambdaStart = randn(xDim,1);
% muStart     = randn(muDim,1);
% uStart      = uRef;
% xStart      = x0;
% lambdaEnd   = zeros(lambdaDim,1);
% muEnd       = zeros(muDim,1);
% uEnd        = uRef;
% xEnd        = xRef;
% [lambdaInitGuess,muInitGuess,uInitGuess,xInitGuess] = ...
%     ocpSolver.initFromStartEnd(lambdaStart,muStart,uStart,xStart,...
%                                lambdaEnd,  muEnd,  uEnd,  xEnd);
% 3. init guess from file
[lambdaInitGuess,muInitGuess,uInitGuess,xInitGuess] = ...
                        ocpSolver.initFromMatFile('GEN_initData.mat');

% Solve the OCP
[lambda,mu,u,x] = ocpSolver.OCPSolve(lambdaInitGuess,...
                                              muInitGuess,...
                                              uInitGuess,...
                                              xInitGuess,...
                                              'fsolve');%NMPCSolver_GaussNewton
plot(x([1 3 5],:).');

% Get the dependent variable LAMBDA
LAMBDA = ocpSolver.getLAMBDA(x0,lambda,mu,u,x,par);

% Save to file
save GEN_initData.mat  ...
     lambdaDim muDim uDim xDim pDim N...
     x0 lambda mu u x par LAMBDA...
     discretizationMethod isMEnabled
%% Define the controlled plant using Class DynamicSystem

% M(u,x,p)\dot(x) = f(u,x,p)
% Create a DynamicSystem object
plant = DynamicSystem(4,9,0);

% Give names to x, u
[X,dX,Y,dY,Z,dZ,Gamma,Beta,Alpha] = ...
    plant.setStateName({'X','dX','Y','dY','Z','dZ','Gamma','Beta','Alpha'});
[a,omegaX,omegaY,omegaZ] = ...
    plant.setInputName({'a','omegaX','omegaY','omegaZ'});

% Set the dynamic function f
plant.setf(f); % same model 

% Generate necessary files
isSIMReGen = true;
if isSIMReGen
    plant.codeGen();
end