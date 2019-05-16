function [l1Norm_LALL,l1Norm_xEq,l1Norm_C] = NMPC_LineSearch_Filter_PairEval(xPrev,rho,u,x,p)

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
    l1Norm_LALL_Split = zeros(1,sizeSeg,DoP);
    l1Norm_xEq_Split  = zeros(1,sizeSeg,DoP);
    l1Norm_C_Split    = zeros(1,sizeSeg,DoP);
    parfor (i=1:1:DoP,numThreads)
%     for i=1:1:DoP
        u_i = u(:,:,i);
        x_i = x(:,:,i);
        p_i = p(:,:,i);
        xPrev_i   = xPrev(:,:,i);
        l1Norm_LAll_i    = zeros(1,sizeSeg);
        l1Norm_xEq_i     = zeros(1,sizeSeg);
        l1Norm_C_i       = zeros(1,sizeSeg);
        for j = sizeSeg:-1:1
            u_j_i   = u_i(:,j);
            x_j_i   = x_i(:,j);
            p_j_i   = p_i(:,j);
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
            
            l1Norm_LAll_i(:,j) = LAll_j_i;
            l1Norm_xEq_i(:,j)  = norm(xEq_j_i,1);
            l1Norm_C_i(:,j)    = norm(C_j_i,1);
        end
        l1Norm_LALL_Split(:,:,i) =  l1Norm_LAll_i;
        l1Norm_xEq_Split(:,:,i)  =  l1Norm_xEq_i;
        l1Norm_C_Split(:,:,i)    =  l1Norm_C_i;
    end
    l1Norm_LALL = sum(l1Norm_LALL_Split(:));
    l1Norm_xEq  = sum(l1Norm_xEq_Split(:));
    l1Norm_C    = sum(l1Norm_C_Split(:));

end