function [KKTError,costL,timeElapsed] = NMPC_KKTError(x0,p,rho,lambda,mu,u,x)

    timerStart = Timer();
    % Global variables
    global ParNMPCGlobalVariable
    discretizationMethod       = ParNMPCGlobalVariable.discretizationMethod;
    isMEnabled                 = ParNMPCGlobalVariable.isMEnabled;
    lambdaDim                  = ParNMPCGlobalVariable.dim.x;
    muDim                      = ParNMPCGlobalVariable.dim.mu;
    uDim                       = ParNMPCGlobalVariable.dim.u;
    xDim                       = ParNMPCGlobalVariable.dim.x;
    
    % init
    KKTError.stateEquation   = 0;
    KKTError.C               = 0;
    KKTError.Hu              = 0;
    KKTError.costateEquation = 0;
    
    [~,sizeSeg,DoP]  = size(x);
    if coder.target('MATLAB') % Normal excution
        % in serial
        numThreads = 0;
    else % Code generation
        numThreads = DoP;
    end
    
    % Local 
    KKTxEquation      = zeros(1, DoP);
    KKTC              = zeros(1, DoP);
    KKTHu             = zeros(1, DoP);
    KKTlambdaEquation = zeros(1, DoP);
    L                 = zeros(1,sizeSeg,DoP);
    
    % Coupling variable for each segment
    lambdaNext      = zeros(lambdaDim,sizeSeg,DoP);
    xPrev           = zeros(xDim,sizeSeg,DoP);
    xPrev(:,1,1)    = x0;
    for i=2:1:DoP
        xPrev(:,1,i) = x(:,sizeSeg,i-1);
        lambdaNext(:,sizeSeg,i-1) = lambda(:,1,i);
    end
    
    parfor (i=1:1:DoP,numThreads)
        lambda_i = lambda(:,:,i);
        mu_i = mu(:,:,i);
        u_i = u(:,:,i);
        x_i = x(:,:,i);
        p_i = p(:,:,i);
        
        xPrev_i      = xPrev(:,:,i);
        lambdaNext_i = lambdaNext(:,:,i);
        
        xEq_i      = zeros(xDim,sizeSeg);
        C_i        = zeros(muDim,sizeSeg);
        HuT_i      = zeros(uDim,sizeSeg);
        lambdaEq_i = zeros(lambdaDim,sizeSeg);
        L_i        = zeros(1,sizeSeg);

        for j = sizeSeg:-1:1
            u_j_i   = u_i(:,j);
            x_j_i   = x_i(:,j);
            p_j_i   = p_i(:,j);
            
            % Function Evaluation
            if j > 1
                xPrev_i(:,j) = x_i(:,j-1);
            end
            if j < sizeSeg
                lambdaNext_i(:,j) = lambda_i(:,j+1);
            end
            [L_i(:,j),Lu_j_i,Lx_j_i]          = OCP_L_Lu_Lx(u_j_i,x_j_i,p_j_i);
            [~,LBu_j_i,LBx_j_i] = OCP_LB_LBu_LBx(u_j_i,x_j_i,p_j_i);
            LAllu_j_i = Lu_j_i + rho*LBu_j_i;
            LAllx_j_i = Lx_j_i + rho*LBx_j_i;

            C_i(:,j) = zeros(muDim,1);
            Cu_j_i   = zeros(muDim,uDim);
            Cx_j_i   = zeros(muDim,xDim);
            if muDim ~=0
                [C_i(:,j),Cu_j_i,Cx_j_i] = OCP_C_Cu_Cx(u_j_i,x_j_i,p_j_i);
            end
            
            [F_j_i,Fu_j_i,Fx_j_i] = OCP_F_Fu_Fx(u_j_i,x_j_i,p_j_i,discretizationMethod,isMEnabled);

            xEq_i(:,j)      = F_j_i + xPrev_i(:,j);
            HuT_i(:,j)      = LAllu_j_i.'  + Fu_j_i.'*lambda_i(:,j);
            lambdaEq_i(:,j) = lambdaNext_i(:,j) + ...
                              LAllx_j_i.'  + Fx_j_i.'*lambda_i(:,j);
            if muDim ~= 0
                HuT_i(:,j)      = HuT_i(:,j) + Cu_j_i.'*mu_i(:,j);
                lambdaEq_i(:,j) = lambdaEq_i(:,j) + Cx_j_i.'*mu_i(:,j);
            end
        end
        KKTxEquation(:,i)      = norm(xEq_i,     Inf);
        KKTC(:,i)              = norm(C_i,       Inf);
        KKTHu(:,i)             = norm(HuT_i,     Inf);
        KKTlambdaEquation(:,i) = norm(lambdaEq_i,Inf);
        L(:,:,i)               = L_i;
    end
    
    KKTError.stateEquation   = max(KKTxEquation(:));
    KKTError.C               = max(KKTC(:));
    KKTError.Hu              = max(KKTHu(:));
    KKTError.costateEquation = max(KKTlambdaEquation(:));
    costL = sum(L(:));
    timerEnd = Timer();
    timeElapsed = timerEnd  - timerStart;
end