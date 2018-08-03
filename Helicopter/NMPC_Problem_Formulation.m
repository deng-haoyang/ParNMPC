clear all;
addpath('../ParNMPC/')
% Hardware and Parameter Configration
setup_lab_heli_3d;
%% Formulate an OCP using Class OptimalControlProblem

% Create an OptimalControlProblem object
OCP = OptimalControlProblem(0,... % dim of equality constraints
                            3,... % dim of inputs 
                            6,... % dim of states
                            15,... % dim of parameters
                            4,... % T: prediction horizon
                            48);  % N: num of discritization grids
% Give names to x, u, p
[epsilon_v,rho_v,lambda_v,dEpsilon_v,dRho_v,dLambda_v] = ...
    OCP.setStateName({'epsilon_v','rho_v','lambda_v','dEpsilon_v','dRho_v','dLambda_v'});
[Vf,Vb,slackrho_v] = ...
    OCP.setInputName({'Vf','Vb','slackrho_v'});

% Set the dynamic function f
% f
c = 1.272;
ae1 = 2.356;
ae2 = 0.799;
ap  = 0.858;
ce = 0.053;
cp = 0.048;
cl = 0.274;
be = 0.565*c;
bp = 7.340*c;
bl = 0.257*c;
Kf = 0.1188;
Vop = 7.4556;
bar_g = [sin(epsilon_v)*(ae1+ae2*cos(rho_v));...
        -ap*cos(epsilon_v)*sin(rho_v);...
         0];
bar_R = diag([ce,cp,cl]);
bar_S1 = [be*cos(rho_v) 0;...
          0 bp;...
          bl*cos(epsilon_v)*sin(rho_v) 0];
forces = [Vf+Vb;Vf-Vb]*Kf;
dq = [dEpsilon_v;...
      dRho_v;
      dLambda_v];
f = [ dq;
      -bar_g-bar_R*dq+bar_S1*forces];
OCP.setf(f);
OCP.setDiscretizationMethod('Euler');

% Set the cost function L
Q = diag([OCP.p(1), OCP.p(2), OCP.p(3), OCP.p(4), OCP.p(5), OCP.p(6)]);
R = diag([OCP.p(7), OCP.p(8)]);

lambdaDim = OCP.dim.lambda;
muDim = OCP.dim.mu;
uDim  = OCP.dim.u;
xDim  = OCP.dim.x;
pDim  = OCP.dim.p;
N     = OCP.N;

xRef = [OCP.p(9);OCP.p(10);OCP.p(11);0;0;0];
uRef = [Vop;Vop];
uMax = [20;20];
uMin = [0;0];
L  =  0.5*(OCP.x-xRef).'*Q*(OCP.x-xRef)...
     +0.5*(OCP.u(1:2)-uRef).'*R*(OCP.u(1:2)-uRef)...
     + 1000*slackrho_v^2;
L = L * OCP.deltaTau;
OCP.setL(L);

% Set the bound constraints
uMax = [20; 20; Inf];
uMin = [0;   0;   0];
uBarrierPara = ones(OCP.dim.u,1)*OCP.p(12);
OCP.setUpperBound('u',uMax,uBarrierPara);
OCP.setLowerBound('u',uMin,uBarrierPara);

% Set the linear constraints G(u,x,p)
G = [rho_v - slackrho_v; rho_v + slackrho_v];
GMax = [   1; Inf];
GMin = [-Inf;  -1];
GBarrierPara = ones(2,1)*OCP.p(12);
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
x0   = [0;0;0;0;0;0];
angleRef = [0;0;0];
xRef = [angleRef;0;0;0];
QDiagVal = [82;4.2;2.3;0.1;0.1;0.1];
RDiagVal = [0.05;0.05];
par = zeros(pDim,N);
par(1:8,:) = repmat([QDiagVal;RDiagVal],1,N);
par(9:11,:) = repmat(angleRef,1,N);
par(12:15,:) = 0.1;% barrior
ocpSolver = OCPSolver(OCP,nmpcSolver,x0,par);

% % 1. init guess by input
% lambdaInitGuess = repmat(randn(lambdaDim,1),1,N);
% muInitGuess     = repmat(randn(muDim,1),1,N);
% uInitGuess      = repmat(uRef,1,N);
% xInitGuess      = repmat(xRef,1,N);

% 2. init guess by start and end
lambdaStart = randn(xDim,1);
muStart     = randn(muDim,1);
uStart      = [uRef;1];
xStart      = x0;

lambdaEnd   = zeros(lambdaDim,1);
muEnd       = zeros(muDim,1);
uEnd        = [uRef;1];
xEnd        = xRef;
[lambdaInitGuess,muInitGuess,uInitGuess,xInitGuess] = ...
    ocpSolver.initFromStartEnd(lambdaStart,muStart,uStart,xStart,...
                               lambdaEnd,  muEnd,  uEnd,  xEnd);

% 3. init guess from file
% [lambdaInitGuess,muInitGuess,uInitGuess,xInitGuess,state] = ...
%                         ocpSolver.initFromMatFile('GEN_initData.mat');
                    
[lambda,mu,u,x] = ocpSolver.OCPSolve(lambdaInitGuess,...
                                           muInitGuess,...
                                           uInitGuess,...
                                           xInitGuess,...
                                           'NMPC_Iter',...
                                           100);
plot(x(1,:));
hold on 
plot(x(2,:));
hold on 
plot(x(3,:));

LAMBDA = ocpSolver.getLAMBDA(x0,lambda,mu,u,x,par);
discretizationMethod = OCP.discretizationMethod;
isMEnabled = OCP.isMEnabled;
save GEN_initData.mat  ...
     lambdaDim muDim uDim xDim pDim N...
     x0 lambda mu u x par LAMBDA
%% Simulation Definition
% M(u,x,p)*dx/dt = f(u,x,p)
plant = DynamicSystem(2,6,0);

[epsilon_v,rho_v,lambda_v,dEpsilon_v,dRho_v,dLambda_v] = ...
    plant.setStateName({'epsilon_v','rho_v','lambda_v','dEpsilon_v','dRho_v','dLambda_v'});
[Vf,Vb] = ...
    plant.setInputName({'Vf','Vb'});
fPlant = f;

plant.setf(fPlant);
isSIMReGen = true;
if isSIMReGen
    plant.codeGen();
end