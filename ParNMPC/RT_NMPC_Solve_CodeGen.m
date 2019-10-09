function RT_NMPC_Solve_CodeGen(targetLang,NMPCSolveOptions)

targetLang = upper(targetLang); 

% global variable 
global ParNMPCGlobalVariable
globalVariable = {'ParNMPCGlobalVariable',coder.Constant(ParNMPCGlobalVariable)};
dim   = ParNMPCGlobalVariable.dim;
N     = ParNMPCGlobalVariable.N;
DoP   = NMPCSolveOptions.DoP;
c_MAX_ITER = NMPCSolveOptions.maxIter;
c_RHO = NMPCSolveOptions.rho;
checkKKTError = NMPCSolveOptions.checkKKTErrorAfterIteration;
xEqTol = NMPCSolveOptions.xEqTol;
CEqTol = NMPCSolveOptions.CEqTol;
firstOrderOptTol = NMPCSolveOptions.firstOrderOptTol;
lockMemory = NMPCSolveOptions.lockMemory;
isBusyWaiting = NMPCSolveOptions.busyWaiting;
generateClosedLoopSimulationExample = NMPCSolveOptions.generateClosedLoopSimulationExample;
x0 = NMPCSolveOptions.x0;
p  = NMPCSolveOptions.p;
Ts = NMPCSolveOptions.Ts;
solution = NMPCSolveOptions.solution;
%%
core_info = evalc('feature(''numcores'')');
numsInString = regexp(core_info,'\d*','Match');
numPhysicalCores = str2double(numsInString{1});
numLogicalCores  = str2double(numsInString{2});
disp([num2str(numPhysicalCores),' physical cores, ',num2str(numLogicalCores) ' logical cores']);

if DoP>numPhysicalCores
    error(['DoP should not be more than the number of physical cores (',num2str(numPhysicalCores),')']);
end
if numLogicalCores>numPhysicalCores
    warning('Hyper-threading should be better disabled');
end
uload =' ';
if (DoP>numPhysicalCores) && (DoP<numLogicalCores)
    uload = ' (unbalanced loads detected)';
end

aff = DoP-1:-1:0;
disp(['Tasks will be distributed to core # ', num2str(aff), uload]);
%% coarse_update_func
segSize = (N/DoP);
muDim = dim.mu;
zDim = dim.z;
pDim = dim.p;
muDim(dim.mu == 0) = 1;
zDim(dim.z == 0) = 1;
pDim(dim.p == 0) = 1;

lambda_i          = zeros(dim.lambda,segSize);
mu_i              = zeros(dim.mu,segSize);
u_i               = zeros(dim.u,segSize);
x_i               = zeros(dim.x,segSize);
z_i               = zeros(dim.z,segSize);
p_i               = zeros(pDim,segSize);
xPrev_i           = zeros(dim.x,segSize);
lambdaNext_i      = zeros(dim.x,segSize);
LAMBDA_i          = zeros(dim.lambda,dim.lambda,segSize); 
rho = 0.01; 
iTrd   = int64(1); 
dx_i = zeros(dim.x,segSize);
u_k_i = zeros(dim.u,segSize);
x_k_i = zeros(dim.x,segSize);
z_k_i = zeros(zDim,segSize);
p_muu_F_i = zeros(dim.mu+dim.u,dim.x,segSize);
%% config
cfg = coder.config('lib');
cfg.FilePartitionMethod = 'SingleFile'; 
cfg.TargetLang = targetLang; 
% stackUsageMax = (dim.x+dim.u)*N/360*200000;
% cfg.StackUsageMax = stackUsageMax;
% cfg.BuildConfiguration = 'Faster Runs'; 
cfg.SupportNonFinite = false; 
% cfg.MultiInstanceCode = true;
% cfg.DataTypeReplacement = 'CoderTypeDefs'; 
cfg.HardwareImplementation.TargetHWDeviceType = 'Intel->x86-64 (Linux 64)'; 
% cfg.HardwareImplementation.TargetHWDeviceType = 'Intel->x86-64 (Windows64)'; 
cfg.DynamicMemoryAllocation = 'Off';
% cfg.GenerateMakefile = false; 
% cfg.GenerateExampleMain = 'DoNotGenerate';
cfg.GenCodeOnly = true; % true to generate code only
%% coarse_update_func
args = {lambda_i,mu_i,u_i,x_i,z_i,p_i,xPrev_i,lambdaNext_i,LAMBDA_i,rho,iTrd};
disp("Generating coarse_update_func...");
codegen -config cfg coarse_update_func -globals globalVariable  -args args
%% forward_correction_parallel_func
args = {lambda_i,mu_i,u_i,x_i,z_i,p_i,dx_i,u_k_i,x_k_i,z_k_i,p_muu_F_i,LAMBDA_i,rho};
disp("Generating forward_correction_parallel_func...");
codegen -config cfg forward_correction_parallel_func -globals globalVariable  -args args
%% KKT_error_func
disp("Generating KKT_error_func...");
args = {lambda_i,mu_i,u_i,x_i,p_i,xPrev_i,lambdaNext_i,rho,iTrd};
codegen -config cfg KKT_error_func -globals globalVariable  -args args
%%
global PlantGlobalVariable
uDimPlant = PlantGlobalVariable.dim.u;
xDimPlant = PlantGlobalVariable.dim.x;
pDimPlant = PlantGlobalVariable.dim.p;
globalVariable = {'PlantGlobalVariable',coder.Constant(PlantGlobalVariable)};

