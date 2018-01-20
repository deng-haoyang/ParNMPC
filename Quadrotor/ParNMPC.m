%% For closed-loop simulation and code generation
% Date: Jan 21, 2018
% Author: Haoyang Deng
function ParNMPC
%% Load and init parameters
% dimension variables
data       = coder.load('GEN_initData.mat');
lambdaDim  = data.lambdaDim;
muDim      = data.muDim;
uDim       = data.uDim;
xDim       = data.xDim;
pDim       = data.pDim;
subDim     = data.subDim;

% some other mpc parameters
uLocation  = data.uLocation;
N          = data.N;
pVal       = data.pVal;
xCurrentState = data.x0Value;

% simulation variables
simuLength = data.simuLength;
Ts         = data.Ts;
simuSteps  = floor(simuLength/Ts);
MaxIterNum = data.MaxIterNum;
tolerance  = data.tolerance;

pSimVal    = data.pSimVal;
pSimDim    = data.pSimDim;

% Jacobian variables
FDStep     = data.FDStep;
isHxxExplicit   = data.isHxxExplicit;

% record variables
rec.x      = zeros(simuSteps+1,xDim);
rec.x(1,:) = xCurrentState.';
rec.u      = zeros(simuSteps,uDim);
rec.numIter   = zeros(simuSteps,1);
rec.error      = zeros(simuSteps,1);
rec.t      = zeros(simuSteps,1);
rec.cpuTime = zeros(simuSteps,1);

theta_N    = zeros(xDim,xDim);

% problem variables
currentEval      = zeros(subDim,N);
currentIteration = data.currentIteration;
theta            = data.theta;
lambdaNextVal    = data.lambdaNextVal;
xPrevVal         = data.xPrevVal;

theta_uncrt     = zeros(xDim,xDim,N);
fu_Val          = zeros(xDim,uDim,N);
fx_I_Val        = zeros(xDim,xDim,N);
Cx_Val          = zeros(muDim,xDim,N);
dKKT23_mu_u_Val = zeros(muDim+uDim,muDim+uDim,N);
Inv_dKKT23_mu_u_Val = zeros(muDim+uDim,muDim+uDim,N);
dmu_u           = zeros(muDim+uDim,N);
Hux_Val         = zeros(uDim,xDim,N);
Hxx_Val         = zeros(xDim,xDim,N);
V_Val           = zeros(muDim,N);
W_Val           = zeros(uDim,N);
Hux_Inv_fx_I_Val  = zeros(uDim,xDim,N);
Cx_Inv_fx_I_Val   = zeros(muDim,xDim,N);
fuT_Inv_fxT_I_Val = zeros(uDim,xDim,N);

Inv_fx_I_Val    = zeros(xDim,xDim,N);
dlambda         = zeros(lambdaDim,N);
dx          = zeros(xDim,N);
A_Val       = zeros(muDim,uDim,N);
P_Val       = zeros(uDim,uDim,N);
MT_Val      = zeros(uDim,uDim,N);
p_lambda_muu = zeros(xDim,muDim+uDim,N);
fuT_theta_uncrt_m_Hux_Inv_fx_I_Val = zeros(uDim,xDim,N);
p_muu_F      = zeros(muDim+uDim,xDim,N);
p_muu_Lambda = zeros(muDim+uDim,xDim,N);
p_lambda_Lambda = zeros(xDim,xDim,N);
p_x_Lambda   = zeros(xDim,xDim,N);
p_x_F        = zeros(xDim,xDim,N);
p_x_muu      = zeros(xDim,muDim+uDim,N);

F_Val     = zeros(xDim,N);
C_Val     = zeros(muDim,N);
Hu_Val    = zeros(uDim,N);
Lamda_Val = zeros(lambdaDim,N);
% time variables
timerRTIEnd    = 0;
timerRTIStart  = 0;
RTITime      = 0;

