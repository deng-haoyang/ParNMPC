function [lambda,mu,u,x,z,LAMBDA,KKTError,costL,timeElapsed] = ...
                NMPC_Solve_SearchDirection(x0,p,rho,lambda,mu,u,x,z,LAMBDA) %#codegen
    tStart = Timer();

    % global variables
    global ParNMPCGlobalVariable
    lambdaDim                  = ParNMPCGlobalVariable.dim.x;
    muDim                      = ParNMPCGlobalVariable.dim.mu;
    uDim                       = ParNMPCGlobalVariable.dim.u;
    xDim                       = ParNMPCGlobalVariable.dim.x;
    % parallel seg
    [~,sizeSeg,DoP]  = size(u);
    if coder.target('MATLAB') % Normal excution
        % in serial
        numThreads = 0;
    else % Code generation
        numThreads = DoP;
    end
    LAMBDA_N    = zeros(xDim,xDim);
    
    % backup 
    lambda_k = lambda;
    mu_k     = mu;
    u_k      = u;
    x_k      = x;
    z_k      = z;
    
    % line search parameters
    stepSizeZ     = ones(1,DoP);
    stepSizeG     = ones(1,DoP);

    % local variables
    lambdaNext      = zeros(lambdaDim,sizeSeg,DoP);
    xPrev           = zeros(xDim,sizeSeg,DoP);

    dlambda         = zeros(lambdaDim,sizeSeg,DoP);
    dx              = zeros(xDim,sizeSeg,DoP);
    
    p_muu_F         = zeros(muDim+uDim,xDim,sizeSeg,DoP);
    p_muu_Lambda    = zeros(muDim+uDim,xDim,sizeSeg,DoP);
    p_lambda_Lambda = zeros(xDim,xDim,sizeSeg,DoP);
    p_x_Lambda      = zeros(xDim,xDim,sizeSeg,DoP);
    p_x_F           = zeros(xDim,xDim,sizeSeg,DoP);
    
    KKTxEquation      = zeros(sizeSeg, DoP);
    KKTC              = zeros(sizeSeg, DoP);
    KKTHu             = zeros(sizeSeg, DoP);
    KKTlambdaEquation = zeros(sizeSeg, DoP);
    L                 = zeros(sizeSeg, DoP);
    KKTError.stateEquation   = 0;
    KKTError.C               = 0;
    KKTError.Hu              = 0;
    KKTError.costateEquation = 0;
    
    % coupling variable for each segment
    xPrev(:,1,1) = x0;
    for i=2:1:DoP
        xPrev(:,1,i) = x(:,sizeSeg,i-1);
        lambdaNext(:,sizeSeg,i-1) = lambda(:,1,i);
        LAMBDA(:,:,sizeSeg,i-1) = LAMBDA(:,:,1,i);
    end
    LAMBDA(:,:,sizeSeg,DoP) = LAMBDA_N;
    %% V(:,index_inside_sig_j,which_sigment_i)
    parfor (i=1:DoP,numThreads)
%     for i=1:1:DoP
        lambda_i = lambda(:,:,i);
        mu_i     = mu(:,:,i);
        u_i      = u(:,:,i);
        x_i = x(:,:,i);
        z_i = z(:,:,i);
        p_i = p(:,:,i);
        LAMBDA_i     = LAMBDA(:,:,:,i);
        xPrev_i      = xPrev(:,:,i);
        lambdaNext_i = lambdaNext(:,:,i);
              
        [lambda_i,mu_i,u_i,x_i,xPrev_i,lambdaNext_i,...
          p_muu_F_i, p_muu_Lambda_i, p_lambda_Lambda_i, p_x_Lambda_i, p_x_F_i,LAMBDA_i,...
          KKTxEquation_i,KKTC_i,KKTHu_i,KKTlambdaEquation_i,L_i,LB_i] = ...
        coarse_update_func(lambda_i,mu_i,u_i,x_i,z_i,p_i,xPrev_i,lambdaNext_i,LAMBDA_i,rho,i);
        
        % Recover
        lambda(:,:,i) = lambda_i;
        mu(:,:,i)     = mu_i;
        u(:,:,i)      = u_i;
        x(:,:,i)      = x_i;
        xPrev(:,:,i)  = xPrev_i;
        LAMBDA(:,:,:,i)= LAMBDA_i;
        lambdaNext(:,:,i) = lambdaNext_i;
        
        p_muu_F(:,:,:,i) = p_muu_F_i;
        p_muu_Lambda(:,:,:,i) = p_muu_Lambda_i;
        p_lambda_Lambda(:,:,:,i) = p_lambda_Lambda_i;
        p_x_Lambda(:,:,:,i) = p_x_Lambda_i;
        p_x_F(:,:,:,i) = p_x_F_i;
        
        %
        KKTxEquation(:,i)      = KKTxEquation_i.';
        KKTC(:,i)              = KKTC_i.';
        KKTHu(:,i)             = KKTHu_i.';
        KKTlambdaEquation(:,i) = KKTlambdaEquation_i.';
        L(:,i)                 = L_i.';
    end
    %%
    KKTError.stateEquation   = max(KKTxEquation(:));
    KKTError.C               = max(KKTC(:));
    KKTError.Hu              = max(KKTHu(:));
    KKTError.costateEquation = max(KKTlambdaEquation(:));
    costL = sum(L(:));
    %% Step 2: Backward correction due to the approximation of lambda
    for i = DoP-1:-1:1
        for j = sizeSeg:-1:1
            if j == sizeSeg
                if i == DoP
                    lambda_next =  zeros(lambdaDim,1);
                else
                    lambda_next = lambda(:,1,i+1);
                end
            else
                lambda_next = lambda(:,j+1,i);
            end
            
            dlambda(:,j,i) = lambda_next-lambdaNext(:,j,i);
            lambda(:,j,i)  = lambda(:,j,i)  - p_lambda_Lambda(:,:,j,i) * dlambda(:,j,i);
        end
    end
    
    parfor (i=1:DoP,numThreads)
