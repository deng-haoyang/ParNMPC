
data       = coder.load('GEN_initData.mat');
N          = data.N;
xDim       = data.dim.x;
uDim       = data.dim.u;

% global variable
global ParNMPCGlobalVariable
globalVariable = {'ParNMPCGlobalVariable',coder.Constant(ParNMPCGlobalVariable)};

cfg = coder.config('exe');
cfg.FilePartitionMethod = 'SingleFile';

cfg.TargetLang = 'C';
stackUsageMax = (xDim+uDim)*N/360*200000;
cfg.StackUsageMax = stackUsageMax;
cfg.BuildConfiguration = 'Faster Runs'; % no MexCodeConfig 
cfg.SupportNonFinite = false; % no MexCodeConfig
clear NMPC_Solve


myCCompiler = mex.getCompilerConfigurations(cfg.TargetLang,'Selected');
if ~strcmp(myCCompiler.Manufacturer,'Microsoft')
    cfg.PostCodeGenCommand = 'buildInfo.addLinkFlags(''-fopenmp'')';
end

codegen -config cfg Simu_Matlab -globals globalVariable...
         ./codegen/exe/Simu_Matlab/examples/main.c ...
         ./codegen/exe/Simu_Matlab/examples/main.h