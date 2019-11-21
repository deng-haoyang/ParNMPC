function NMPC_Solve_CodeGen(target,targetLang,NMPCSolveOptions)
% target: 'mex' 'lib' 'dll'
% targetLang: 'C' 'C++'

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

if ismac
    disp('Note: install libomp for mac: brew install libomp');
    % Code to run on Mac plaform
    if verLessThan('matlab','9.6')
        % -- earlier than R2019a --
        isInParallel = false;
        warning('Mac is only supported for parallel code generation from R2019a!');
    end
    if DoP == 1
        isInParallel = true;
    end
end
cfg.EnableOpenMP            = isInParallel;
cfg.TargetLang              = targetLang;
stackUsageMax               = (dim.x + dim.u)*N/360*10000;
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
    if ismac
        % flag to call openmp in mac
        cfg.PostCodeGenCommand = 'buildInfo.addLinkFlags(''-Xpreprocessor -fopenmp'')';
    else
        cfg.PostCodeGenCommand = 'buildInfo.addLinkFlags(''-fopenmp'')';
    end
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
        if ismac
           genMSg = ['Generating NMPC_Solve.dylib...' ];
        elseif isunix
           genMSg = ['Generating NMPC_Solve.so...' ];
        elseif ispc
           genMSg = ['Generating NMPC_Solve.dll...' ];
        else
           disp('Platform not supported')
        end
    otherwise
end
disp(genMSg);
codegen  -config cfg ...
          NMPC_Solve ...
         -globals globalVariable...
         -args args
%% copy dll/so/dylib to the working folder
if strcmp(target,'dll')
    clear mex
    if ismac
        %% comment omp in NMPC_Solve.h for mac
        fid = fopen('./codegen/dll/NMPC_Solve/NMPC_Solve.h','r');
        strAll = [];
        tline = fgetl(fid);
        while ischar(tline)
            isFound = strfind(tline, 'omp');
            if isempty(isFound)
                strAll = [strAll,tline,'\n'];
            else
                strAll = [strAll,'// ', tline,'\n'];
            end
            % Read next line
            tline = fgetl(fid);
        end
        fclose(fid);
        fid = fopen('./codegen/dll/NMPC_Solve/NMPC_Solve.h','w');
        fprintf(fid,strAll);
        fclose(fid);
        
        
        copyfile('./codegen/dll/NMPC_Solve/NMPC_Solve.dylib');
    elseif isunix
       copyfile('./codegen/dll/NMPC_Solve/NMPC_Solve.so');
    elseif ispc
       copyfile('./codegen/dll/NMPC_Solve/NMPC_Solve.dll');
    else
       disp('Platform not supported')
    end
end
%%
disp('Done!');