
data       = coder.load('GEN_initData.mat');
N          = data.N;
xDim       = data.dim.x;
uDim       = data.dim.u;

% global variable
global ParNMPCGlobalVariable
globalVariable = {'ParNMPCGlobalVariable',coder.Constant(ParNMPCGlobalVariable)};

cfg = coder.config('lib');
cfg.FilePartitionMethod = 'SingleFile';
cfg.EnableOpenMP = true;
cfg.TargetLang = 'C++';
stackUsageMax = (xDim+uDim)*N/360*200000;
cfg.StackUsageMax = stackUsageMax;
cfg.BuildConfiguration = 'Faster Runs';
cfg.EnableMemcpy  = true;
cfg.GenerateExampleMain = 'GenerateCodeOnly';
cfg.GenCodeOnly = true;
cfg.SupportNonFinite = false;
cfg.CustomInitializer = 'iiwa14_init();';      % init function
clear NMPC_Solve

myCCompiler = mex.getCompilerConfigurations(cfg.TargetLang,'Selected');
if ~strcmp(myCCompiler.Manufacturer,'Microsoft')
        cfg.PostCodeGenCommand = 'buildInfo.addLinkFlags(''-fopenmp'')';
end

codegen  -config cfg Simu_Matlab -globals globalVariable