function [lambda_i,mu_i,u_i,z_i,stepSizeMaxZ_i,stepSizeMaxG_i] = ...
            forward_correction_parallel_func(lambda_i,mu_i,u_i,x_i,z_i,p_i_codegen,dx_i,u_k_i,x_k_i,z_k_i_codegen,p_muu_F_i,LAMBDA_i,rho)
        
        [~,sizeSeg] = size(x_i);
        
        global ParNMPCGlobalVariable
        muDim                      = ParNMPCGlobalVariable.dim.mu;
        zDim                       = ParNMPCGlobalVariable.dim.z;
        pDim                       = ParNMPCGlobalVariable.dim.p;
        
        % make the generated code's parameter contain z,p
        if zDim == 0
            z_k_i = zeros(zDim,sizeSeg);
        else
            z_k_i  = z_k_i_codegen;
        end
        if pDim == 0
            p_i = zeros(pDim,sizeSeg);
        else
            p_i = p_i_codegen;
        end
        
        % line search variables
        stepSizeZ_i    = zeros(zDim,sizeSeg);
        stepSizeG_i    = zeros(zDim,sizeSeg);
        stepSizeMaxZ_i = ones(sizeSeg,1);
        stepSizeMaxG_i = ones(sizeSeg,1);
        
        for j = sizeSeg:-1:1
            dmu_u_i = p_muu_F_i(:,:,j)* dx_i(:,j);
            dlambda_j_i    = LAMBDA_i(:,:,j)  * dx_i(:,j);
            lambda_i(:,j) = lambda_i(:,j) - dlambda_j_i;
            mu_u_new =  [mu_i(:,j);u_i(:,j)] - dmu_u_i;
            mu_i(:,j) = mu_u_new(1:muDim,1);
            u_i(:,j) = mu_u_new(muDim+1:end,1);
        end
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
        end
        %% Line Search for feasibility
        if zDim ~= 0
        % z
            dz_i = z_i - z_k_i;
            for j = 1:sizeSeg
                    stepSizeZ_ij = (0.05 - 1).*((z_k_i(:,j))./(dz_i(:,j)));
                    stepSizeZ_ij(stepSizeZ_ij>1 | stepSizeZ_ij<0) = 1;
                    stepSizeZ_i(:,j) = stepSizeZ_ij;
            end
            stepSizeMaxZ_i = min(stepSizeZ_i).';

        % G 
            G_i   = OCP_G(u_i,x_i,p_i);
            G_k_i = OCP_G(u_k_i,x_k_i,p_i);
            dG_i  = G_i - G_k_i;
            % GMin
            for j=1:sizeSeg
                stepSizeG_ij = (0.05 - 1).*(G_k_i(:,j)./dG_i(:,j));
                stepSizeG_ij(stepSizeG_ij>1 | stepSizeG_ij<0) = 1;
                stepSizeG_i(:,j) = stepSizeG_ij;
            end
            stepSizeMaxG_i = min(stepSizeG_i).';
        end

end

