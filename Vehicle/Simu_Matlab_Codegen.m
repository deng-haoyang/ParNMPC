% Generate exe file for Simu_Matlab

data       = coder.load('GEN_initData.mat');
N          = data.N;
xDim       = data.dim.x;
uDim       = data.dim.u;

% global variable
global ParNMPCGlobalVariable
globalVariable = {'ParNMPCGlobalVariable',coder.Constant(ParNMPCGlobalVariable)};
% config
cfg = coder.config('lib');
cfg.FilePartitionMethod = 'SingleFile';
cfg.TargetLang = 'C';
stackUsageMax = (xDim+uDim)*N/360*200000;
cfg.StackUsageMax = stackUsageMax;
cfg.BuildConfiguration = 'Faster Runs'; 
cfg.SupportNonFinite = false; 
cfg.GenerateExampleMain = 'GenerateCodeAndCompile';
cfg.GenCodeOnly = false; % true to generate code only
myCCompiler = mex.getCompilerConfigurations(cfg.TargetLang,'Selected');
clear NMPC_Solve % must be cleared before code generation
if ~strcmp(myCCompiler.Manufacturer,'Microsoft')
    cfg.PostCodeGenCommand = 'buildInfo.addLinkFlags(''-fopenmp'')';
end
% generate exe
codegen -config cfg Simu_Matlab -globals globalVariable
%% Run 
!Simu_Matlab
