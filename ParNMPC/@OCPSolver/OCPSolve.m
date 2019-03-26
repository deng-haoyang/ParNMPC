function [lambda,mu,u,x] = OCPSolve(solver,lambdaInitGuess,muInitGuess,uInitGuess,xInitGuess,method,maxIter)
    % lambdaInitGuess: [lambdaDim,N]
    % muInitGuess:: [muDim,N]
    % uInitGuess:: [uDim,N]
    % xInitGuess:: [xDim,N]
    % method: 'NMPC_Iter', 'fmincon'
    
    lambdaDim = solver.OCP.dim.lambda;
    muDim     = solver.OCP.dim.mu;
    uDim      = solver.OCP.dim.u;
    xDim      = solver.OCP.dim.x;
    pDim      = solver.OCP.dim.p;
    subDim    = solver.OCP.dim.subDim;
    N         = solver.OCP.N;
    discretizationMethod = solver.OCP.discretizationMethod;
    isMEnabled = solver.OCP.isMEnabled;
    x0     = solver.x0;
    p      = solver.p;
    theta  = zeros(xDim,xDim,N);
    
    lambda = lambdaInitGuess;
    mu     = muInitGuess;
    u      = uInitGuess;
    x      = xInitGuess;
    
    uMax   = solver.OCP.uMax.value;
    uMin   = solver.OCP.uMin.value;
    xMax   = solver.OCP.xMax.value;
    xMin   = solver.OCP.xMin.value;
    GMax   = solver.OCP.GMax.value;
    GMin   = solver.OCP.GMin.value;
    
    [GDim,unused] = size(GMax);

    exitflag = -2;
    solveMode = 0;
    switch method
        case 'NMPC_Iter'
            solveMode = 1;
        case 'fmincon'
            solveMode = 2;
        otherwise
            solveMode = 2;
    end
    switch solveMode
        case 2 % fmincon
            uMax(uMax == solver.OCP.veryBigNum) = Inf;
            uMin(uMin == -solver.OCP.veryBigNum) = -Inf;
            xMax(uMax == solver.OCP.veryBigNum) = Inf;
            xMin(uMin == -solver.OCP.veryBigNum) = -Inf;
            GMax(GMax == solver.OCP.veryBigNum) = Inf;
            GMin(GMin == -solver.OCP.veryBigNum) = -Inf;
            
            X0_matrix = [u;x];
            X0 = X0_matrix(:);
            lb = repmat([uMin;xMin],N,1);
            ub = repmat([uMax;xMax],N,1);
            % linear inequality
            A_ieq =  zeros(GDim*N,(uDim+xDim)*N);
            ub_ieq = zeros(GDim*N,1);
            lb_ieq = zeros(GDim*N,1);
            % Ax < b
            for i = 1:N
                Gu_i = OCP_GEN_Gu(u(:,i),x(:,i),p(:,i));
                Gx_i = OCP_GEN_Gx(u(:,i),x(:,i),p(:,i));
                A_ieq((i-1)*GDim+1:i*GDim,(i-1)*(uDim+xDim)+1:i*(uDim+xDim)) = ...
                    [Gu_i,Gx_i];
                offset_i = OCP_GEN_G(zeros(uDim,1),zeros(xDim,1),p(:,i));
                ub_ieq((i-1)*GDim+1:i*GDim,1) = GMax - offset_i;
                lb_ieq((i-1)*GDim+1:i*GDim,1) = GMin - offset_i;
            end
            A_ieq_all = [A_ieq;-A_ieq];
            b_ieq_all = [ub_ieq;-lb_ieq];
            idx_ieq = ~isinf(b_ieq_all);
            b_ieq_all = b_ieq_all(idx_ieq);
            A_ieq_all = A_ieq_all(idx_ieq,:);
            % compatibility
            verRelease = version('-release');
            verReleaseYearIndex = isstrprop(verRelease,'digit');
            verReleaseYear = num2str(verRelease(verReleaseYearIndex==1));
            if verReleaseYear > 2015
                MaxFunctionEvaluations = 'MaxFunctionEvaluations';
                MaxIterations          = 'MaxIterations';
            else
                MaxFunctionEvaluations = 'MaxFunEvals';
                MaxIterations          = 'MaxIter';
            end

            options = optimoptions('fmincon',...
                                'Algorithm','interior-point',...
                                'Display','iter',...
                                'Diagnostics','off',...
                                 MaxFunctionEvaluations,300000,...
                                 MaxIterations,maxIter,...
                                'StepTolerance',0,...
                                'HonorBounds',true);
            [X,fval,exitflag,output,lambda_fmincon,grad,hessian] = ...
                fmincon(@fmincon_L,X0,A_ieq_all,b_ieq_all,[],[],lb,ub,@fmincon_Eq,options);
            ux_vec   = reshape(X,uDim+xDim,N);
            lambda_vec = lambda_fmincon.eqnonlin(1:xDim*N);
            mu_vec     = lambda_fmincon.eqnonlin(xDim*N+1:end);
            u          = ux_vec(1:uDim,:);
            x          = ux_vec(uDim+1:end,:);
            lambda     = reshape(lambda_vec,xDim,N);
            mu         = reshape(mu_vec,muDim,N);
        case 1 % NMPC_Iter
            for i=1:maxIter
                [lambda,mu,u,x,theta,cost,error,timeElapsed] =...
                    NMPC_Iter(x0,lambda,mu,u,x,p,theta,1);
                disp(['Iter: ',num2str(i),...
                      '   cost:' ,num2str(cost),...
                      '   error:' ,num2str(error)]);
                if error < 1e-7
                    break;
                end
            end
            exitflag = 0;
        otherwise
                lambda = lambdaInitGuess;
                mu     = muInitGuess;
                u      = uInitGuess;
                x      = xInitGuess;
                exitflag = -2;
    end
%     switch mode
%         
%     end
end