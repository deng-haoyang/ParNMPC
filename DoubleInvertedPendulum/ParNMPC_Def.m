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
xDim  = 6; % dimension of states
uDim  = 2; % dimension of inputs including dummy inputs
muDim = 1; % dimension  of constraints
pDim  = xDim+uDim; % dimension of parameters for the controller
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

run('./Functions/Func_Define_Var.m');

% >>>>>>------------------FOR_USER---------------------------->>>>>>
% Definition of system dynamics f(u,x,p)

% See: Bogdanov, Alexander. 
% "Optimal control of a double inverted pendulum on a cart."
% Oregon Health and Science University, Tech. Rep. CSE-04-006, 
% OGI School of Science and Engineering, Beaverton, OR (2004).

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

Ds = [d1           d2*cos(x(1))      d3*cos(x(2));...
     d2*cos(x(1))  d4                d5*cos(x(1)-x(2));...
     d3*cos(x(2))  d5*cos(x(1)-x(2)) d6];
Cs = [0 -d2*sin(x(1))*x(4)      -d3*sin(x(2))*x(5);...
      0  0                       d5*sin(x(1)-x(2))*x(5);...
      0 -d5*sin(x(1)-x(2))*x(4)  0];
Gs = [0;...
     -f1*sin(x(1));...
     -f2*sin(x(2))];
Hs = [1 0 0].';
f([u;x;p]) = [x(4);...
              x(5);
              x(6);
              Ds\(Hs*u(1)-Gs-Cs*[x(4) x(5) x(6)].')];
          
% Definition of equality constraint C(u,x,p)
uMax =  10;
uMin = -10;
uBar = (uMax + uMin)/2;
C([u;x;p]) = [(u(1) - uBar)^2 + u(2)^2 - (uMax-uBar)^2];
          
% Definition of cost function L(u,x,p)
Q = diag([p(1), p(2), p(3), p(4), p(5), p(6)]);
R = diag([p(7),p(8)]);
r = [0,0.1];
xRef = [0;0;0;0;0;0];
uRef = [0;uMax];
L([u;x;p]) =  0.5*(x-xRef).'*Q*(x-xRef)...
             +0.5*(u-uRef).'*R*(u-uRef)...
             -0.5*r*u;

% Definition of NMPC settings
x0Value = [0;pi;pi;0;0;0]; % initial state
T = 1.5; % prediction horizon
N  = 36; % number of discretization grids

QDiagVal = [10;10;10;1;1;1];
RDiagVal = [0.1;0.1];
pVal = repmat([QDiagVal;RDiagVal],1,N);
pVal(:,end) = [200;200;200;10;10;10;0.1;0.1]; % terminal penlty

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
fSim([u;x;pSim]) = [x(4);...
                    x(5);
                    x(6);
              Ds\(Hs*u(1)-Gs-Cs*[x(4) x(5) x(6)].')];
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
Ts = 0.005;       % sampling interval
simuLength = 5; % simulation length
%<<<<<<----------------END_FOR_USER--------------------------<<<<<<

disp('Problem has been defined!');
%_END_OF_FILE_