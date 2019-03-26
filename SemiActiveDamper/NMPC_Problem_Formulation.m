clear all
addpath('../ParNMPC/')
%% Formulate an OCP using Class OptimalControlProblem

% Create an OptimalControlProblem object
OCP = OptimalControlProblem(1,... % dim of inputs 
                            2,... % dim of states 
                            0,... % dim of parameters 
                            12);  % N: num of discritization grids

% Set the prediction horizon T
OCP.setT(1);

% Set the dynamic function f
a = -1;
b = -1;
f = [OCP.x(2); a * OCP.x(1) + b * OCP.x(2) * OCP.u(1)];
OCP.setf(f);
OCP.setDiscretizationMethod('Euler');

% Set the cost function L
Q    = diag([10, 10]); 
R    = 0.01;
xRef = [0;0];
uRef = 0.5;
L    =  0.5*(OCP.x-xRef).'*Q*(OCP.x-xRef)...
       +0.5*(OCP.u-uRef).'*R*(OCP.u-uRef);
OCP.setL(L);

% Set the linear constraints G(u,x,p)>=0
G = [OCP.u(1);...
     1 - OCP.u(1)];
OCP.setG(G);

% Generate necessary files
OCP.codeGen();
%% Configrate the solver using Class NMPCSolver

% Create a NMPCSolver object
nmpcSolver = NMPCSolver(OCP);

% Configurate the Hessian approximation method
nmpcSolver.setHessianApproximation('Newton');

% Generate necessary files
nmpcSolver.codeGen();
%% Solve the very first OCP for a given initial state and given parameters using Class OCPSolver

% Set the initial state
x0 =   [1;0];

% Set the parameters
dim = OCP.dim;
N   = OCP.N;
p   = zeros(dim.p,N);

% Solve the very first OCP 
solutionInitGuess.lambda = [randn(dim.lambda,1),zeros(dim.lambda,1)];
solutionInitGuess.mu     = randn(dim.mu,1);
solutionInitGuess.u      = uRef;
solutionInitGuess.x      = [x0,xRef];
solutionInitGuess.z      = ones(dim.z,N);
solution = NMPC_SolveOffline(x0,p,solutionInitGuess,1e-4,1000);

plot(solution.x(1,:).');

% Save to file
save GEN_initData.mat dim x0 p N

% Set initial guess
global ParNMPCGlobalVariable
ParNMPCGlobalVariable.solutionInitGuess = solution;
%% Define the controlled plant using Class DynamicSystem

% M(u,x,p) \dot(x) = f(u,x,p)
% Create a DynamicSystem object
plant = DynamicSystem(1,2,0);

g = 9.81;
a = -1;
b = -1;
fPlant = [plant.x(2); a * plant.x(1) + b * plant.x(2) * plant.u(1)];

% Set the dynamic function f
plant.setf(fPlant); % same model 

% Generate necessary files
plant.codeGen();
