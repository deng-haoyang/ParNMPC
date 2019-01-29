function Simu_Matlab_Codegen

data       = coder.load('GEN_initData.mat');
N          = data.N;
xDim       = data.xDim;

% global variable
global ParNMPCGlobalVariable
globalVariable = {'ParNMPCGlobalVariable',coder.Constant(ParNMPCGlobalVariable)};

cfg = coder.config('lib');
cfg.FilePartitionMethod = 'SingleFile';

cfg.TargetLang = 'C';
stackUsageMax = xDim*N/360*200000;
cfg.StackUsageMax = stackUsageMax;
cfg.BuildConfiguration = 'Faster Runs'; % no MexCodeConfig 
cfg.SupportNonFinite = false; % no MexCodeConfig

codegen -config cfg Simu_Matlab -globals globalVariable
