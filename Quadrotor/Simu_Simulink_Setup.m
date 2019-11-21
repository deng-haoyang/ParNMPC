initData   = coder.load('GEN_initData.mat');
p          = initData.p;
x0         = initData.x0;

% set options
options              = createOptions();
options.DoP          = 4; % degree of parallism: 1 = in serial, otherwise in parallel
options.isLineSearch = false;
options.rhoInit      = 1e-2;
options.rhoEnd       = 1e-2;
options.maxIterTotal = 5;
options.maxIterInit  = 5;
% generate code
NMPC_Solve_CodeGen('dll','C',options);

%% settings for simulink to call the generated code
Simu_Simulink
set_param('Simu_Simulink', 'SimCustomHeaderCode',   '#include "NMPC_Solve.h"')
set_param('Simu_Simulink', 'SimCustomInitializer',  'NMPC_Solve_initialize();')
set_param('Simu_Simulink', 'SimCustomTerminator',   'NMPC_Solve_terminate();')
if ismac
    set_param('Simu_Simulink', 'SimUserLibraries',      'NMPC_Solve.dylib')
elseif isunix
    set_param('Simu_Simulink', 'SimUserLibraries',      'NMPC_Solve.so')
elseif ispc
    set_param('Simu_Simulink', 'SimUserLibraries',      'NMPC_Solve.lib')
end
set_param('Simu_Simulink', 'SimUserIncludeDirs',    './codegen/dll/NMPC_Solve')
