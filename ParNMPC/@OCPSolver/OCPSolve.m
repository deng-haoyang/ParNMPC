function [lambda,mu,u,x] = OCPSolve(solver,lambdaInitGuess,muInitGuess,uInitGuess,xInitGuess,method)
    % lambdaInitGuess: [lambdaDim,N]
    % muInitGuess:: [muDim,N]
    % uInitGuess:: [uDim,N]
    % xInitGuess:: [xDim,N]
    % method: 'fsolve', 'NMPC_Iter_GaussNewton'
    
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
    exitflag = -2;
    solveMode = 0;
    switch method
        case 'fsolve'
            solveMode = 0;
        case 'NMPC_Iter_GaussNewton'
            if strcmp(solver.NMPCSolver.HessianApproximation,'GaussNewton')
                solveMode = 1;
            else
                solveMode = 0;
            end
        otherwise
            solveMode = 0;
    end
    switch solveMode
        case 1 % NMPC_Iter_GaussNewton
            for i=1:100
                [lambda,mu,u,x,theta,cost,error,timeElapsed] =...
                    NMPC_Iter(x0,lambda,mu,u,x,p,theta,discretizationMethod,isMEnabled);
                disp(['Iter: ',num2str(i),...
                      '   cost:' ,num2str(cost),...
                      '   error:' ,num2str(error)]);
            end
            exitflag = 0;
        case 0 % fsolve
            % compatibility
            verRelease = version('-release');
            verReleaseYearIndex = isstrprop(verRelease,'digit');
            verReleaseYear = num2str(verRelease(verReleaseYearIndex==1));
            if verReleaseYear>2015
                MaxFunctionEvaluations = 'MaxFunctionEvaluations';
                MaxIterations          = 'MaxIterations';
            else
                MaxFunctionEvaluations = 'MaxFunEvals';
                MaxIterations          = 'MaxIter';
            end
            fun = @OCP_KKTs_mex;%
            % trust-region-dogleg levenberg-marquardt  trust-region-reflective
            options = optimoptions( 'fsolve',...
                                    'Algorithm','levenberg-marquardt',...
                                    'Display','final',...
                                    'PlotFcn',@optimplotfirstorderopt,...
                                    'Diagnostics','off',...
                                     MaxFunctionEvaluations,300000,...
                                     MaxIterations,2000);
                                
            initGuessMatrix = [lambdaInitGuess;...
                               muInitGuess;...
                               uInitGuess;...
                               xInitGuess];
            initGuess = initGuessMatrix(:);
            [X,fval,exitflag,output] = fsolve(fun,initGuess,options);
            if exitflag >= -1 % optimum found
                XSplit = reshape(X,subDim,N);
                lambda = XSplit(1:lambdaDim,:);
                mu     = XSplit(lambdaDim+1:lambdaDim+muDim,:);
                u      = XSplit(lambdaDim+muDim+1:lambdaDim+muDim+uDim,:);
                x      = XSplit(lambdaDim+muDim+uDim+1:end,:);
            end
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