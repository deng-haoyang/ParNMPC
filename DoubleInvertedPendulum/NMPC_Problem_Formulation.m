clear all
addpath('../ParNMPC/')
%% Formulate an OCP using Class OptimalControlProblem

% Create an OptimalControlProblem object
OCP = OptimalControlProblem(2,... % dim of inputs 
                            6,... % dim of states 
                            7,... % dim of parameters 
                            48);  % N: num of discritization grids

% Give names to x, u, p
[X,Theta1,Theta2,dX,dTheta1,dTheta2] = ...
    OCP.setStateName({'X','Theta1','Theta2','dX','dTheta1','dTheta2'});
[F,slack] = ...
    OCP.setInputName({'F','slack'});

% Set the prediction horizon T
OCP.setT(1.5);

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
Q = diag(OCP.p(1:6));
R = diag(OCP.p(7));
xRef  = [0;0;0;0;0;0];
uRef  = 0;
L     =   0.5*(OCP.x-xRef).'*Q*(OCP.x-xRef)...
        + 0.5*(OCP.u(1)-uRef).'*R*(OCP.u(1)-uRef)...
        +1e6*slack^2;
OCP.setL(L);

% Set the linear constraints G(u,x,p)>=0
G =[ OCP.u(1) + 10;...
    -OCP.u(1) + 10;...
     slack;...
     X + slack + 0.09;...
    -X + slack + 0.09];
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
x0   = [0;pi;pi;0;0;0];

% Set the parameter p
dim      = OCP.dim;
N        = OCP.N;
QDiagVal = [10;10;10;1;1;1];
RDiagVal = 0.1;
p        = zeros(dim.p,N);
p(1:7,:) = repmat([QDiagVal;RDiagVal],1,N);
p(1:7,end) = [100;100;100;10;10;10;0.1]; % terminal penlty

% init
solutionInitGuess.lambda = [randn(dim.lambda,1),zeros(dim.lambda,1)];
solutionInitGuess.mu     = [randn(dim.mu,1),randn(dim.mu,1)];
solutionInitGuess.u      = [uRef;1];
solutionInitGuess.x      = [x0,xRef];
solutionInitGuess.z      = ones(dim.z,N);
solutionInitGuess.LAMBDA = zeros(dim.lambda,dim.lambda,N);
solution = NMPC_SolveOffline(x0,p,solutionInitGuess,0.01,1000);

plot(solution.x([2 3],:).');
figure(2);
plot(solution.u(1,:).');
figure(3);
plot(solution.x(1,:).');

% Save to file
save GEN_initData.mat  dim x0 p N
global ParNMPCGlobalVariable
ParNMPCGlobalVariable.solutionInitGuess = solution;
%% Define the controlled plant using Class DynamicSystem

% M(u,x,p) \dot(x) = f(u,x,p)
% Create a DynamicSystem object
plant = DynamicSystem(2,6,0);

% Give names to x, u
[X,Theta1,Theta2,dX,dTheta1,dTheta2] = ...
    plant.setStateName({'X','Theta1','Theta2','dX','dTheta1','dTheta2'});
[F,slack] = ...
    plant.setInputName({'F','slack'});

% Set the dynamic function f
plant.setf(f); % same model 
plant.setM(M); % same model 


% Generate necessary files
plant.codeGen();
