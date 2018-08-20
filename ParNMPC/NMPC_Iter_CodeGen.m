function NMPC_Iter_CodeGen(target,targetLang,args)
% target: 'mex' 'lib' 'dll'
% targetLang: 'C' 'C++'
% args: {x0,lambda,mu,u,x,p,LAMBDA}

target = lower(target);
targetLang = upper(targetLang);

[lambdaDim,segSize,DoP] = size(args{2});
[uDim,segSize,DoP] = size(args{4});
[pDim,segSize,DoP] = size(args{6});

% global variables
global discretizationMethod isMEnabled ...
       uMin uMax xMin xMax GMax GMin ...
       veryBigNum

cfg = coder.config(target);
cfg.FilePartitionMethod = 'SingleFile';

if DoP == 1
    isInParallel = false;
else
    isInParallel = true;
end
cfg.EnableOpenMP = isInParallel;

cfg.TargetLang = targetLang;
stackUsageMax = lambdaDim*segSize*DoP/360*200000;
cfg.StackUsageMax = stackUsageMax;
%% Generate C/C++ for NMPC_Iter
globalVariable = {'discretizationMethod',coder.Constant(discretizationMethod),...
                  'isMEnabled',coder.Constant(isMEnabled),...
                  'uMax',coder.Constant(uMax),...
                  'uMin',coder.Constant(uMin),...
                  'xMax',coder.Constant(xMax),...
                  'xMin',coder.Constant(xMin),...
                  'GMax',coder.Constant(GMax),...
                  'GMin',coder.Constant(GMin),...
                  'veryBigNum',coder.Constant(veryBigNum)};

if ~strcmp(target,'mex')
    cfg.BuildConfiguration = 'Faster Runs'; % no MexCodeConfig 
    cfg.SupportNonFinite = false; % no MexCodeConfig
    cfg.GenerateExampleMain = 'DoNotGenerate'; % no MexCodeConfig
end

myCCompiler = mex.getCompilerConfigurations(targetLang,'Selected');
switch myCCompiler.Name
    case 'gcc'
        cfg.PostCodeGenCommand = 'buildInfo.addLinkFlags(''-fopenmp'')'; 
    case 'g++'
        cfg.PostCodeGenCommand = 'buildInfo.addLinkFlags(''-fopenmp'')'; 
end

codegen -config cfg ...
         NMPC_Iter ...
         -globals globalVariable...
        -args args