%     for i=1:1:DoP
        p_muu_Lambda_i = p_muu_Lambda(:,:,:,i);
        p_x_Lambda_i = p_x_Lambda(:,:,:,i);
        mu_i = mu(:,:,i);
        u_i = u(:,:,i);
        x_i = x(:,:,i);
        dlambda_i = dlambda(:,:,i);
        for j = sizeSeg:-1:1
            dmu_u_j_i = p_muu_Lambda_i(:,:,j)* dlambda_i(:,j);
            dx_j_i    = p_x_Lambda_i(:,:,j)  * dlambda_i(:,j);
            mu_u_new  =  [mu_i(:,j);u_i(:,j)] - dmu_u_j_i;
            mu_i(:,j) = mu_u_new(1:muDim,1);
            u_i(:,j)  = mu_u_new(muDim+1:end,1);
            x_i(:,j)  = x_i(:,j) - dx_j_i;
        end
        mu(:,:,i)     = mu_i;
        u(:,:,i)      = u_i;
        x(:,:,i)      = x_i;
    end

    %% Step 3: Forward correction due to the approximation of x
    for i = 1:1:DoP
        for j = 1:1:sizeSeg
            if j == 1
                if i==1
                   x_prev = x0;
                else
                   x_prev = x(:,sizeSeg,i-1);
                end
            else
                x_prev = x(:,j-1,i);
            end
            dx(:,j,i) = (x_prev-xPrev(:,j,i));
            x(:,j,i)  = x(:,j,i)  - p_x_F(:,:,j,i) * dx(:,j,i);
        end
    end
    parfor (i=1:1:DoP,numThreads)
%     for i=1:1:DoP
        lambda_i = lambda(:,:,i);
        mu_i = mu(:,:,i);
        u_i = u(:,:,i);
        x_i = x(:,:,i);
        z_i = z(:,:,i);
        p_i = p(:,:,i);
        dx_i = dx(:,:,i);
        
        % line search variables
        u_k_i = u_k(:,:,i);
        x_k_i = x_k(:,:,i);
        z_k_i = z_k(:,:,i);
        
        p_muu_F_i = p_muu_F(:,:,:,i);
        LAMBDA_i  = LAMBDA(:,:,:,i);
        
        for j = sizeSeg:-1:1
            dmu_u_i       = p_muu_F_i(:,:,j) * dx_i(:,j);
            dlambda_j_i   = LAMBDA_i(:,:,j)  * dx_i(:,j);
            lambda_i(:,j) = lambda_i(:,j) - dlambda_j_i;
            mu_u_new      =  [mu_i(:,j);u_i(:,j)] - dmu_u_i;
            mu_i(:,j)     = mu_u_new(1:muDim,1);
            u_i(:,j)      = mu_u_new(muDim+1:end,1);
        end
        lambda(:,:,i) = lambda_i;
        mu(:,:,i)     = mu_i;
        u(:,:,i)      = u_i;
        
        [z_i,stepSizeZ_i,stepSizeG_i] = ...
            fraction_to_boundary_parallel_func(u_i,x_i,z_i,p_i,u_k_i,x_k_i,z_k_i,rho);
        % Recover
        lambda(:,:,i) = lambda_i;
        mu(:,:,i)     = mu_i;
        u(:,:,i)      = u_i;
        z(:,:,i)      = z_i;
        stepSizeZ(1,i) = stepSizeZ_i;
        stepSizeG(1,i) = stepSizeG_i;
    end
    %% Line Search to Guarantee Primal Stability
    stepSize = min(stepSizeG(:));
    if stepSize ~= 1
        lambda = (1-stepSize)*lambda_k + stepSize* lambda;
        mu     = (1-stepSize)*mu_k     + stepSize* mu;
        u      = (1-stepSize)*u_k      + stepSize* u;
        x      = (1-stepSize)*x_k      + stepSize* x;
    end
    stepSizeDual = min(stepSizeZ(:));
    if stepSizeDual ~= 1
        z = (1-stepSizeDual)*z_k + stepSizeDual* z;
    end
    %%
    tEnd = Timer();
    timeElapsed = tEnd  - tStart;
end