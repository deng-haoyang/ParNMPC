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
xDim  = 9; % dimension of states
uDim  = 8; % dimension of inputs including dummy inputs
muDim = 4; % dimension  of constraints
pDim  = xDim+uDim; % dimension of parameters for the controller
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

run('./Functions/Func_Define_Var.m');

% >>>>>>------------------FOR_USER---------------------------->>>>>>
% Definition of system dynamics f(u,x,p)
g = 9.81;
f([u;x;p]) = [x(2);...
              u(1)*(cos(x(7))*sin(x(8))*cos(x(9)) + sin(x(7))*sin(x(9)));...
              x(4);...
              u(1)*(cos(x(7))*sin(x(8))*sin(x(9)) - sin(x(7))*cos(x(9)));...
              x(6);...
              u(1)*cos(x(7))*cos(x(8)) - g;...
             (u(2)*cos(x(7)) + u(3)*sin(x(7)))/cos(x(8));...
             -u(2)*sin(x(7)) + u(3)*cos(x(7));...
              u(2)*cos(x(7))*tan(x(8)) + u(3)*sin(x(7))*tan(x(8)) + u(4)];
          
% Definition of equality constraint C(u,x,p)
uMax = [11;1;1;1];
uMin = [0;-1;-1;-1];
uBar = (uMax + uMin)/2;
C([u;x;p]) = [(u(1) - uBar(1))^2 + u(5)^2 - (uMax(1)-uBar(1))^2;...
              (u(2) - uBar(2))^2 + u(6)^2 - (uMax(2)-uBar(2))^2;...
              (u(3) - uBar(3))^2 + u(7)^2 - (uMax(3)-uBar(3))^2;...
              (u(4) - uBar(4))^2 + u(8)^2 - (uMax(4)-uBar(4))^2];
          
% Definition of cost function L(u,x,p)
Q = diag([10, 1, 2, 1, 10, 1, 1, 1, 1]);
R = diag([1, 1, 1, 1 ,...
          0.01, 0.01, 0.01, 0.01 ]);
r = [0,0,0,0,...
     1,1,1,1]*0.1;
L([u;x;p]) =  0.5*(x-p(1:xDim)).'*Q*(x-p(1:xDim))...
             +0.5*(u-p(pDim-uDim+1:pDim)).'*R*(u-p(pDim-uDim+1:pDim))...
             -0.5*r*u;

% Definition of NMPC settings
x0Value = [1;0;1;0;1;0;0;0;0]; % initial state
T = 1.0; % prediction horizon
N  = 24; % number of discretization grids
xRefConstant = [0;0;0;0;0;0;...
                0;0;0];
uRefConstant = [g;0;0;0;...
                sqrt(-(g - uBar(1))^2 + (uMax(1)-uBar(1))^2);...
                uMax(2);uMax(3);uMax(4)];
pVal = repmat([xRefConstant;uRefConstant],1,N); % init parameters
MaxIterNum = 5; % max num of iterations per update
tolerance = 5e-3; % tolerance of the KKT conditions to terminate
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

% Define and generate KKT files
run('./Functions/Func_Define_KKT.m');

% Define and generate Jacobian files

%>>>>>>------------------FOR_USER---------------------------->>>>>>
isHxxExplicit = true;  % true for explicit Hxx, false for forward difference
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
fSim([u;x;pSim]) = [x(2);...
            u(1)*(cos(x(7))*sin(x(8))*cos(x(9)) + sin(x(7))*sin(x(9)));...
            x(4);...
            u(1)*(cos(x(7))*sin(x(8))*sin(x(9)) - sin(x(7))*cos(x(9)));...
            x(6);...
            u(1)*cos(x(7))*cos(x(8)) - g;...
            (u(2)*cos(x(7)) + u(3)*sin(x(7)))/cos(x(8));...
            -u(2)*sin(x(7)) + u(3)*cos(x(7));...
            u(2)*cos(x(7))*tan(x(8)) + u(3)*sin(x(7))*tan(x(8)) + u(4)];
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
simuLength = 10; % simulation length
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

disp('Problem has been defined!');
%_END_OF_FILE_