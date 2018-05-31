%% For closed-loop simulation or code generation
function Simu_Matlab
DoP        = 40; % degree of parallism: 1 = in serial, otherwise in parallel
simuLength = 10;
Ts         = 0.001; % sampling interval

simuSteps  = floor(simuLength/Ts);
% Load and init
initData   = coder.load('GEN_initData.mat');
lambdaDim  = initData.lambdaDim;
par        = initData.par;
muDim      = initData.muDim;
uDim       = initData.uDim;
xDim       = initData.xDim;
pDim       = initData.pDim;
N          = initData.N;
x0         = initData.x0;
lambda     = initData.lambda;
mu         = initData.mu;
u          = initData.u;
x          = initData.x;
LAMBDA     = initData.LAMBDA;
isMEnabled = initData.isMEnabled;

discretizationMethod = initData.discretizationMethod;
% reshape initial guess
sizeSeg     = N/DoP;
lambdaSplit = reshape(lambda,lambdaDim,sizeSeg,DoP);
muSplit     = reshape(mu,muDim,sizeSeg,DoP);
uSplit      = reshape(u,uDim,sizeSeg,DoP);
xSplit      = reshape(x,xDim,sizeSeg,DoP);
pSplit      = reshape(par,pDim,sizeSeg,DoP);
LAMBDASplit = reshape(LAMBDA,xDim,xDim,sizeSeg,DoP);

% define record variables
rec.x       = zeros(simuSteps+1,xDim);
rec.x(1,:)  = x0.';
rec.u       = zeros(simuSteps,uDim);
rec.numIter = zeros(simuSteps,1);
rec.error   = zeros(simuSteps,1);
rec.cost    = zeros(simuSteps,1);
rec.t       = zeros(simuSteps,1);
rec.cpuTime = zeros(simuSteps,1);
%% Simulation
MaxIterNum = 3;
tolerance  = 5e-3;

% init
cost        = 0;
error       = 0;
timeElapsed = 0;
RTITimeAll  = 0;
LAMBDABFGS = zeros(xDim,xDim,N);
for i=1:N
    LAMBDABFGS(:,:,i) = LAMBDASplit(:,:,1,i);
end
for step = 1:simuSteps %simulation steps
    RTITime = 0;
    % Solve the optimal control problem
    for iter=1:MaxIterNum
        [lambdaSplitNew,...
         muSplit,...
         uSplit,...
         xSplitNew,...
         LAMBDASplit,...
         cost,...
         error,...
         timeElapsed] = NMPC_Iter(x0,...
                                  lambdaSplit,...
                                  muSplit,...
                                  uSplit,...
                                  xSplit,...
                                  pSplit,...
                                  LAMBDASplit,...
                                  discretizationMethod,...
                                  isMEnabled);
                              
        dlambda = lambdaSplit - lambdaSplitNew;
        dx      = xSplitNew    - xSplit;
        for i=1:N-1
            % BFGS
        	LAMBDABFGS(:,:,i) =  LAMBDABFGS(:,:,i) ...
                 + dlambda(:,:,i)*dlambda(:,:,i).'/(dlambda(:,:,i).'*dx(:,:,i))...
                    - LAMBDABFGS(:,:,i)*dx(:,:,i)*dx(:,:,i).'*LAMBDABFGS(:,:,i)/(dx(:,:,i).'*LAMBDABFGS(:,:,i)*dx(:,:,i));
            % DFP
%              gamma = 1/(dlambda(:,:,i).'*dx(:,:,i));
%             LAMBDABFGS(:,:,i) = (eye(xDim)-gamma*dlambda(:,:,i)*dx(:,:,i).')*LAMBDABFGS(:,:,i)*(eye(xDim)-gamma*dlambda(:,:,i)*dx(:,:,i).')...
%                 +gamma*dlambda(:,:,i)*dlambda(:,:,i).';
        end
        if step>10
            for i=1:N
                LAMBDASplit(:,:,1,i) = LAMBDABFGS(:,:,i);
            end
        end
        lambdaSplit = lambdaSplitNew;
        xSplit      = xSplitNew;
        
        RTITime = RTITime + timeElapsed;
        if error<tolerance
            break;
        end
    end
    RTITimeAll = RTITimeAll + RTITime;
    
    % Obtain the first optimal control input
    uOpt = uSplit(:,1,1);
    
    % System simulation by the 4th-order Explicit Runge-Kutta Method
    pSimVal = zeros(0,1);
    x0 = SIM_Plant_RK4(uOpt(1:4,1),x0,pSimVal,Ts);

    % Update parameters
    if step >= 500 && step <= 515
        pSplit(1,:,:) = (step-500)*0.1; % X ref
        pSplit(2,:,:) = (step-500)*0.1; % Y ref
        pSplit(3,:,:) = (step-500)*0.1; % Z ref
    end
    if step >= 400 && step <= 415 % prediction horizon to 2 s
        pSplit(5,:,:) = (step-400)*0.1 + 0.5;
    end

    % Record data
    rec.x(step+1,:)      = x0.';
    rec.u(step,:)        = uOpt.';
    rec.error(step,:)    = error;
    rec.cpuTime(step,:)  = RTITime*1e6;
    rec.t(step,:)        = step*Ts;
    rec.numIter(step,:)  = iter;
    rec.cost(step,:)     = cost;
    if coder.target('MATLAB')
         disp(['Step: ',num2str(step),'/',num2str(simuSteps),...
               '   NumIter: ',num2str(iter),...
               '   error:' ,num2str(error)]);
    end
end
%% Log to file
if coder.target('MATLAB')% Normal excution
    save('GEN_log_rec.mat','rec');
    % count time
    disp(['Time Elapsed for RTI: ',num2str(RTITimeAll) ' seconds ']);
else % Code generation
    coder.cinclude('stdio.h');
    coder.cinclude('omp.h');
    % show Time Elapsed for RTI
    fmt1 = coder.opaque( 'const char *',['"',...
                                        'Time Elapsed for RTI (Real Time Iteration): %f s\r\n',...
                                        'Timer Precision: %f us\r\n',...
                                        '"']);
    wtrick = 0; % Timer precision
    wtrick = coder.ceval('omp_get_wtick');
    wtrick = wtrick*1e6;
    coder.ceval('printf',fmt1, RTITimeAll,wtrick);
    % Log to file
    fileID = fopen('GEN_log_rec.txt','w');
    % printf header
    for j=1:xDim
        fprintf(fileID,'%s\t',['x',char(48+j)]);
    end
    for j=1:uDim
        fprintf(fileID,'%s\t',['u',char(48+j)]);
    end
    fprintf(fileID,'%s\t','error');
    fprintf(fileID,'%s\t','numIter');
    fprintf(fileID,'%s\n','cpuTime');
    % printf data
    for i=1:simuSteps
        for j=1:xDim
            fprintf(fileID,'%f\t',rec.x(i,j));
        end
        for j=1:uDim
            fprintf(fileID,'%f\t',rec.u(i,j));
        end
        fprintf(fileID,'%f\t',rec.error(i,1));
        fprintf(fileID,'%f\t',rec.numIter(i,1));
        fprintf(fileID,'%f\n',rec.cpuTime(i,1));
    end
    fclose(fileID);
end