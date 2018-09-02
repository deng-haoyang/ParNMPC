function [lambda,mu,u,x,LAMBDA,cost,error,timeElapsed] = NMPC_Iter(x0,lambda,mu,u,x,p,LAMBDA) %#codegen
    timerRTIStart = Timer();
    
    % global variables
    global discretizationMethod isMEnabled ...
           uMin uMax xMin xMax GMax GMin ...
           veryBigNum...
           nonsingularRegularization descentRegularization
           
    [xDim,sizeSeg,DoP] = size(x);
    lambdaDim = xDim;
    [muDim,sizeSeg,DoP] = size(mu);
    [uDim,sizeSeg,DoP] = size(u);
    if coder.target('MATLAB') % Normal excution
        % in serial
        numThreads = 0;
    else % Code generation
        numThreads = DoP;
    end
    LAMBDA_N    = zeros(xDim,xDim);
    
    % backup 
    lambda_k = lambda;
    mu_k = mu;
    u_k = u;
    x_k = x;
    
    % line search parameters
    stepSizeUMax    = ones(DoP,1);
    stepSizeUMin    = ones(DoP,1);
    stepSizeXMax    = ones(DoP,1);
    stepSizeXMin    = ones(DoP,1);
    [GDim,unused]   = size(GMax);
    stepSizeGMax    = ones(DoP,1);
    stepSizeGMin    = ones(DoP,1);
    
    % regularization
    NSRMatrix  = -nonsingularRegularization*eye(muDim);
    uDRMatrix  =  descentRegularization*eye(uDim);
    xDRMatrix  =  descentRegularization*eye(xDim);
    
    % local variables
    lambdaNext    = zeros(lambdaDim,sizeSeg,DoP);
    xPrev         = zeros(xDim,sizeSeg,DoP);

    dlambda         = zeros(lambdaDim,sizeSeg,DoP);
    dx              = zeros(xDim,sizeSeg,DoP);
    
    p_muu_F         = zeros(muDim+uDim,xDim,sizeSeg,DoP);
    p_muu_Lambda    = zeros(muDim+uDim,xDim,sizeSeg,DoP);
    p_lambda_Lambda = zeros(xDim,xDim,sizeSeg,DoP);
    p_x_Lambda      = zeros(xDim,xDim,sizeSeg,DoP);
    p_x_F           = zeros(xDim,xDim,sizeSeg,DoP);

    xEq      = zeros(xDim,sizeSeg,DoP);
    C        = zeros(muDim,sizeSeg,DoP);
    HuT      = zeros(uDim,sizeSeg,DoP);
    lambdaEq = zeros(lambdaDim,sizeSeg,DoP);
    L        = zeros(1,sizeSeg,DoP);
    
    % coupling variable for each segment
    xPrev(:,1,1) = x0;
    for i=2:1:DoP
        xPrev(:,1,i) = x(:,sizeSeg,i-1);
        lambdaNext(:,sizeSeg,i-1) = lambda(:,1,i);
    end
    %% V(:,index_inside_sig_j,which_sigment_i)
    parfor (i=1:1:DoP,numThreads)
        lambda_i = lambda(:,:,i);
        mu_i = mu(:,:,i);
        u_i = u(:,:,i);
        x_i = x(:,:,i);
        p_i = p(:,:,i);
        LAMBDA_i = LAMBDA(:,:,:,i);
        xPrev_i = xPrev(:,:,i);
        lambdaNext_i = lambdaNext(:,:,i);
        
        xEq_i = xEq(:,:,i);
        C_i   = C(:,:,i);
        HuT_i = HuT(:,:,i);
        lambdaEq_i = lambdaEq(:,:,i);
        
        p_muu_F_i = p_muu_F(:,:,:,i);
        p_muu_Lambda_i = p_muu_Lambda(:,:,:,i);
        p_lambda_Lambda_i = p_lambda_Lambda(:,:,:,i);
        p_x_Lambda_i = p_x_Lambda(:,:,:,i);
        p_x_F_i = p_x_F(:,:,:,i);
        
        dx_i = dx(:,:,i);
        dlambda_i = dlambda(:,:,i);
        
        for j = sizeSeg:-1:1
            lambda_j_i  = lambda_i(:,j);
            mu_j_i  = mu_i(:,j);
            u_j_i   = u_i(:,j);
            x_j_i   = x_i(:,j);
            p_j_i   = p_i(:,j);
            
            % Jacobian Evaluation
            [L_j_i,LBarrier_j_i,Lu_j_i,Lx_j_i] = OCP_L_Lu_Lx(u_j_i,x_j_i,p_j_i);
            
            C_i(:,j) = zeros(muDim,1);
            Cu_j_i   = zeros(muDim,uDim);
            Cx_j_i   = zeros(muDim,xDim);
            if muDim ~=0
                [C_i(:,j),Cu_j_i,Cx_j_i] = OCP_C_Cu_Cx(u_j_i,x_j_i,p_j_i);
            end
            [F_j_i,Fu_j_i,Fx_j_i] = OCP_F_Fu_Fx(u_j_i,x_j_i,p_j_i,discretizationMethod,isMEnabled);
            
            Aux_j_i   = OCP_Aux(lambda_j_i,mu_j_i,u_j_i,x_j_i,p_j_i);
            Axx_j_i   = OCP_Axx(lambda_j_i,mu_j_i,u_j_i,x_j_i,p_j_i) + xDRMatrix; % descent regularization
            Auu_j_i   = OCP_Auu(lambda_j_i,mu_j_i,u_j_i,x_j_i,p_j_i) + uDRMatrix; % descent regularization
            
            d_CHuT_muu_j_i  = [    NSRMatrix,       Cu_j_i;...
                                   Cu_j_i.',        Auu_j_i]; % nonsingular regularization
            % Function Evaluation
            if j > 1
                xPrev_i(:,j) = x_i(:,j-1);
            end
            if j < sizeSeg
                lambdaNext_i(:,j) = lambda_i(:,j+1);
            end
            xEq_i(:,j)      = F_j_i + xPrev_i(:,j);
            
            HuT_i(:,j)      = Lu_j_i.' + Fu_j_i.'*lambda_j_i;
            lambdaEq_i(:,j) = lambdaNext_i(:,j) + ...
                              Lx_j_i.' + Fx_j_i.'*lambda_j_i;
            if muDim ~= 0
                HuT_i(:,j)      = HuT_i(:,j) + Cu_j_i.'*mu_j_i;
                lambdaEq_i(:,j) = lambdaEq_i(:,j) + Cx_j_i.'*mu_j_i;
            end

            if j < sizeSeg
                LAMBDA_i(:,:,j) = LAMBDA_i(:,:,j+1);
            end
            % Intermediate Variables
            invFx_j_i     = inv(Fx_j_i);
            LAMBDAUncrt_j_i  = invFx_j_i.'*(Axx_j_i -LAMBDA_i(:,:,j) )*invFx_j_i;

            Aux_invFx_j_i  = Aux_j_i*invFx_j_i;
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
            
            % Sensitivity
            p_lambda_muu_j_i = [-Cx_invFx_j_i.', FuT_LAMBDAUncrt_m_Aux_invFx_j_i.'];
            p_x_muu_j_i = [zeros(xDim,muDim),-FuT_invFxT_j_i.'];

            p_muu_F_i(:,:,j) = Inv_dKKT23_mu_u_j_i*p_lambda_muu_j_i.';
            p_muu_Lambda_i(:,:,j) = Inv_dKKT23_mu_u_j_i*[zeros(muDim,xDim);-FuT_invFxT_j_i];
            p_lambda_Lambda_i(:,:,j) = p_lambda_muu_j_i*p_muu_Lambda_i(:,:,j)+invFx_j_i.';
            p_x_Lambda_i(:,:,j) = p_x_muu_j_i*p_muu_Lambda_i(:,:,j);
            p_x_F_i(:,:,j) = p_x_muu_j_i*p_muu_F_i(:,:,j)+ invFx_j_i;
            % LAMBDA = p_lambda_F
            LAMBDA_i(:,:,j) = p_lambda_muu_j_i*p_muu_F_i(:,:,j) - LAMBDAUncrt_j_i;

            % Coarse Iteration
            V_j_i = [];
            if muDim ~= 0
               V_j_i = C_i(:,j) - Cx_invFx_j_i*xEq_i(:,j);
            end
            
            W_j_i = HuT_i(:,j) - FuT_invFxT_j_i*lambdaEq_i(:,j)...
                                     + FuT_LAMBDAUncrt_m_Aux_invFx_j_i*xEq_i(:,j);
            dmu_u_j_i = Inv_dKKT23_mu_u_j_i*[V_j_i;W_j_i];
            dx_i(:,j)    = p_x_muu_j_i*dmu_u_j_i + invFx_j_i*xEq_i(:,j);
            dlambda_i(:,j) = -LAMBDAUncrt_j_i*xEq_i(:,j)...
                           +invFx_j_i.'*lambdaEq_i(:,j)...
                           +p_lambda_muu_j_i*dmu_u_j_i;

            lambda_i(:,j) = lambda_i(:,j) - dlambda_i(:,j);
            mu_u_new =  [mu_i(:,j);u_i(:,j)] - dmu_u_j_i;
            mu_i(:,j) = mu_u_new(1:muDim,1);
            u_i(:,j) = mu_u_new(muDim+1:end,1);
            x_i(:,j) = x_i(:,j) - dx_i(:,j);
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
    end
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
            lambda(:,j,i)  = ...
             lambda(:,j,i)  - p_lambda_Lambda(:,:,j,i) * dlambda(:,j,i);
        end
    end
    parfor (i=1:1:DoP,numThreads)
        p_muu_Lambda_i = p_muu_Lambda(:,:,:,i);
        p_x_Lambda_i = p_x_Lambda(:,:,:,i);
        mu_i = mu(:,:,i);
        u_i = u(:,:,i);
        x_i = x(:,:,i);
        dx_i = dx(:,:,i);
        dlambda_i = dlambda(:,:,i);
        for j = sizeSeg:-1:1
            dmu_u_j_i = p_muu_Lambda_i(:,:,j)* dlambda_i(:,j);
            dx_i(:,j)    = p_x_Lambda_i(:,:,j)  * dlambda_i(:,j);
            mu_u_new  =  [mu_i(:,j);u_i(:,j)] - dmu_u_j_i;
            mu_i(:,j) = mu_u_new(1:muDim,1);
            u_i(:,j)  = mu_u_new(muDim+1:end,1);
            x_i(:,j)  = x_i(:,j) - dx_i(:,j);
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
            x(:,j,i)  = ...
                 x(:,j,i)  - p_x_F(:,:,j,i) * dx(:,j,i);
        end
    end
    parfor (i=1:1:DoP,numThreads)
        lambda_i = lambda(:,:,i);
        mu_i = mu(:,:,i);
        u_i = u(:,:,i);
        x_i = x(:,:,i);
        p_i = p(:,:,i);
        dx_i = dx(:,:,i);
        
        % line search variables
        u_k_i = u_k(:,:,i);
        x_k_i = x_k(:,:,i);
        stepSizeUMax_i = zeros(uDim,sizeSeg);
        stepSizeUMin_i = zeros(uDim,sizeSeg);
        stepSizeXMax_i = zeros(xDim,sizeSeg);
        stepSizeXMin_i = zeros(xDim,sizeSeg);
        stepSizeGMax_i = zeros(GDim,sizeSeg);
        stepSizeGMin_i = zeros(GDim,sizeSeg);
        
        
        dlambda_i = dlambda(:,:,i);
        p_muu_F_i = p_muu_F(:,:,:,i);
        LAMBDA_i = LAMBDA(:,:,:,i);
        
        for j = sizeSeg:-1:1
            dmu_u_i = p_muu_F_i(:,:,j)* dx_i(:,j);
            dlambda_i(:,j)    = LAMBDA_i(:,:,j)  * dx_i(:,j);
            lambda_i(:,j) = lambda_i(:,j) - dlambda_i(:,j);
            mu_u_new =  [mu_i(:,j);u_i(:,j)] - dmu_u_i;
            mu_i(:,j) = mu_u_new(1:muDim,1);
            u_i(:,j) = mu_u_new(muDim+1:end,1);
        end
        lambda(:,:,i) = lambda_i;
        mu(:,:,i)     = mu_i;
        u(:,:,i)      = u_i;
        %% Line Search for primal feasibility
        % Line search of u for primal feasibility
        du_i = u_i - u_k_i;
        % uMax
        if ~all(uMax == veryBigNum)
            for j = 1:sizeSeg
                stepSizeUMax_i(:,j) = (1 - 0.005).*((uMax - u_k_i(:,j))./(du_i(:,j)));
            end
            stepSizeUMax_i(stepSizeUMax_i>1 | stepSizeUMax_i<0) = 1;
            stepSizeMaxUMax_i = min(stepSizeUMax_i(:));
            if isempty(stepSizeMaxUMax_i)
                stepSizeMaxUMax_i = 1;
            end
            stepSizeUMax(i,1) = stepSizeMaxUMax_i;
        end
        % uMin
        if ~all(uMin == -veryBigNum)
            for j = 1:sizeSeg
                stepSizeUMin_i(:,j) = (0.005 - 1).*((u_k_i(:,j) - uMin)./(du_i(:,j)));
            end
            stepSizeUMin_i(stepSizeUMin_i>1 | stepSizeUMin_i<0) = 1;
            stepSizeMaxUMin_i = min(stepSizeUMin_i(:));
            if isempty(stepSizeMaxUMin_i)
                stepSizeMaxUMin_i = 1;
            end
            stepSizeUMin(i,1) = stepSizeMaxUMin_i;
        end
        % Line search of x for primal feasibility
        dx_i = x_i - x_k_i;
        % xMax
        if ~all(xMax == veryBigNum)
            for j = 1:sizeSeg
                stepSizeXMax_i(:,j) = (1 - 0.005).*((xMax - x_k_i(:,j))./(dx_i(:,j)));
            end
            stepSizeXMax_i(stepSizeXMax_i>1 | stepSizeXMax_i<0) = 1;
            stepSizeMaxXMax_i = min(stepSizeXMax_i(:));
            if isempty(stepSizeMaxXMax_i)
                stepSizeMaxXMax_i = 1;
            end
            stepSizeXMax(i,1) = stepSizeMaxXMax_i;
        end
        % xMin
        if ~all(xMin == -veryBigNum)
            for j = 1:sizeSeg
                stepSizeXMin_i(:,j) = (0.005 - 1).*((x_k_i(:,j) - xMin)./(dx_i(:,j)));
            end
            stepSizeXMin_i(stepSizeXMin_i>1 | stepSizeXMin_i<0) = 1;
            stepSizeMaxXMin_i = min(stepSizeXMin_i(:));
            if isempty(stepSizeMaxXMin_i)
                stepSizeMaxXMin_i = 1;
            end
            stepSizeXMin(i,1) = stepSizeMaxXMin_i;
        end
        % Line search of G for primal feasibility
        if GDim ~= 0
            G_i   = OCP_GEN_G(u_i,x_i,p_i);
            G_k_i = OCP_GEN_G(u_k_i,x_k_i,p_i);
            dG_i  = G_i - G_k_i;
            % GMax
            if ~all(GMax == veryBigNum)
                for j=1:sizeSeg
                    stepSizeGMax_i(:,j) = (1 - 0.005).*((GMax - G_k_i(:,j))./(dG_i(:,j)));
                end
                stepSizeGMax_i(stepSizeGMax_i>1 | stepSizeGMax_i<0) = 1;
                stepSizeMaxGMax_i = min(stepSizeGMax_i(:));
                if isempty(stepSizeMaxGMax_i)
                    stepSizeMaxGMax_i = 1;
                end
                stepSizeGMax(i,1) = stepSizeMaxGMax_i;
            end
            % GMin
            if ~all(GMin == -veryBigNum)
                for j=1:sizeSeg
                    stepSizeGMin_i(:,j) = (0.005 - 1).*((G_k_i(:,j) - GMin)./(dG_i(:,j)));
                end
                stepSizeGMin_i(stepSizeGMin_i>1 | stepSizeGMin_i<0) = 1;
                stepSizeMaxGMin_i = min(stepSizeGMin_i(:));
                if isempty(stepSizeMaxGMin_i)
                    stepSizeMaxGMin_i = 1;
                end
                stepSizeGMin(i,1) = stepSizeMaxGMin_i;
            end
        end
    end
    %% Line Search to Guarantee Primal Stability
    stepSize = min([stepSizeUMax;stepSizeUMin;...
                    stepSizeXMax;stepSizeXMin;...
                    stepSizeGMax;stepSizeGMin]);
    if stepSize ~= 1
        lambda = (1-stepSize)*lambda_k + stepSize* lambda;
        mu     = (1-stepSize)*mu_k     + stepSize* mu;
        u      = (1-stepSize)*u_k      + stepSize* u;
        x      = (1-stepSize)*x_k      + stepSize* x;
    end
    %% Update Coupling Variables
    for i=2:1:DoP
        xPrev(:,1,i) = x(:,sizeSeg,i-1);
        lambdaNext(:,sizeSeg,i-1) = lambda(:,1,i);
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
    %% Check norm
    parfor (i=1:1:DoP,numThreads)
        lambda_i = lambda(:,:,i);
        mu_i = mu(:,:,i);
        u_i = u(:,:,i);
        x_i = x(:,:,i);
        p_i = p(:,:,i);
        L_i = L(:,:,i);
        
        xPrev_i = xPrev(:,:,i);
        lambdaNext_i = lambdaNext(:,:,i);
        
        xEq_i = xEq(:,:,i);
        C_i   = C(:,:,i);
        HuT_i = HuT(:,:,i);
        lambdaEq_i = lambdaEq(:,:,i);
                
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
            [L_i(:,j),LBarrier_j_i,Lu_j_i,Lx_j_i] = OCP_L_Lu_Lx(u_j_i,x_j_i,p_j_i);
            C_i(:,j) = zeros(muDim,1);
            Cu_j_i   = zeros(muDim,uDim);
            Cx_j_i   = zeros(muDim,xDim);
            if muDim ~=0
                [C_i(:,j),Cu_j_i,Cx_j_i] = OCP_C_Cu_Cx(u_j_i,x_j_i,p_j_i);
            end
            
            [F_j_i,Fu_j_i,Fx_j_i] = OCP_F_Fu_Fx(u_j_i,x_j_i,p_j_i,discretizationMethod,isMEnabled);

            xEq_i(:,j)      = F_j_i + xPrev_i(:,j);
            HuT_i(:,j)      = Lu_j_i.'  + Fu_j_i.'*lambda_i(:,j);
            lambdaEq_i(:,j) = lambdaNext_i(:,j) + ...
                              Lx_j_i.'  + Fx_j_i.'*lambda_i(:,j);
            if muDim ~= 0
                HuT_i(:,j)      = HuT_i(:,j) + Cu_j_i.'*mu_i(:,j);
                lambdaEq_i(:,j) = lambdaEq_i(:,j) + Cx_j_i.'*mu_i(:,j);
            end
        end
         xEq(:,:,i) = xEq_i;
         C(:,:,i) = C_i;
         HuT(:,:,i) = HuT_i;
         lambdaEq(:,:,i) = lambdaEq_i;
         L(:,:,i) = L_i;
    end
    error = norm([xEq(:);C(:);HuT(:);lambdaEq(:)],2);
    cost  = sum(L(:));
    timerRTIEnd = Timer();
    timeElapsed = timerRTIEnd  - timerRTIStart;
end