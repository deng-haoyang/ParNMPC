function [solution,output] = NMPC_Solve(x0,p,options)
    tStart = Timer();
    
    persistent lambdaInit muInit uInit xInit zInit LAMBDAInit;
    
    global ParNMPCGlobalVariable
    dim = ParNMPCGlobalVariable.dim;
    N   = ParNMPCGlobalVariable.N;
    
    % only for the very first problem
    solutionInitGuess = ParNMPCGlobalVariable.solutionInitGuess;
    
    % Reshape
    sizeSeg     = N/options.DoP;
    pSplit      = reshape(p,      dim.p,        sizeSeg, options.DoP);

    if isempty(xInit)
        lambdaInit = reshape(solutionInitGuess.lambda, dim.lambda,   sizeSeg, options.DoP);
        uInit      = reshape(solutionInitGuess.u,      dim.u,        sizeSeg, options.DoP);
        xInit      = reshape(solutionInitGuess.x,      dim.x,        sizeSeg, options.DoP);
        LAMBDAInit = reshape(solutionInitGuess.LAMBDA, dim.x, dim.x, sizeSeg, options.DoP);
        % assert
        if coder.target('MATLAB') % Normal excution
            checkFeasibility(solutionInitGuess,p);
            checkOptions(options);
        end
    end
    if dim.mu ~= 0
        muInit     = reshape(solutionInitGuess.mu,     dim.mu,       sizeSeg, options.DoP);
    end
    if dim.z ~= 0
        zInit      = reshape(solutionInitGuess.z,      dim.z,        sizeSeg, options.DoP);
    end    
    
    % Init 
    lambdaSplit = lambdaInit;
    if dim.mu ~= 0
        muSplit = muInit;
    else
        muSplit = zeros(dim.mu,sizeSeg, options.DoP);
    end
    uSplit      = uInit;
    xSplit      = xInit;
    if dim.z ~= 0
        zSplit = zInit;
    else
        zSplit = zeros(dim.z,sizeSeg, options.DoP);
    end
    LAMBDASplit = LAMBDAInit;
    
    output   = createOutput();
    solution = createSolution(dim,N);
    costL = 0;
    error = 0;
    tLineSearch = 0;
    if (options.rhoInit == options.rhoEnd)
        options.maxIterInit = options.maxIterTotal;
        options.tolInit = options.tolEnd;
    end
    rho     = options.rhoInit;
    mode    = 1;
    
    % initialize a filter [LAll;xEq+C;flag]
    lineSearchFilterWidth = 10;
    lineSearchFilter = zeros(3,lineSearchFilterWidth);
    
    % Iteration
    for iter=1:options.maxIterTotal
        % backup
        lambdaSplit_k = lambdaSplit;
        muSplit_k     = muSplit;
        uSplit_k      = uSplit;
        xSplit_k      = xSplit;
        %% Search direction
        [lambdaSplit,muSplit,uSplit,xSplit,zSplit,LAMBDASplit,KKTError,costL,tSearchDirection] = ...
            NMPC_Solve_SearchDirection(x0,pSplit,rho,lambdaSplit,muSplit,uSplit,xSplit,zSplit,LAMBDASplit);
        output.timeElapsed.searchDirection = output.timeElapsed.searchDirection + tSearchDirection;
        %% Line search
        stepSize = 1;
        if options.isLineSearch
            switch options.lineSearchMethod
                case 'merit'
                    scaling = 1.5;
                    lambdaSplitAbs = abs(lambdaSplit);
                    lambdaSplitMax3 =  max(lambdaSplitAbs,[],2);
                    phiX = max(lambdaSplitMax3,[],3);
                    muSplitAbs = abs(muSplit);
                    muSplitMax3 =  max(muSplitAbs,[],2);
                    phiC = max(muSplitMax3,[],3);
                    [lambdaSplit,muSplit,uSplit,xSplit,stepSize,tLineSearch] = ...
                        NMPC_LineSearch_Merit(x0,pSplit,rho,lambdaSplit_k,muSplit_k,uSplit_k,xSplit_k,...
                                        lambdaSplit,muSplit,uSplit,xSplit,phiX*scaling,phiC*scaling);
                case 'filter'
                    [lambdaSplit,muSplit,uSplit,xSplit,lineSearchFilter,stepSize,tLineSearch] = ...
                        NMPC_LineSearch_Filter(x0,pSplit,rho,lambdaSplit_k,muSplit_k,uSplit_k,xSplit_k,...
                                        lambdaSplit,muSplit,uSplit,xSplit,lineSearchFilter);
                otherwise
                    if coder.target('MATLAB') % Normal excution
                            warning('Specified linesearch method is not supported!');
                    end
            end
            output.timeElapsed.lineSearch = output.timeElapsed.lineSearch + tLineSearch;
        end
        %% KKT error
        tKKTErrorCheck = 0;
        if options.checkKKTErrorAfterIteration
            [KKTError,costL,tKKTErrorCheck]   = ...
                NMPC_KKTError(x0,pSplit,rho,lambdaSplit,muSplit,uSplit,xSplit);
            KKTErrorScaling = 1;
        else
            % avoid chattering of the num of iter
            KKTErrorScaling = 5;
        end
        sMax = 100;
        lambda_L1Norm = norm(lambdaSplit(:),1);
        HuScaling =  (lambda_L1Norm + norm(muSplit(:),1))/(dim.lambda+dim.mu)/N;
        HuScaling = max(sMax,HuScaling)/sMax;
        costateEquationScaling = max(sMax,lambda_L1Norm/dim.lambda/N)/sMax;
        error = max([KKTError.stateEquation*KKTErrorScaling;...
                     KKTError.C/KKTErrorScaling;...
                     KKTError.Hu/HuScaling/KKTErrorScaling;...
                     KKTError.costateEquation/costateEquationScaling/KKTErrorScaling]);
        output.timeElapsed.KKTErrorCheck = output.timeElapsed.KKTErrorCheck + tKKTErrorCheck;
        %% print
        if coder.target('MATLAB') % Normal excution
            if options.printLevel == 1
                printMsg = ['Iter: ',num2str(iter),...
                            '   KKTError: ',num2str(error),...
                            '   Cost: ',num2str(costL),...
                            '   rho: ',num2str(rho),...
                            '   Step size: ',num2str(stepSize)];
                disp(printMsg);
            end
        end
        %% barrier parameter update
        switch mode
            case 1 % init
                if (error < options.tolInit) || (iter >= options.maxIterInit)
                    mode = 2;
                    lambdaInit = lambdaSplit;
                    if dim.mu ~= 0
                        muInit     = muSplit;
                    end
                    uInit      = uSplit;
                    xInit      = xSplit;
                    if dim.z ~= 0
                        zInit     = zSplit;
                    end
                    LAMBDAInit = LAMBDASplit;

                    output.iterInit          = iter;
                    if (options.rhoInit == options.rhoEnd) && (error < options.tolEnd)
                        output.exitflag = 1;
                        break;
                    end
                end
            case 2 % decay
                rho = rho * options.rhoDecayRate;
                rho(rho<options.rhoEnd) = options.rhoEnd;
                if (error<options.tolEnd) && (rho == options.rhoEnd)
                    output.exitflag = 1;
                    break;
                end
        end
    end
    %% Reshape
    solution.lambda = reshape(lambdaSplit, dim.lambda,   N);
    solution.mu     = reshape(muSplit,     dim.mu,       N);
    solution.u      = reshape(uSplit,      dim.u,        N);
    solution.x      = reshape(xSplit,      dim.x,        N);
    solution.z      = reshape(zSplit,      dim.z,        N);
    solution.LAMBDA = reshape(LAMBDASplit, dim.x, dim.x, N);
    
    output.cost            = costL;
    output.KKTError        = error;
    output.rho             = rho;
    output.iterTotal       = iter;
    
    tEnd = Timer();

    output.timeElapsed.total = tEnd-tStart;
end


