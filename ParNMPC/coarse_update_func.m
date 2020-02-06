function [lambda_i,mu_i,u_i,x_i,xPrev_i,lambdaNext_i,...
          p_muu_F_i, p_muu_Lambda_i, p_lambda_Lambda_i, p_x_Lambda_i, p_x_F_i,LAMBDA_i,...
          KKTxEquation_i,KKTC_i,KKTHu_i,KKTlambdaEquation_i,L_i,LB_i] = ...
        coarse_update_func(lambda_i,mu_i,u_i,x_i,z_i,p_i,xPrev_i,lambdaNext_i,LAMBDA_i,rho,i)

        [~,sizeSeg] = size(x_i);

        global ParNMPCGlobalVariable
        discretizationMethod       = ParNMPCGlobalVariable.discretizationMethod;
        isMEnabled                 = ParNMPCGlobalVariable.isMEnabled;
        nonsingularRegularization  = ParNMPCGlobalVariable.nonsingularRegularization;
        descentRegularization      = ParNMPCGlobalVariable.descentRegularization;
        isApproximateInvFx         = ParNMPCGlobalVariable.isApproximateInvFx;
        lambdaDim                  = ParNMPCGlobalVariable.dim.lambda;
        muDim                      = ParNMPCGlobalVariable.dim.mu;
        uDim                       = ParNMPCGlobalVariable.dim.u;
        xDim                       = ParNMPCGlobalVariable.dim.x;
        zDim                       = ParNMPCGlobalVariable.dim.z;
        pDim                       = ParNMPCGlobalVariable.dim.p;
        
        
        % regularization
        NSRMatrix  = -nonsingularRegularization*eye(muDim);
        uDRMatrix  =  descentRegularization*eye(uDim);
        xDRMatrix  =  descentRegularization*eye(xDim);

        p_muu_F_i         = zeros(muDim+uDim,xDim,sizeSeg);
        p_muu_Lambda_i    = zeros(muDim+uDim,xDim,sizeSeg);
        p_lambda_Lambda_i = zeros(xDim,xDim,sizeSeg);
        p_x_Lambda_i      = zeros(xDim,xDim,sizeSeg);
        p_x_F_i           = zeros(xDim,xDim,sizeSeg);
                
        KKTxEquation_i      = zeros(1,sizeSeg);
        KKTC_i              = zeros(1,sizeSeg);
        KKTHu_i             = zeros(1,sizeSeg);
        KKTlambdaEquation_i = zeros(1,sizeSeg);
        L_i                 = zeros(1,sizeSeg);
        LB_i                = zeros(1,sizeSeg);
        
        for j = sizeSeg:-1:1
            lambda_j_i  = lambda_i(:,j);
            mu_j_i  = mu_i(:,j);
            u_j_i   = u_i(:,j);
            x_j_i   = x_i(:,j);
            z_j_i   = z_i(:,j);
            p_j_i   = p_i(:,j);
            
            % Function and Jacobian
            [L_j_i,Lu_j_i, Lx_j_i]    = OCP_L_Lu_Lx(u_j_i,x_j_i,p_j_i);
            [LB_j_i,LBu_j_i,LBx_j_i]   = OCP_LB_LBu_LBx(u_j_i,x_j_i,p_j_i);
            
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
            p_muu_Lambda_j_i    = Inv_dKKT23_mu_u_j_i*p_x_muu_j_i.';
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
            KKTxEquation_i(1,j)      = norm(xEq_j_i, Inf);
            KKTC_i(1,j)              =  norm(C_j_i, Inf);
            KKTHu_i(1,j)             = norm(HAlluT_j_i, Inf);
            KKTlambdaEquation_i(1,j) = norm(lambdaEq_j_i, Inf);
            L_i(1,j)                 = L_j_i;
            LB_i(1,j)                = LB_j_i;
        end
end

