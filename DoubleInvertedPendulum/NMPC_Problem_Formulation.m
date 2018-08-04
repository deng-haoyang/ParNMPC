clear all
addpath('../ParNMPC/')
%% Formulate an OCP using Class OptimalControlProblem

% Create an OptimalControlProblem object
OCP = OptimalControlProblem(0,... % constraints dim
                            1,... % inputs dim
                            6,... % states dim
                            8,... % parameters dim
                            1.5,... % T: prediction horizon
                            48);  % N: num of discritization grids
% Give names to x, u, p
[X,Theta1,Theta2,dX,dTheta1,dTheta2] = ...
    OCP.setStateName({'X','Theta1','Theta2','dX','dTheta1','dTheta2'});
[F] = ...
    OCP.setInputName({'F'});

% Set the dynamic function f
g  = 9.81;
m0 = 1.0;
m1 = 0.8;
m2 = 0.5;
L1 = 0.3;
L2 = 0.45;
d1 = m0+m1+m2;
d2 = (0.5*m1+m2)*L1;
d3 = 0.5*m2*L2;
d4 = (1/3*m1+m2)*L1*L1;
d5 = 0.5*m2*L1*L2;
d6 = 1/3*m2*L2*L2;
f1 = (0.5*m1+m2)*L1*g;
f2 = 0.5*m2*L2*g;
Ds = [d1              d2*cos(X)        d3*cos(Theta1);...
      d2*cos(X)       d4               d5*cos(X-Theta1);...
      d3*cos(Theta1)  d5*cos(X-Theta1) d6];
Cs = [0 -d2*sin(X)*dX      -d3*sin(Theta1)*dTheta1;...
      0  0                    d5*sin(X-Theta1)*dTheta1;...
      0 -d5*sin(X-Theta1)*dX  0];
Gs = [0;...
     -f1*sin(X);...
     -f2*sin(Theta1)];
Hs = [1 0 0].';
f = [ dX;...
      dTheta1;
      dTheta2;
      Hs*F-Gs-Cs*[dX dTheta1 dTheta2].'];
M = blkdiag(eye(3),Ds);
OCP.setf(f);
OCP.setM(M);
OCP.setDiscretizationMethod('Euler');

% Set the cost function L
lambdaDim = OCP.dim.lambda;
muDim     = OCP.dim.mu;
uDim      = OCP.dim.u;
xDim      = OCP.dim.x;
pDim      = OCP.dim.p;
N         = OCP.N;
Q = diag(OCP.p(1:6));
R = diag(OCP.p(7));
xRef  = [0;0;0;0;0;0];
uRef  = 0;
L     =   0.5*(OCP.x-xRef).'*Q*(OCP.x-xRef)...
        + 0.5*(OCP.u-uRef).'*R*(OCP.u-uRef);
L     = L*OCP.deltaTau;
OCP.setL(L);

% Set the bound constraints
uMax  =  10;
uMin  = -10;
uBarrierPara = OCP.p(8);
OCP.setUpperBound('u',uMax,uBarrierPara);
OCP.setLowerBound('u',uMin,uBarrierPara);

% Generate necessary files
isReGen = true; % is re-gen?
if isReGen
    OCP.codeGen();
end
%% Configrate the solver using Class NMPCSolver

% Create a NMPCSolver object
nmpcSolver = NMPCSolver(OCP);

% Configurate the Hessian approximation method
nmpcSolver.setHessianApproximation('GaussNewton');

% Generate necessary files
isReGen = true; % is re-gen?
if isReGen
    nmpcSolver.codeGen();
end
%% Solve the very first OCP for a given initial state and given parameters using Class OCPSolver

% Set the initial state
x0   = [0;pi;pi;0;0;0];

% Set the parameters
QDiagVal = [10;10;10;1;1;1];
RDiagVal = 0.1;
par = zeros(pDim,N);
par(1:7,:) = repmat([QDiagVal;RDiagVal],1,N);
par(1:7,end) = [100;100;100;10;10;10;0.1]; % terminal penlty
par(8,:) = 0.1; % barrier parameter

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
plot(x([2 3],:).');
figure(2);
plot(u(1,:).');
figure(3);
plot(x(1,:).');

% Get the dependent variable LAMBDA
LAMBDA = ocpSolver.getLAMBDA(x0,lambda,mu,u,x,par);

% Get the cost
cost = ocpSolver.getCost(u,x,par);

% Save to file
save GEN_initData.mat  ...
     lambdaDim muDim uDim xDim pDim N...
     x0 lambda mu u x par LAMBDA
	 
%% Define the controlled plant using Class DynamicSystem

% M(u,x,p)\dot(x) = f(u,x,p)
% Create a DynamicSystem object
plant = DynamicSystem(1,6,0);

% Give names to x, u
[X,Theta1,Theta2,dX,dTheta1,dTheta2] = ...
    plant.setStateName({'X','Theta1','Theta2','dX','dTheta1','dTheta2'});
[F] = ...
    plant.setInputName({'F'});

% Set the dynamic function f
plant.setf(f); % same model 
plant.setM(M); % same model 

% Generate necessary files
isSIMReGen = true;
if isSIMReGen
    plant.codeGen();
end