function [z_i,stepSizeMaxZ_i,stepSizeMaxG_i] = ...
            fraction_to_boundary_parallel_func(u_i,x_i,z_i,p_i,u_k_i,x_k_i,z_k_i,rho)
        
        
        global ParNMPCGlobalVariable
        zDim                       = ParNMPCGlobalVariable.dim.z;
        [~,sizeSeg] = size(x_i);

        % line search variables

        % update z
        if zDim ~= 0
            for j = 1:1:sizeSeg
                u_k_j_i  = u_k_i(:,j);
                x_k_j_i  = x_k_i(:,j);
                u_j_i  = u_i(:,j);
                x_j_i  = x_i(:,j);
                z_j_i  = z_i(:,j);
                p_j_i  = p_i(:,j);
                
                G_j_i   = OCP_G(u_j_i,x_j_i,p_j_i);
                G_k_j_i = OCP_G(u_k_j_i,x_k_j_i,p_j_i);
                dz_j_i = (z_j_i.*G_j_i - rho)./G_k_j_i;
                z_i(:,j)  = z_j_i -  dz_j_i;
            end
        end

        %% Line Search for feasibility
        if zDim ~= 0
        % z
            dz_i = z_i - z_k_i;
            stepSizeZ_i = (0.05 - 1).*(z_k_i./dz_i);
            stepSizeZ_i(stepSizeZ_i>1 | stepSizeZ_i<0) = 1;
            stepSizeMaxZ_i = min(stepSizeZ_i(:));
            if isempty(stepSizeMaxZ_i)
                stepSizeMaxZ_i = 1;
            end

        % G 
            G_i   = OCP_G(u_i,x_i,p_i);
            G_k_i = OCP_G(u_k_i,x_k_i,p_i);
            dG_i  = G_i - G_k_i;
            % GMin
            stepSizeG_i = (0.05 - 1).*(G_k_i./dG_i);
            stepSizeG_i(stepSizeG_i>1 | stepSizeG_i<0) = 1;
            stepSizeMaxG_i = min(stepSizeG_i(:));
            if isempty(stepSizeMaxG_i)
                stepSizeMaxG_i = 1;
            end
        end
end

