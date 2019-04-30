clear all
addpath('../ParNMPC/')
%% Formulate an OCP using Class OptimalControlProblem

% Create an OptimalControlProblem object
OCP = OptimalControlProblem(8,... % dim of inputs 
                            14,... % dim of states 
                            7,... % dim of parameters 
                            24);  % N: num of discritization grids

% Give names to x, u, p

% Set the prediction horizon T
OCP.setT(1);

% Set the dynamic function f
OCP.setf('external');% 'external'
OCP.setDiscretizationMethod('Euler');

% Set the cost function L
q  = OCP.x(1:7,1);
dq = OCP.x(8:end,1);

Q = diag([[1, 1, 1, 1, 1, 1, 1], [1, 1, 1, 1, 1, 1, 1]*1e-1]);
R = diag([1, 1, 1, 1, 1, 1, 1]*1e-3);
qRef  = OCP.p(1:7);
dqRef = [0,0,0,0,0,0,0].';
xRef = [qRef;dqRef];
uRef = zeros(7,1);
L =    0.5*(OCP.x-xRef).'*Q*(OCP.x-xRef)...
     + 0.5*(OCP.u(1:7,:)-uRef).'*R*(OCP.u(1:7,:)-uRef)...
     + 1000*OCP.u(8)^2;
OCP.setL(L);

% Set the linear constraints G(u,x,p)>=0
G = [ OCP.u(1:7) + ones(7,1)*10;...
     -OCP.u(1:7) + ones(7,1)*10;...
      OCP.u(8);...
      dq + pi/2  + OCP.u(8);...
     -dq + pi/2  + OCP.u(8)];
OCP.setG(G);

% Generate necessary files
OCP.codeGen();
%% Configrate the solver using Class NMPCSolver

% Create a NMPCSolver object
nmpcSolver = NMPCSolver(OCP);

% Configurate the Hessian approximation method
nmpcSolver.setHessianApproximation('GaussNewton');

% Generate necessary files
nmpcSolver.codeGen();
%% Solve the very first OCP for a given initial state and given parameters using Class OCPSolver

% Set the initial state
x0 =   zeros(OCP.dim.x,1);

% Set the parameters
dim      = OCP.dim;
N        = OCP.N;
p      = zeros(dim.p,N);
p(2,:) = 0;
p(4,:) = 0;
xRef0 = [0,0,0,0,0,0,0,zeros(1,7)].';
% Solve the very first OCP 
solutionInitGuess.lambda = [zeros(dim.lambda,1),zeros(dim.lambda,1)];
solutionInitGuess.mu     = zeros(dim.mu,1);
solutionInitGuess.u      = [uRef;1];
solutionInitGuess.x      = [x0,xRef0];
solutionInitGuess.z      = ones(dim.z,N);
solution = NMPC_SolveOffline(x0,p,solutionInitGuess,1e-2,200);

% Save to file
save GEN_initData.mat dim x0 p N

% Set initial guess
global ParNMPCGlobalVariable
ParNMPCGlobalVariable.solutionInitGuess = solution;
%% Define the controlled plant using Class DynamicSystem

% M(u,x,p) \dot(x) = f(u,x,p)
% Create a DynamicSystem object
plant = DynamicSystem(7,14,0);

% Give names to x, u
% Set the dynamic function f
plant.setf('external'); % same model 

% Generate necessary files
plant.codeGen();