uPlant_i  = zeros(uDimPlant,1);
xPlant_i  = zeros(xDimPlant,1);
pPlant_i  = zeros(pDimPlant,1);
Ts        = 0.01;

disp("Generating SIM_Plant_RK4...");
args = {uPlant_i,xPlant_i,pPlant_i,Ts};
codegen -config cfg SIM_Plant_RK4 -globals globalVariable -args args
%%
if generateClosedLoopSimulationExample
    fileID = fopen('./codegen/examplemain.h','w');
    fprintf(fileID, '#ifndef EXAMPLEMAIN_H_\n');
    fprintf(fileID, '#define EXAMPLEMAIN_H_\n\n');
    
%     pString = sprintf('%.9f,' , p(:).');
%     pString = pString(1:end-1);% strip final comma
%     fprintf(fileID,['#define c_pINIT ', '{',pString,'}\n']);
%     
    pString='{';
    for i=1:N
        pStringi = sprintf('%.9f,' , p(:,i).');
        if i==N
            pStringi = ['{',pStringi(1:end-1),'}'];
        else
            pStringi = ['{',pStringi(1:end-1),'},'];
        end
        pString = [pString,pStringi];
    end
    pString = [pString,'}'];
    fprintf(fileID,['#define c_pINIT ', pString,'\n']);
    
    x0String = sprintf('%.9f,' , x0(:).');
    x0String = x0String(1:end-1);% strip final comma
    fprintf(fileID,['#define c_x0INIT ', '{',x0String,'}\n']);
    
    fprintf(fileID,['#define c_Ts ', num2str(Ts), '\n']);
    
    fprintf(fileID, '#endif\n');

    fclose(fileID);
    
    
    % initial_guess_func
    solutionConst = coder.Constant(solution);
    args = {solutionConst};
    disp("Generating initial_guess_func...");
    codegen -config cfg  -args args initial_guess_func
end
%%
disp("Generating configuration file...");
affstr = sprintf('%.0f,' , aff);
affstr = affstr(1:end-1);
pri = ones(1,DoP)*97;
pri(end) = pri(end) + 1;

pristr = sprintf('%.0f,' , pri);
pristr = pristr(1:end-1);

fileID = fopen('./codegen/nmpcconstants.h','w');

fprintf(fileID, '#ifndef NMPC_CONSTANTS_H_\n');
fprintf(fileID, '#define NMPC_CONSTANTS_H_\n');
fprintf(fileID, '#include <sched.h>\n\n');

fprintf(fileID, '/*  Configurable  */\n');
fprintf(fileID, '#define c_MAX_ITER %d\n',c_MAX_ITER);
fprintf(fileID, '#define c_RHO %f\n',c_RHO);
fprintf(fileID, '#define c_XEQ_TOL %f\n',xEqTol);
fprintf(fileID, '#define c_CEQ_TOL %f\n',CEqTol);
fprintf(fileID, '#define c_OPT_TOL %f\n',firstOrderOptTol);
if checkKKTError ~= false
    fprintf(fileID, '#define CHECK_KKT_ERROR_AFTER_ITERATION\n');
end
if lockMemory ~= false
    fprintf(fileID, '#define LOCK_MEMORY_ALL\n');
end
fprintf(fileID, ['#define AFFINITY {' affstr '}\n']);
fprintf(fileID, ['#define PRIORITY {' pristr '}\n']);
fprintf(fileID, ['#define c_MAIN_AFFINITY ' num2str(aff(end)) '\n']);
fprintf(fileID, ['#define c_MAIN_PRIORITY ' num2str(pri(end)) '\n']);
fprintf(fileID, '#define SCHED_METHOD SCHED_FIFO\n\n');

fprintf(fileID, '/*  NOT configurable  */\n');
fprintf(fileID, 'typedef double real_T;\n');
fprintf(fileID, '#define c_N %d\n',N);
fprintf(fileID, '#define c_DOP %d\n',DoP);
fprintf(fileID, '#define c_SEG_SIZE %d\n',N/DoP);
if isBusyWaiting
    fprintf(fileID, '#define BUSY_WAITING\n');
end
fprintf(fileID, '#define c_lambdaDim %d\n',dim.lambda);
fprintf(fileID, '#define c_muDim %d\n',dim.mu);
fprintf(fileID, '#define c_uDim %d\n',dim.u);
fprintf(fileID, '#define c_xDim %d\n',dim.x);
fprintf(fileID, '#define c_pDim %d\n',dim.p);
fprintf(fileID, '#define c_zDim %d\n\n',dim.z);

fprintf(fileID, '#endif\n');
fclose(fileID);
%%
isExistCMakeLists = exist('./CMakeLists.txt','file');
if isExistCMakeLists ~= 2
    copyfile('../ParNMPC/PreemptRTNMPC/CMakeLists.txt');
else
    disp('CMakeLists.txt already exists and will be kept');   
end
disp('Ok!');


