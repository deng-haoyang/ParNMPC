%% For problem formulation
% Date: Jan 21, 2018
% Author: Haoyang Deng
%__________________________________________________________________
% parameters need to be defined: all of the global variables
% functions need to be defined: f, L, C
%__________________________________________________________________
addpath('./Functions/');
%% Definition of the NMPC controller

%__________________________________________________________________
% sizes of parameters:
% xDim uDim muDim pDim: 1 x 1
% T N MaxIterNum tolerance isHxxExplicit FDStep: 1 x 1
% x0Value: xDim x 1
% pVal: pDim x N
%__________________________________________________________________

global xDim uDim muDim pDim ...
       x0Value T N pVal MaxIterNum tolerance ...
       isHxxExplicit FDStep

%>>>>>>------------------FOR_USER---------------------------->>>>>>
% Definition of dimensions
xDim  = 4; % dimension of states
uDim  = 4; % dimension of inputs including dummy inputs
muDim = 2; % dimension  of constraints
pDim  = 0; % dimension of parameters for the controller
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

run('./Functions/Func_Define_Var.m');

% >>>>>>------------------FOR_USER---------------------------->>>>>>
% Definition of system dynamics f(u,x,p)

% See: Diehl, M. (2001). 
% Real-time optimization for large scale nonlinear processes. 
% Ph.D. thesis. Universitat Heidelberg.

k10 = 1.287e12;
k20 = 1.287e12;
k30 = 9.043e9;
E1  = -9758.3;
E2  = -9758.3;
E3  = -8560;
H1  = 4.2;
H2  = -11;
H3  = -41.85;
pho = 0.9342;
Cp  = 3.01;
kw  = 4032;
AR  = 0.215;
VR  = 10;
mK  = 5;
CPK = 2;
cA0 = 5.1;
theta0 = 104.9;
k1 = k10*exp(E1/(x(3)+273.15));
k2 = k20*exp(E2/(x(3)+273.15));
k3 = k30*exp(E3/(x(3)+273.15));

f([u;x;p]) = [u(1)*(cA0-x(1))-k1*x(1)-k3*x(1)*x(1);...
             -u(1)*x(2)+k1*x(1)-k2*x(2);...
              u(1)*(theta0-x(3))+kw*AR/(pho*Cp*VR)*(x(4)-x(3))-...
                  1/(pho*Cp)*(k1*x(1)*H1+k2*x(2)*H2+k3*x(1)*x(1)*H3);...
             (1/(mK*CPK))*(u(2)+kw*AR*(x(3)-x(4)))];
          
% Definition of equality constraint C(u,x,p)
uMax = [35;0];
uMin = [0;-9000];
uBar = (uMax + uMin)/2;
C([u;x;p]) = [(u(1) - uBar(1))^2 + u(3)^2 - (uMax(1)-uBar(1))^2;...
              (u(2) - uBar(2))^2 + u(4)^2 - (uMax(2)-uBar(2))^2];


% Definition of cost function L(u,x,p)
Q = diag([0.2, 1, 0.5, 0.2]);
R = diag([0.5, 5e-7, 0.5, 5e-7]);
r = [0,0,0.1,5e-7];
xRef = [2.1402;1.0903;114.19;112.91];
uRef = [14.19;-1113.5;15.2599;2963.4];
L([u;x;p]) =  0.5*(x-xRef).'*Q*(x-xRef)...
             +0.5*(u-uRef).'*R*(u-uRef)...
             -0.5*r*u;

% Definition of NMPC settings
x0Value = [1;0.5;100;100]; % initial state
T  = 1500/3600; % prediction horizon
N  = 24; % number of discretization grids

pVal = zeros(pDim,N); % parameters

MaxIterNum = 5; % max num of iterations per update
tolerance = 1e-7; % tolerance of the KKT conditions to terminate
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

% Define and generate KKT files
run('./Functions/Func_Define_KKT.m');

% Define and generate Jacobian files

%>>>>>>------------------FOR_USER---------------------------->>>>>>
isHxxExplicit = false;  % true for explicit Hxx, false for forward difference
FDStep    = 0.0001;     % step size of forward difference: h
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

run('./Functions/Func_Define_Jacobian.m');
%% Definition of the controlled plant

%__________________________________________________________________
% sizes of parameters:
% pSimDim: 1 x 1
% pSimVal: pSimDim x 1
%__________________________________________________________________


global pSimDim pSimVal

%>>>>>>------------------FOR_USER---------------------------->>>>>>
% Definition of dimensions
pSimDim  = 0; % dimension of the parameter in the simulation model
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

run('./Functions/Func_Define_VarSim.m');

%>>>>>>------------------FOR_USER---------------------------->>>>>>
fSim([u;x;pSim]) = [u(1)*(cA0-x(1))-k1*x(1)-k3*x(1)*x(1);...
             -u(1)*x(2)+k1*x(1)-k2*x(2);...
              u(1)*(theta0-x(3))+kw*AR/(pho*Cp*VR)*(x(4)-x(3))-...
                  1/(pho*Cp)*(k1*x(1)*H1+k2*x(2)*H2+k3*x(1)*x(1)*H3);...
             (1/(mK*CPK))*(u(2)+kw*AR*(x(3)-x(4)))];

% init pSim
pSimVal = zeros(pSimDim,1);
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

run('./Functions/Func_Define_fSim.m');

%% Definition of the simulation loop

%__________________________________________________________________
% sizes of parameters:
% Ts simuLength: 1 x 1
%__________________________________________________________________

global Ts simuLength

%>>>>>>------------------FOR_USER---------------------------->>>>>>
Ts = 5/3600;       % sampling interval
simuLength = 1800/3600; % simulation length
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

disp('Problem has been defined!');
%_END_OF_FILE_