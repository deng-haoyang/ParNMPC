function [lambda,mu,u,x,z,LAMBDA,KKTError,costL,timeElapsed] = ...
                NMPC_Solve_SearchDirection(x0,p,rho,lambda,mu,u,x,z,LAMBDA) %#codegen
    tStart = Timer();
    
    % global variables
    global ParNMPCGlobalVariable
    discretizationMethod       = ParNMPCGlobalVariable.discretizationMethod;
    isMEnabled                 = ParNMPCGlobalVariable.isMEnabled;
    nonsingularRegularization  = ParNMPCGlobalVariable.nonsingularRegularization;
    descentRegularization      = ParNMPCGlobalVariable.descentRegularization;
    isApproximateInvFx         = ParNMPCGlobalVariable.isApproximateInvFx;
    lambdaDim                  = ParNMPCGlobalVariable.dim.x;
    muDim                      = ParNMPCGlobalVariable.dim.mu;
    uDim                       = ParNMPCGlobalVariable.dim.u;
    xDim                       = ParNMPCGlobalVariable.dim.x;
    zDim                       = ParNMPCGlobalVariable.dim.z;
    
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
    stepSizeZ     = ones(DoP,1);
    stepSizeG     = ones(DoP,1);
    
    % regularization
    NSRMatrix  = -nonsingularRegularization*eye(muDim);
    uDRMatrix  =  descentRegularization*eye(uDim);
    xDRMatrix  =  descentRegularization*eye(xDim);
    
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
    
    KKTxEquation      = zeros(1, DoP);
    KKTC              = zeros(1, DoP);
    KKTHu             = zeros(1, DoP);
    KKTlambdaEquation = zeros(1, DoP);
    L                 = zeros(1,sizeSeg,DoP);
    KKTError.stateEquation   = 0;
    KKTError.C               = 0;
    KKTError.Hu              = 0;
    KKTError.costateEquation = 0;
    
    % coupling variable for each segment
    xPrev(:,1,1) = x0;
    for i=2:1:DoP
        xPrev(:,1,i) = x(:,sizeSeg,i-1);
        lambdaNext(:,sizeSeg,i-1) = lambda(:,1,i);
    end
    %% V(:,index_inside_sig_j,which_sigment_i)
    parfor (i=1:1:DoP,numThreads)
        lambda_i = lambda(:,:,i);
        mu_i     = mu(:,:,i);
        u_i      = u(:,:,i);
        x_i = x(:,:,i);
        z_i = z(:,:,i);
        p_i = p(:,:,i);
        LAMBDA_i     = LAMBDA(:,:,:,i);
        xPrev_i      = xPrev(:,:,i);
        lambdaNext_i = lambdaNext(:,:,i);
        
        p_muu_F_i         = zeros(muDim+uDim,xDim,sizeSeg);
        p_muu_Lambda_i    = zeros(muDim+uDim,xDim,sizeSeg);
        p_lambda_Lambda_i = zeros(xDim,xDim,sizeSeg);
        p_x_Lambda_i      = zeros(xDim,xDim,sizeSeg);
        p_x_F_i           = zeros(xDim,xDim,sizeSeg);
        
        
        xEq_i      = zeros(xDim,sizeSeg);
        C_i        = zeros(muDim,sizeSeg);
        HuT_i      = zeros(uDim,sizeSeg);
        lambdaEq_i = zeros(lambdaDim,sizeSeg);
        L_i        = zeros(1,sizeSeg);
        
        for j = sizeSeg:-1:1
            lambda_j_i  = lambda_i(:,j);
            mu_j_i  = mu_i(:,j);
            u_j_i   = u_i(:,j);
            x_j_i   = x_i(:,j);
            z_j_i   = z_i(:,j);
            p_j_i   = p_i(:,j);
            
            % Function and Jacobian
            [L_j_i,Lu_j_i, Lx_j_i]    = OCP_L_Lu_Lx(u_j_i,x_j_i,p_j_i);
            [~,LBu_j_i,LBx_j_i]   = OCP_LB_LBu_LBx(u_j_i,x_j_i,p_j_i);
            
            C_j_i    = zeros(muDim,1);
            Cu_j_i   = zeros(muDim,uDim);
            Cx_j_i   = zeros(muDim,xDim);
            if muDim ~=0
                [C_j_i,Cu_j_i,Cx_j_i] = OCP_C_Cu_Cx(u_j_i,x_j_i,p_j_i,i);
            end
            [F_j_i,Fu_j_i,Fx_j_i] = OCP_F_Fu_Fx(u_j_i,x_j_i,p_j_i,discretizationMethod,isMEnabled,i);
            
            % KKT
            if j > 1
                xPrev_i(:,j) = x_i(:,j-1);
            end
            if j < sizeSeg
                lambdaNext_i(:,j) = lambda_i(:,j+1);
            end
            xEq_j_i      = xPrev_i(:,j) + F_j_i;
            
            HuT_j_i      = Lu_j_i.' + Fu_j_i.'*lambda_j_i;
            HxT_j_i      = Lx_j_i.' + Fx_j_i.'*lambda_j_i;
            if muDim ~= 0
                HuT_j_i   = HuT_j_i + Cu_j_i.'*mu_j_i;
                HxT_j_i   = HxT_j_i + Cx_j_i.'*mu_j_i;
            end
            lambdaEq_j_i  = lambdaNext_i(:,j) + HxT_j_i + rho*LBx_j_i.';
            HAlluT_j_i    = HuT_j_i   + rho*LBu_j_i.';
            
            % Hessian
            % --- AuuCondensed_j_i = Auu_j_i + Gu_j_i.'*(z_j_i./G_j_i.*Gu_j_i);
            % --- AuxCondensed_j_i = Aux_j_i + Gu_j_i.'*(z_j_i./G_j_i.*Gx_j_i);
            % --- AxxCondensed_j_i = Axx_j_i + Gx_j_i.'*(z_j_i./G_j_i.*Gx_j_i);
            [AuuCondensed_j_i,AuxCondensed_j_i,AxxCondensed_j_i] = ...
                OCP_Auu_Aux_Axx_Condensed(lambda_j_i,mu_j_i,u_j_i,x_j_i,z_j_i,p_j_i);
            AxxCondensed_j_i   = AxxCondensed_j_i + xDRMatrix; % descent regularization
            AuuCondensed_j_i   = AuuCondensed_j_i + uDRMatrix; % descent regularization            
            
            
            d_CHuT_muu_j_i  = [    NSRMatrix,       Cu_j_i;...
                                   Cu_j_i.',        AuuCondensed_j_i]; % nonsingular regularization
            % Intermediate Variables
            if j < sizeSeg
                LAMBDA_i(:,:,j) = LAMBDA_i(:,:,j+1);
            end
            if isApproximateInvFx
                invFx_j_i = -Fx_j_i-2*eye(xDim);
            else
                invFx_j_i =  inv(Fx_j_i);
            end
            LAMBDAUncrt_j_i  = invFx_j_i.'*(AxxCondensed_j_i -LAMBDA_i(:,:,j) )*invFx_j_i;

            Aux_invFx_j_i  = AuxCondensed_j_i*invFx_j_i;
            Cx_invFx_j_i = [];
            if muDim ~= 0
                Cx_invFx_j_i   = Cx_j_i*invFx_j_i;
            end
            
            FuT_invFxT_j_i = Fu_j_i.'*invFx_j_i.';
            FuT_LAMBDAUncrt_m_Aux_invFx_j_i = Fu_j_i.'*LAMBDAUncrt_j_i - Aux_invFx_j_i;
            MT_j_i = Fu_j_i.'*Aux_invFx_j_i.';
            A_j_i = [];
            if muDim ~= 0
                A_j_i = -Cx_invFx_j_i*Fu_j_i;
            end
            
            P_j_i = FuT_LAMBDAUncrt_m_Aux_invFx_j_i*Fu_j_i - MT_j_i;
            d_CHuT_muu_j_i = d_CHuT_muu_j_i  + [zeros(muDim,muDim), A_j_i;A_j_i.', P_j_i];
            Inv_dKKT23_mu_u_j_i = inv(d_CHuT_muu_j_i);
            
            % Sensitivities
            p_lambda_muu_j_i = [-Cx_invFx_j_i.', FuT_LAMBDAUncrt_m_Aux_invFx_j_i.'];
            p_x_muu_j_i = [zeros(xDim,muDim),-FuT_invFxT_j_i.'];

            p_muu_F_j_i         = Inv_dKKT23_mu_u_j_i*p_lambda_muu_j_i.';
            p_muu_Lambda_j_i    = Inv_dKKT23_mu_u_j_i*[zeros(muDim,xDim);-FuT_invFxT_j_i];
            p_lambda_Lambda_j_i = p_lambda_muu_j_i*p_muu_Lambda_j_i+invFx_j_i.';
            p_x_Lambda_j_i      = p_x_muu_j_i*p_muu_Lambda_j_i;
            p_x_F_j_i           = p_x_muu_j_i*p_muu_F_j_i+ invFx_j_i;
            % --- LAMBDA = p_lambda_F
            LAMBDA_j_i          = p_lambda_muu_j_i*p_muu_F_j_i - LAMBDAUncrt_j_i;

            % Coarse Iteration
            V_j_i = [];
            if muDim ~= 0
               V_j_i = C_j_i - Cx_invFx_j_i*xEq_j_i;
            end
            
            W_j_i = HAlluT_j_i - FuT_invFxT_j_i*lambdaEq_j_i...
                               + FuT_LAMBDAUncrt_m_Aux_invFx_j_i*xEq_j_i;
            dmu_u_j_i      = Inv_dKKT23_mu_u_j_i*[V_j_i;W_j_i];
            dx_j_i         = p_x_muu_j_i*dmu_u_j_i + invFx_j_i*xEq_j_i;
            dlambda_j_i    = - LAMBDAUncrt_j_i*xEq_j_i...
                             + invFx_j_i.'*lambdaEq_j_i...
                             + p_lambda_muu_j_i*dmu_u_j_i;
            
            lambda_i(:,j) = lambda_i(:,j) - dlambda_j_i;
            mu_u_new =  [mu_i(:,j);u_i(:,j)] - dmu_u_j_i;
            mu_i(:,j) = mu_u_new(1:muDim,1);
            u_i(:,j) = mu_u_new(muDim+1:end,1);
            x_i(:,j) = x_i(:,j) - dx_j_i;
            
            % Recover
            p_muu_F_i(:,:,j) = p_muu_F_j_i;
            p_muu_Lambda_i(:,:,j) = p_muu_Lambda_j_i;
            p_lambda_Lambda_i(:,:,j) = p_lambda_Lambda_j_i;
            p_x_Lambda_i(:,:,j)   = p_x_Lambda_j_i;
            p_x_F_i(:,:,j) = p_x_F_j_i;
            LAMBDA_i(:,:,j) = LAMBDA_j_i;
            %
            xEq_i(:,j)      = xEq_j_i;
            C_i(:,j)        = C_j_i;
            HuT_i(:,j)      = HAlluT_j_i;
            lambdaEq_i(:,j) = lambdaEq_j_i;
            L_i(:,j)        = L_j_i;
        end
        
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
        KKTxEquation(:,i)      = norm(xEq_i,     Inf);
        KKTC(:,i)              = norm(C_i,       Inf);
        KKTHu(:,i)             = norm(HuT_i,     Inf);
        KKTlambdaEquation(:,i) = norm(lambdaEq_i,Inf);
        L(:,:,i)               = L_i;
    end
    %%
    KKTError.stateEquation   = max(KKTxEquation(:));
    KKTError.C               = max(KKTC(:));
    KKTError.Hu              = max(KKTHu(:));
    KKTError.costateEquation = max(KKTlambdaEquation(:));
    costL = sum(L(:));

    %% Step 2: Backward correction due to the approximation of lambda
    for i = DoP:-1:1
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
    parfor (i=1:1:DoP,numThreads)
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
        
        stepSizeZ_i    = zeros(zDim,sizeSeg);
        stepSizeG_i    = zeros(zDim,sizeSeg);
        
        
        p_muu_F_i = p_muu_F(:,:,:,i);
        LAMBDA_i = LAMBDA(:,:,:,i);
        
        for j = sizeSeg:-1:1
            dmu_u_i = p_muu_F_i(:,:,j)* dx_i(:,j);
            dlambda_j_i    = LAMBDA_i(:,:,j)  * dx_i(:,j);
            lambda_i(:,j) = lambda_i(:,j) - dlambda_j_i;
            mu_u_new =  [mu_i(:,j);u_i(:,j)] - dmu_u_i;
            mu_i(:,j) = mu_u_new(1:muDim,1);
            u_i(:,j) = mu_u_new(muDim+1:end,1);
        end
        lambda(:,:,i) = lambda_i;
        mu(:,:,i)     = mu_i;
        u(:,:,i)      = u_i;
        % update z
        if zDim ~= 0
            for j = sizeSeg:-1:1
                u_k_j_i  = u_k_i(:,j);
                x_k_j_i  = x_k_i(:,j);
                u_j_i  = u_i(:,j);
                x_j_i  = x_i(:,j);
                z_j_i  = z_i(:,j);
                p_j_i  = p_i(:,j);
                if zDim ~=0
                    G_j_i   = OCP_G(u_j_i,x_j_i,p_j_i);
                    G_k_j_i = OCP_G(u_k_j_i,x_k_j_i,p_j_i);
                    dz_j_i = (z_j_i.*G_j_i - rho)./G_k_j_i;
                    z_i(:,j)  = z_j_i -  dz_j_i;
                end
            end
            z(:,:,i)      = z_i;
        end
        %% Line Search for feasibility
        if zDim ~= 0
        % z
            dz_i = z_i - z_k_i;
            for j = 1:sizeSeg
                    stepSizeZ_i(:,j) = (0.05 - 1).*((z_k_i(:,j))./(dz_i(:,j)));
            end
            stepSizeZ_i(stepSizeZ_i>1 | stepSizeZ_i<0) = 1;
            stepSizeMaxZ_i = min(stepSizeZ_i(:));
            if isempty(stepSizeMaxZ_i)
                stepSizeMaxZ_i = 1;
            end
            stepSizeZ(i,1) = stepSizeMaxZ_i;

        % G 
            G_i   = OCP_G(u_i,x_i,p_i);
            G_k_i = OCP_G(u_k_i,x_k_i,p_i);
            dG_i  = G_i - G_k_i;
            % GMin
            for j=1:sizeSeg
                stepSizeG_i(:,j) = (0.05 - 1).*(G_k_i(:,j)./dG_i(:,j));
            end
            stepSizeG_i(stepSizeG_i>1 | stepSizeG_i<0) = 1;
            stepSizeMaxG_i = min(stepSizeG_i(:));
            if isempty(stepSizeMaxG_i)
                stepSizeMaxG_i = 1;
            end
            stepSizeG(i,1) = stepSizeMaxG_i;
        end
    end
    %% Line Search to Guarantee Primal Stability
    stepSize = min(stepSizeG);
    if stepSize ~= 1
        lambda = (1-stepSize)*lambda_k + stepSize* lambda;
        mu     = (1-stepSize)*mu_k     + stepSize* mu;
        u      = (1-stepSize)*u_k      + stepSize* u;
        x      = (1-stepSize)*x_k      + stepSize* x;
    end
    stepSizeDual = min(stepSizeZ);
    if stepSizeDual ~= 1
        z = (1-stepSizeDual)*z_k + stepSizeDual* z;
    end
    %% Update LAMBDA
    for i = 1:1:DoP
        for j = 1:1:sizeSeg
            if j<sizeSeg
                LAMBDA(:,:,j,i) = LAMBDA(:,:,j+1,i);
            else
                if i == DoP
                   LAMBDA(:,:,sizeSeg,DoP) = LAMBDA_N;
                else
                   LAMBDA(:,:,j,i) = LAMBDA(:,:,1,i+1);
                end
            end
        end
    end
    tEnd = Timer();
    timeElapsed = tEnd  - tStart;
end
