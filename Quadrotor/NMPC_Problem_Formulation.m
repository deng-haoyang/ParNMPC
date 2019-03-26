clear all
addpath('../ParNMPC/')
%% Formulate an OCP using Class OptimalControlProblem

% Create an OptimalControlProblem object
OCP = OptimalControlProblem(5,... % dim of inputs 
                            9,... % dim of states 
                            3,... % dim of parameters 
                            48);  % N: num of discritization grids

% Give names to x, u, p
[X,dX,Y,dY,Z,dZ,Gamma,Beta,Alpha] = ...
    OCP.setStateName({'X','dX','Y','dY','Z','dZ','Gamma','Beta','Alpha'});
[a,omegaX,omegaY,omegaZ,slack] = ...
    OCP.setInputName({'a','omegaX','omegaY','omegaZ','slack'});
[XSP,YSP,ZSP] = ...
    OCP.setParameterName({'XSP','YSP','ZSP'},[1 2 3]);

% Set the prediction horizon T
OCP.setT(2);

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
R = diag([0.1, 0.1, 0.1, 0.1]);
xRef = [XSP;0;YSP;0;ZSP;0;0;0;0];

uRef = [g;0;0;0];
L =    0.5*(OCP.x-xRef).'*Q*(OCP.x-xRef)...
     + 0.5*(OCP.u(1:4)-uRef).'*R*(OCP.u(1:4)-uRef)...
     + 1e5*slack^2;
OCP.setL(L);

% Set the linear constraints G(u,x,p)>=0
G =-[OCP.u(1:4) - [11;1;1; 1];...
    -OCP.u(1:4) - [0;1;1;1];...
    -slack;...
     Gamma - slack - 0.2;...
    -Gamma - slack - 0.2;...
     Beta  - slack - 0.2;...
    -Beta  - slack - 0.2;...
     Alpha - slack - 0.2;...
    -Alpha - slack - 0.2];
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
x0 =   [1;0;1;0;1;0;0;0;0];

% Set the parameters
dim      = OCP.dim;
N        = OCP.N;
p      = zeros(dim.p,N);
p(1,:) = 0;   % X setpoint
p(2,:) = 0;   % Y setpoint
p(3,:) = 0;   % Z setpoint 

% Solve the very first OCP 
solutionInitGuess.lambda = [randn(dim.lambda,1),zeros(dim.lambda,1)];
solutionInitGuess.mu     = randn(dim.mu,1);
solutionInitGuess.u      = [uRef;1];
solutionInitGuess.x      = [x0,[0;0;0;0;0;0;0;0;0]];
solutionInitGuess.z      = ones(dim.z,N);
solution = NMPC_SolveOffline(x0,p,solutionInitGuess,0.01,1000);

plot(solution.x([1 3 5],:).');

% Save to file
save GEN_initData.mat dim x0 p N

% Set initial guess
global ParNMPCGlobalVariable
ParNMPCGlobalVariable.solutionInitGuess = solution;
%% Define the controlled plant using Class DynamicSystem

% M(u,x,p) \dot(x) = f(u,x,p)
% Create a DynamicSystem object
plant = DynamicSystem(4,9,0);

% Give names to x, u
[X,dX,Y,dY,Z,dZ,Gamma,Beta,Alpha] = ...
    plant.setStateName({'X','dX','Y','dY','Z','dZ','Gamma','Beta','Alpha'});
[a,omegaX,omegaY,omegaZ] = ...
    plant.setInputName({'a','omegaX','omegaY','omegaZ'});
g = 9.81;
fPlant = [  dX;...
            a*(cos(Gamma)*sin(Beta)*cos(Alpha) + sin(Gamma)*sin(Alpha));...
            dY;...
            a*(cos(Gamma)*sin(Beta)*sin(Alpha) - sin(Gamma)*cos(Alpha));... 
            dZ;...
            a*cos(Gamma)*cos(Beta) - g;... 
           (omegaX*cos(Gamma) + omegaY*sin(Gamma))/cos(Beta);... 
           -omegaX*sin(Gamma) + omegaY*cos(Gamma);... 
            omegaX*cos(Gamma)*tan(Beta) + omegaY*sin(Gamma)*tan(Beta) + omegaZ];

% Set the dynamic function f
plant.setf(fPlant); % same model 

% Generate necessary files
plant.codeGen();
