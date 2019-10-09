function [KKTxEquation_i,KKTC_i,KKTHu_i,KKTlambdaEquation_i,L_i,LB_i] = KKT_error_func(lambda_i,mu_i,u_i,x_i,p_i_codegen,xPrev_i,lambdaNext_i,rho,i)

    [~,sizeSeg] = size(x_i);

    global ParNMPCGlobalVariable
    discretizationMethod       = ParNMPCGlobalVariable.discretizationMethod;
    isMEnabled                 = ParNMPCGlobalVariable.isMEnabled;
    lambdaDim                  = ParNMPCGlobalVariable.dim.x;
    muDim                      = ParNMPCGlobalVariable.dim.mu;
    uDim                       = ParNMPCGlobalVariable.dim.u;
    xDim                       = ParNMPCGlobalVariable.dim.x;
    pDim                       = ParNMPCGlobalVariable.dim.p;
        
    % make the generated code's parameter contain p
    if pDim == 0
        p_i = zeros(pDim,sizeSeg);
    else
        p_i = p_i_codegen;
    end

        
    xEq_i      = zeros(xDim,sizeSeg);
    C_i        = zeros(muDim,sizeSeg);
    HuT_i      = zeros(uDim,sizeSeg);
    lambdaEq_i = zeros(lambdaDim,sizeSeg);

    
    KKTxEquation_i      = zeros(1,sizeSeg);
    KKTC_i              = zeros(1,sizeSeg);
    KKTHu_i             = zeros(1,sizeSeg);
    KKTlambdaEquation_i = zeros(1,sizeSeg);
    L_i                 = zeros(1,sizeSeg);
    LB_i                = zeros(1,sizeSeg);

        
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
        [L_i(1,j),  Lu_j_i,  Lx_j_i]  = OCP_L_Lu_Lx(u_j_i,x_j_i,p_j_i);
        [LB_i(1,j), LBu_j_i, LBx_j_i] = OCP_LB_LBu_LBx(u_j_i,x_j_i,p_j_i);
        LAllu_j_i = Lu_j_i + rho*LBu_j_i;
        LAllx_j_i = Lx_j_i + rho*LBx_j_i;

        C_i(:,j) = zeros(muDim,1);
        Cu_j_i   = zeros(muDim,uDim);
        Cx_j_i   = zeros(muDim,xDim);
        if muDim ~=0
            [C_i(:,j),Cu_j_i,Cx_j_i] = OCP_C_Cu_Cx(u_j_i,x_j_i,p_j_i,i);
        end

        [F_j_i,Fu_j_i,Fx_j_i] = OCP_F_Fu_Fx(u_j_i,x_j_i,p_j_i,discretizationMethod,isMEnabled,i);

        xEq_i(:,j)      = F_j_i + xPrev_i(:,j);
        HuT_i(:,j)      = LAllu_j_i.'  + Fu_j_i.'*lambda_i(:,j);
        lambdaEq_i(:,j) = lambdaNext_i(:,j) + ...
                          LAllx_j_i.'  + Fx_j_i.'*lambda_i(:,j);
        if muDim ~= 0
            HuT_i(:,j)      = HuT_i(:,j) + Cu_j_i.'*mu_i(:,j);
            lambdaEq_i(:,j) = lambdaEq_i(:,j) + Cx_j_i.'*mu_i(:,j);
        end
        
        %
        KKTxEquation_i(1,j)      = norm(xEq_i(:,j), Inf);
        KKTC_i(1,j)              = norm(C_i(:,j), Inf);
        KKTHu_i(1,j)             = norm(HuT_i(:,j), Inf);
        KKTlambdaEquation_i(1,j) = norm(lambdaEq_i(:,j), Inf);
    end
end