simTimeStart = 0;
simTimeEnd   = 0;
simTime      = 0;
error        = 0;
%% Set number of threads
if coder.target('MATLAB') % Normal excution
    % in serial
    num_threads = 0;
else% Code generation
    coder.cinclude('stdio.h');
    coder.cinclude('omp.h');
    num_threads = N;
end
simTimeStart = Func_GetTime();
%% Simulation
for step=1:simuSteps %simulation steps
    %% Solve the optimal control problem
    timerRTIStart = Func_GetTime();
    for iter=1:MaxIterNum
        %% Step 1: Coarse Iteration
        parfor (i=1:1:N,num_threads)
            %% Jacobian Evaluation
            fu_Val(:,:,i)           = GEN_Func_fu(currentIteration(:,i),pVal(:,i));
            fx_I_Val(:,:,i)         = GEN_Func_fx_I(currentIteration(:,i),pVal(:,i));
            Cx_Val(:,:,i)           = GEN_Func_Cx(currentIteration(:,i),pVal(:,i));
            dKKT23_mu_u_Val(:,:,i)  = GEN_Func_dKKT23_mu_u(currentIteration(:,i),pVal(:,i));
            Hux_Val(:,:,i)          = GEN_Func_Hux(currentIteration(:,i),pVal(:,i));
            if isHxxExplicit
                 Hxx_Val(:,:,i) = ...
                    GEN_Func_Hxx(currentIteration(:,i),pVal(:,i));
            else
                 Hxx_Val(:,:,i) = ...
                    Func_Hxx_FD(currentIteration(:,i),pVal(:,i),xDim,subDim,FDStep);
            end
            %% Function Evaluation
            currentEval(:,i) = ...
                GEN_Func_KKT(currentIteration(:,i),...
                             xPrevVal(:,i),...
                             lambdaNextVal(:,i),...
                             pVal(:,i));
            currentEval_i = currentEval(:,i);
            F_Val(:,i) = currentEval_i(1:xDim);
            C_Val(:,i) = currentEval_i(xDim+1:xDim+muDim);
            Hu_Val(:,i) = currentEval_i(xDim+muDim+1:xDim+muDim+uDim);
            Lamda_Val(:,i) = currentEval_i(xDim+muDim+uDim+1:xDim+muDim+uDim+lambdaDim);
            %% Intermediate Variables
            Inv_fx_I_Val(:,:,i)     = inv(fx_I_Val(:,:,i));
            theta_uncrt(:,:,i)      = Inv_fx_I_Val(:,:,i).'*...
                                        (Hxx_Val(:,:,i)-theta(:,:,i))*...
                                         Inv_fx_I_Val(:,:,i);

            Hux_Inv_fx_I_Val(:,:,i)  = Hux_Val(:,:,i)*Inv_fx_I_Val(:,:,i);
            Cx_Inv_fx_I_Val(:,:,i)   = Cx_Val(:,:,i)*Inv_fx_I_Val(:,:,i);
            fuT_Inv_fxT_I_Val(:,:,i) = fu_Val(:,:,i).'*Inv_fx_I_Val(:,:,i).';
            fuT_theta_uncrt_m_Hux_Inv_fx_I_Val(:,:,i) =...
                                    fu_Val(:,:,i).'*theta_uncrt(:,:,i)...
                                    - Hux_Inv_fx_I_Val(:,:,i);
            MT_Val(:,:,i) = fu_Val(:,:,i).'*Hux_Inv_fx_I_Val(:,:,i).';
            A_Val(:,:,i) = -Cx_Inv_fx_I_Val(:,:,i)*fu_Val(:,:,i);
            P_Val(:,:,i) = fuT_theta_uncrt_m_Hux_Inv_fx_I_Val(:,:,i)*fu_Val(:,:,i) - MT_Val(:,:,i);
            dKKT23_mu_u_Val(:,:,i) = dKKT23_mu_u_Val(:,:,i)  + ...
                    [zeros(muDim,muDim), A_Val(:,:,i);A_Val(:,:,i).', P_Val(:,:,i)];
            Inv_dKKT23_mu_u_Val(:,:,i) = inv(dKKT23_mu_u_Val(:,:,i));
            %% Sensitivity
            p_lambda_muu(:,:,i) = [-Cx_Inv_fx_I_Val(:,:,i).',...
                                   fuT_theta_uncrt_m_Hux_Inv_fx_I_Val(:,:,i).'];
            p_x_muu(:,:,i) = [zeros(xDim,muDim),-fuT_Inv_fxT_I_Val(:,:,i).'];

            p_muu_F(:,:,i) = Inv_dKKT23_mu_u_Val(:,:,i)*p_lambda_muu(:,:,i).';
            p_muu_Lambda(:,:,i) = Inv_dKKT23_mu_u_Val(:,:,i)*[zeros(muDim,xDim);-fuT_Inv_fxT_I_Val(:,:,i)];
            p_lambda_Lambda(:,:,i) = p_lambda_muu(:,:,i)*p_muu_Lambda(:,:,i)+Inv_fx_I_Val(:,:,i).';
            p_x_Lambda(:,:,i) = p_x_muu(:,:,i)*p_muu_Lambda(:,:,i);
            p_x_F(:,:,i) = p_x_muu(:,:,i)*p_muu_F(:,:,i)+ Inv_fx_I_Val(:,:,i);
            %% theta = p_lambda_F
            theta(:,:,i) = p_lambda_muu(:,:,i)*p_muu_F(:,:,i) - theta_uncrt(:,:,i);
            %% Coarse Iteration
            V_Val(:,i) = C_Val(:,i) - Cx_Inv_fx_I_Val(:,:,i)*F_Val(:,i);
            W_Val(:,i) = Hu_Val(:,i) - fuT_Inv_fxT_I_Val(:,:,i)*Lamda_Val(:,i)...
                                     + fuT_theta_uncrt_m_Hux_Inv_fx_I_Val(:,:,i)*F_Val(:,i);
            dmu_u(:,i) = Inv_dKKT23_mu_u_Val(:,:,i)*[V_Val(:,i);W_Val(:,i)];
            dx(:,i)    = p_x_muu(:,:,i)*dmu_u(:,i) ...
                         + Inv_fx_I_Val(:,:,i)*F_Val(:,i);
            dlambda(:,i) = -theta_uncrt(:,:,i)*F_Val(:,i)...
                           +Inv_fx_I_Val(:,:,i).'*Lamda_Val(:,i)...
                           +p_lambda_muu(:,:,i)*dmu_u(:,i);
            currentIteration(:,i) = currentIteration(:,i)-...
                                                [dlambda(:,i);...
                                                 dmu_u(:,i);...
                                                 dx(:,i)];
        end
        %% Step 2: Backward correction due to the approximation of lambda
        for i=N-1:-1:1
            lambda_i_plus_1 = currentIteration(1:xDim,i+1);
            dlambda(:,i) = lambda_i_plus_1-lambdaNextVal(:,i);
            currentIteration(1:xDim,i)  = ...
                currentIteration(1:xDim,i)  - p_lambda_Lambda(:,:,i) * dlambda(:,i);
        end
        
        parfor (i=1:1:N-1,num_threads)
            dmu_u(:,i) = p_muu_Lambda(:,:,i)* dlambda(:,i);
            dx(:,i)    = p_x_Lambda(:,:,i)  * dlambda(:,i);
            currentIteration(:,i) = currentIteration(:,i)-...
                                                [zeros(xDim,1);...
                                                dmu_u(:,i);...
                                                dx(:,i)];
        end
        %% Step 3: Forward correction due to the approximation of x
        for i=2:1:N
            x_i_1 = currentIteration(end-xDim+1:end,i-1);
            dx(:,i) = (x_i_1-xPrevVal(:,i));
            currentIteration(end-xDim+1:end,i)  = ...
                currentIteration(end-xDim+1:end,i)  - p_x_F(:,:,i) * dx(:,i);
        end
        parfor (i=2:1:N,num_threads)
            dmu_u(:,i) = p_muu_F(:,:,i)* dx(:,i);
            dlambda(:,i)    = theta(:,:,i)  * dx(:,i);
            currentIteration(:,i) = currentIteration(:,i)-...
                                                [dlambda(:,i);...
                                                dmu_u(:,i);...
                                                zeros(xDim,1)];
        end
        %% Update Coupling Variables
        for i=2:1:N
            xPrevVal(:,i) = currentIteration(end-xDim+1:end,i-1);
            lambdaNextVal(:,i-1) = currentIteration(1:lambdaDim,i);
        end
        %% Update theta
        for i = 1:1:N-1
            theta(:,:,i) = theta(:,:,i+1);
        end
        theta(:,:,N) = theta_N;
        %% Check termination
        parfor (i=1:1:N,num_threads)
            currentEval(:,i) = ...
                GEN_Func_KKT(currentIteration(:,i),...
                             xPrevVal(:,i),...
                             lambdaNextVal(:,i),...
                             pVal(:,i));
        end
        error = norm(currentEval,'fro');
        if error<tolerance
            break;
        end
    end
    timerRTIEnd = Func_GetTime();
    RTITime = RTITime + timerRTIEnd - timerRTIStart;
    %% Obtain the first optimal control input
    uOptimalInput = currentIteration(uLocation,1);
    %% System simulation by the 4th-order Explicit Runge-Kutta Method
    xCurrentState = FuncPlantSim(uOptimalInput,xCurrentState,pSimVal,Ts);
    %% Update parameters
    % Update coupling variable
    xPrevVal(:,1) = xCurrentState;
    %>>>>>>------------------FOR_USER---------------------------->>>>>>
    % MPC parameters
    if step >= 500 && step <= 515
        pVal(1,:) = (step-500)*0.1;
        pVal(3,:) = (step-500)*0.1;
        pVal(5,:) = (step-500)*0.1;
    end
    % Simulation plant parameters
    pSimVal = zeros(pSimDim,1);
    %<<<<<<----------------END_FOR_USER--------------------------<<<<<<
    %% Record data
    rec.x(step+1,:)      = xCurrentState.';
    rec.u(step,:)        = uOptimalInput.';
    rec.error(step,:)    = error;
    rec.cpuTime(step,:)  = timerRTIEnd-timerRTIStart;
    rec.t(step,:)        = step*Ts;
    rec.numIter(step,:)  = iter;
    if coder.target('MATLAB')% Normal excution
         disp(['Step: ',num2str(step),'/',num2str(simuSteps),...
               '   NumIter: ',num2str(iter),...
               '   error:' ,num2str(error)]);
    end
end % end of simulation
simTimeEnd = Func_GetTime();
simTime = simTimeEnd - simTimeStart;
%% Log to file
if coder.target('MATLAB')% Normal excution
    save('GEN_log_rec.mat','rec');
    % count time
    disp(['Time Elapsed for RTI+Simulation: ',num2str(simTime) ' seconds ']);
    disp(['Time Elapsed for RTI: ',num2str(RTITime) ' seconds ']);
else % Code generation
    %% show Time Elapsed for RTI
    fmt1 = coder.opaque( 'const char *',['"',...
                                        'Time Elapsed for RTI (Real Time Iteration): %f seconds\r\n',...
                                        '"']);
    coder.ceval('printf',fmt1, RTITime);
    fmt2 = coder.opaque( 'const char *',['"',...
                                        'Time Elapsed for RTI+Simulation: %f seconds\r\n',...
                                        '"']);
    coder.ceval('printf',fmt2, simTime);
    %% Log to file
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
end % end of function
%_END_OF_FILE_