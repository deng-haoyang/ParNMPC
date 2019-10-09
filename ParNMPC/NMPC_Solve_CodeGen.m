function NMPC_Solve_CodeGen(target,targetLang,NMPCSolveOptions)
% target: 'mex' 'lib' 'dll'
% targetLang: 'C' 'C++'
if ismac
    % Code to run on Mac plaform
    error('Mac is currently not supported!');
end
% clear persistent variables 
clear NMPC_Solve

target     = lower(target);
targetLang = upper(targetLang); 
%% global variable
global ParNMPCGlobalVariable
globalVariable = {'ParNMPCGlobalVariable',coder.Constant(ParNMPCGlobalVariable)};
%% args 
dim   = ParNMPCGlobalVariable.dim;
N     = ParNMPCGlobalVariable.N;
DoP   = NMPCSolveOptions.DoP;
args_x0               = zeros(dim.x,1);
args_p                = zeros(dim.p,N);
args_NMPCSolveOptions = coder.Constant(NMPCSolveOptions);
args = {args_x0,args_p,args_NMPCSolveOptions};
%% config
cfg = coder.config(target);
cfg.FilePartitionMethod = 'SingleFile';

if DoP == 1
    isInParallel = false;
else
    isInParallel = true;
end
cfg.EnableOpenMP            = isInParallel;
cfg.TargetLang              = targetLang;
stackUsageMax               = (dim.x + dim.u)*N/360*200000;
cfg.StackUsageMax           = stackUsageMax;
cfg.GenerateReport          = true;
cfg.DynamicMemoryAllocation = 'off';
if ~strcmp(target,'mex')
    cfg.BuildConfiguration  = 'Faster Runs';
    cfg.SupportNonFinite    = false;
    cfg.GenerateExampleMain = 'DoNotGenerate';
end

myCCompiler = mex.getCompilerConfigurations(targetLang,'Selected');
if ~strcmp(myCCompiler.Manufacturer,'Microsoft') 
        cfg.PostCodeGenCommand = 'buildInfo.addLinkFlags(''-fopenmp'')';        
end
%% generate
switch target
    case 'mex'
        genMSg = ['Generating ', target, ' file for NMPC_Solve...' ];
    case 'lib'
        genMSg = ['Generating ', targetLang, ' source files for NMPC_Solve...' ];
		cfg.GenerateExampleMain = 'GenerateCodeOnly';
        cfg.GenCodeOnly = true;
    case 'dll'
        if isunix
            genMSg = ['Generating NMPC_Solve.so...' ];
        elseif ispc
            genMSg = ['Generating NMPC_Solve.dll...' ];
        end
    otherwise
end
disp(genMSg);
codegen  -config cfg ...
          NMPC_Solve ...
         -globals globalVariable...
         -args args
%% copy dll/so to the working folder
if isunix
    % Code to run on Linux plaform
    if strcmp(target,'dll')
        clear mex
        copyfile('./codegen/dll/NMPC_Solve/NMPC_Solve.so');
    end
elseif ispc
    % Code to run on Windows platform
    if strcmp(target,'dll')
        clear mex
        copyfile('./codegen/dll/NMPC_Solve/NMPC_Solve.dll');
    end
else
    disp('Platform not supported')
end