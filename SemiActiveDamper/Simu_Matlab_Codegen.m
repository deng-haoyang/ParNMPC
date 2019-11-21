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
stackUsageMax = (xDim+uDim)*N/360*10000;
cfg.StackUsageMax = stackUsageMax;
cfg.BuildConfiguration = 'Faster Runs'; 
cfg.SupportNonFinite = false; 
cfg.GenerateExampleMain = 'GenerateCodeAndCompile';
cfg.GenCodeOnly = false; % true to generate code only
myCCompiler = mex.getCompilerConfigurations(cfg.TargetLang,'Selected');
clear NMPC_Solve % must be cleared before code generation
if ~strcmp(myCCompiler.Manufacturer,'Microsoft')
    if ismac
        % flag to call openmp in mac
        cfg.PostCodeGenCommand = 'buildInfo.addLinkFlags(''-Xpreprocessor -fopenmp'')';
    else
        cfg.PostCodeGenCommand = 'buildInfo.addLinkFlags(''-fopenmp'')';
    end
end
% generate exe
codegen -config cfg Simu_Matlab -globals globalVariable