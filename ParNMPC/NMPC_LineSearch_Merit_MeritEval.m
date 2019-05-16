function merit = NMPC_LineSearch_Merit_MeritEval(xPrev,rho,u,x,p,phiX,phiC)

    % Global variables
    global ParNMPCGlobalVariable
    discretizationMethod       = ParNMPCGlobalVariable.discretizationMethod;
    isMEnabled                 = ParNMPCGlobalVariable.isMEnabled;
    muDim                      = ParNMPCGlobalVariable.dim.mu;
    
    [~,sizeSeg,DoP]  = size(x);
    if coder.target('MATLAB') % Normal excution
        % in serial
        numThreads = 0;
    else % Code generation
        numThreads = DoP;
    end
    % Init
    Merit = zeros(1,sizeSeg,DoP);
    parfor (i=1:1:DoP,numThreads)
%     for i=1:1:DoP
        u_i = u(:,:,i);
        x_i = x(:,:,i);
        p_i = p(:,:,i);
        xPrev_i   = xPrev(:,:,i);
        Merit_i   = Merit(:,:,i);
        phiX_i = phiX;%
        phiC_i = phiC;%
        for j = sizeSeg:-1:1
            u_j_i   = u_i(:,j);
            x_j_i   = x_i(:,j);
            p_j_i   = p_i(:,j);
            phiX_j_i = phiX_i;%
            phiC_j_i = phiC_i;%
            % Function Evaluation
            if j > 1
                xPrev_i(:,j) = x_i(:,j-1);
            end
            xPrev_j_i = xPrev_i(:,j);
            
            L_j_i    = OCP_L(u_j_i,x_j_i,p_j_i);
            LB_j_i   = OCP_LB(u_j_i,x_j_i,p_j_i);
            LAll_j_i = L_j_i + rho*LB_j_i;
            C_j_i    = zeros(muDim,1);
            if muDim ~= 0
                C_j_i = OCP_C(u_j_i,x_j_i,p_j_i,i);
            end
            F_j_i     = OCP_F(u_j_i,x_j_i,p_j_i,discretizationMethod,isMEnabled,i);
            xEq_j_i   = F_j_i + xPrev_j_i;
            Merit_i(:,j) = LAll_j_i + phiX_j_i.'*abs(xEq_j_i) + phiC_j_i.'*abs(C_j_i);
        end
        Merit(:,:,i) = Merit_i;
    end
    merit = norm(Merit(:),1);
end