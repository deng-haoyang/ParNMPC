clear all
addpath('../ParNMPC/')
%% Formulate an OCP using Class OptimalControlProblem

% Create an OptimalControlProblem object
OCP = OptimalControlProblem(5,... % dim of inputs 
                            4,... % dim of states 
                            0,... % dim of parameters 
                            24);  % N: num of discritization grids

% Give names to x, u, p
[y,z,v,theta] = ...
    OCP.setStateName({'y','z','v','theta'});
[F, s, C1,C2,slack] = ...
    OCP.setInputName({'F','s', 'C1','C2','slack'});

% Set the prediction horizon T
OCP.setT(1);

% Set the dynamic function f
m = 1;
I = 1;
f = [   v*cos(theta);...
        v*sin(theta);...
        F/m;...
        s/I];
OCP.setf(f);
OCP.setDiscretizationMethod('RK4');

% Set the equality constraint function C
C = [y^2    +  z^2     - C1;...
    (y-2)^2 + (z-2)^2  - C2];
OCP.setC(C); % 

% Set the cost function L
xRef = [3.5;2;0;0];
uRef = [0;0;3.5^2+2^2;1.5^2;0];
Q = diag([100,100,0.1,0.1]);
R = diag([0.1,0.1,1,1,1e3]); % try R = diag([0.1,0.1,10,10,1e3]);
L =  (OCP.x-xRef)'*Q*(OCP.x-xRef)...
   + (OCP.u-uRef)'*R*(OCP.u-uRef);
OCP.setL(L);

% Set the linear constraints G(u,x,p)>=0
G = [F + 5;...
    -F + 5;...
     s + 1;...
    -s + 1;...
     slack;...
     C1 + slack - 1;...
     C2 + slack - 1];
OCP.setG(G);

% Generate necessary files
OCP.codeGen();
%% Configrate the solver using Class NMPCSolver

% Create a NMPCSolver object
nmpcSolver = NMPCSolver(OCP);

% Configurate the Hessian approximation method
nmpcSolver.setHessianApproximation('GaussNewtonLF');

% Generate necessary files
nmpcSolver.codeGen();
%% Solve the very first OCP for a given initial state and given parameters using Class OCPSolver

% Set the initial state
x0 =   [-2; 0; 0; 0];

% Set the parameters
dim  = OCP.dim;
N    = OCP.N;
p    = zeros(dim.p,N);

% Solve the very first OCP 
solutionInitGuess.lambda = [10*rand(dim.lambda,1),zeros(dim.lambda,1)];
solutionInitGuess.mu     = 10*rand(dim.mu,1);
solutionInitGuess.u      = [0;0;3;3;1];
solutionInitGuess.x      = [x0,xRef];
solutionInitGuess.z      = ones(dim.z,N);
solutionInitGuess.LAMBDA = zeros(dim.lambda,dim.lambda,N);
solution = NMPC_SolveOffline(x0,p,solutionInitGuess,0.1,200);

plot(solution.x(1,:).',solution.x(2,:).');
hold on
circle(0,0,sqrt(1));
hold on
circle(2,2,sqrt(1));

% Save to file
save GEN_initData.mat dim x0 p N

% Set initial guess
global ParNMPCGlobalVariable
ParNMPCGlobalVariable.solutionInitGuess = solution;
%% Define the controlled plant using Class DynamicSystem

% M(u,x,p) \dot(x) = f(u,x,p)
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
plant.codeGen();
