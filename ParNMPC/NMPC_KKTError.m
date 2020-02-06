function [KKTError,costL,timeElapsed] = NMPC_KKTError(x0,p,rho,lambda,mu,u,x)

    timerStart = Timer();
    % Global variables
    global ParNMPCGlobalVariable
    lambdaDim                  = ParNMPCGlobalVariable.dim.x;
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
    KKTxEquation      = zeros(sizeSeg,DoP);
    KKTC              = zeros(sizeSeg,DoP);
    KKTHu             = zeros(sizeSeg,DoP);
    KKTlambdaEquation = zeros(sizeSeg,DoP);
    L                 = zeros(sizeSeg,DoP);
    
    % Coupling variable for each segment
    lambdaNext      = zeros(lambdaDim,sizeSeg,DoP);
    xPrev           = zeros(xDim,sizeSeg,DoP);
    xPrev(:,1,1)    = x0;
    for i=2:1:DoP
        xPrev(:,1,i) = x(:,sizeSeg,i-1);
        lambdaNext(:,sizeSeg,i-1) = lambda(:,1,i);
    end
    
    parfor (i=1:1:DoP,numThreads)
%     for i=1:1:DoP
        lambda_i = lambda(:,:,i);
        mu_i = mu(:,:,i);
        u_i = u(:,:,i);
        x_i = x(:,:,i);
        p_i = p(:,:,i);
        
        xPrev_i      = xPrev(:,:,i);
        lambdaNext_i = lambdaNext(:,:,i);
        
        [KKTxEquation_i,KKTC_i,KKTHu_i,KKTlambdaEquation_i,L_i,LB_i] =...
            KKT_error_func(lambda_i,mu_i,u_i,x_i,p_i,xPrev_i,lambdaNext_i,rho,i);
        
        KKTxEquation(:,i)      = KKTxEquation_i;
        KKTC(:,i)              = KKTC_i;
        KKTHu(:,i)             = KKTHu_i;
        KKTlambdaEquation(:,i) = KKTlambdaEquation_i;
        L(:,i)                 = L_i;
    end
    
    KKTError.stateEquation   = max(KKTxEquation(:));
    KKTError.C               = max(KKTC(:));
    KKTError.Hu              = max(KKTHu(:));
    KKTError.costateEquation = max(KKTlambdaEquation(:));
    costL = sum(L(:));
    timerEnd = Timer();
    timeElapsed = timerEnd  - timerStart;
end