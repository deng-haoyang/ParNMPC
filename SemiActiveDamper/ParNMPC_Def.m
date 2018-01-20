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
xDim  = 2; % dimension of states
uDim  = 2; % dimension of inputs including dummy inputs
muDim = 1; % dimension  of constraints
pDim  = 0; % dimension of parameters for the controller
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

run('./Functions/Func_Define_Var.m');

% >>>>>>------------------FOR_USER---------------------------->>>>>>
% Definition of system dynamics f(u,x,p)

a = -1;
b = -1;
f([u;x;p]) = [x(2); a * x(1) + b * x(2) * u(1)];
          
% Definition of equality constraint C(u,x,p)
uMax = 1;
uMin = -1;
uBar = (uMax + uMin)/2;
C([u;x;p]) = (u(1) - uBar)^2 + u(2)^2 - (uMax - uBar)^2;
          
% Definition of cost function L(u,x,p)
Q = diag([10, 10]); 
R = diag([0.01, 0.01]);
r = [0,0.1];
xRef = [0;0];
uRef = [0;uMax];
L([u;x;p]) =  0.5*(x-xRef).'*Q*(x-xRef)...
             +0.5*(u-uRef).'*R*(u-uRef)...
             -0.5*r*u;

% Definition of NMPC settings
x0Value = [1;0]; % initial state
T  = 2; % prediction horizon
N  = 24; % number of discretization grids

pVal = zeros(pDim,N); % parameters

MaxIterNum = 5; % max num of iterations per update
tolerance = 5e-3; % tolerance of the KKT conditions to terminate
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
fSim([u;x;pSim]) = [x(2); a * x(1) + b * x(2) * u(1)];

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
Ts = 0.01;       % sampling interval
simuLength = 20; % simulation length
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

disp('Problem has been defined!');
%_END_OF_FILE_