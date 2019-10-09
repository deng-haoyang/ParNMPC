function solution = NMPC_SolveOffline(x0,p,solutionInitGuess,rho,maxIter)
    
    global ParNMPCGlobalVariable
    N   = ParNMPCGlobalVariable.N;
    dim = ParNMPCGlobalVariable.dim;
    % lambda
    try
        lambda = solutionInitGuess.lambda;
        solutionInitGuess.lambda = interpolation(lambda,N);
    catch
        warning('Initial guess of lambda is not provided!');
        solutionInitGuess.lambda = zeros(dim.lambda,N);
    end
    % mu
    try
        mu = solutionInitGuess.mu;
        solutionInitGuess.mu = interpolation(mu,N);
    catch
        warning('Initial guess of mu is not provided!');
        solutionInitGuess.mu = zeros(dim.mu,N);
    end
    % u
    try
        u = solutionInitGuess.u;
        solutionInitGuess.u = interpolation(u,N);
    catch
        error('Initial guess of u is not provided!');
    end
    % x
    try
        x = solutionInitGuess.x;
        solutionInitGuess.x = interpolation(x,N);
    catch
        error('Initial guess of x is not provided!');
    end
    % z
    try
        z = solutionInitGuess.z;
        solutionInitGuess.z = interpolation(z,N);
    catch
        warning('Initial guess of z is not provided!');
        solutionInitGuess.z = ones(dim.z,N);
    end
    checkFeasibility(solutionInitGuess,p);
    solutionInitGuess.LAMBDA = zeros(dim.x,dim.x,N);
    ParNMPCGlobalVariable.solutionInitGuess = solutionInitGuess;

    %%
    clear NMPC_Solve
    options = createOptions();
    options.DoP          = 1;
    options.rhoInit      = rho;
    options.rhoEnd       = rho;
    options.tolInit      = 1e-5;
    options.tolEnd       = 1e-5;
    options.maxIterTotal = maxIter;
    options.isLineSearch = true;
    options.printLevel   = 1;
    options.lineSearchMethod = 'filter';
    disp(' ');
    disp('Solving the very first optimal control problem offline...');
    disp('Note that this function can only be used offline to provide an accurate initial guess');
    disp(['Barrier parameter (rho): ', num2str(rho)]);
    disp(['Max number of iterations: ', num2str(maxIter)]);
    disp(['is linesearch enabled: ', 'Yes']);
    disp(['Linesearch method: ', options.lineSearchMethod]);
    try
        [solution,output] = NMPC_Solve(x0,p,options);
        disp([ 'Solution obtained:', ' iterations: ',  num2str(output.iterTotal), ', KKTError:' ,num2str(output.KKTError)]);
    catch
        solution = solutionInitGuess;
        warning('Failed! The (interpolated) provided initial guess is returned!');
    end
end

function x_N = interpolation(x_in,N)
    
    % x_in: [xDim,M]
    % x_N:  [xDim,N]
    [xDim,M] = size(x_in);
    if M == 1
        x_N = repmat(x_in,1,N);
    else
        XFile    = x_in(:);
        % Interpolation
        XInterp = zeros(N*xDim,1);
        if N == 1
            XInterp = XFile(1:xDim,1);
        else
            for i=1:xDim
                dataOrig = XFile(i:xDim:end);
                [sizeOrig,~] = size(dataOrig);
                interpStep = (sizeOrig-1)/(N-1);
                interpPoint = 1:interpStep:sizeOrig;
                dataInterp = interp1(dataOrig,interpPoint,'pchip');
                XInterp(i:xDim:end) = dataInterp.';
            end
        end
        x_N = reshape(XInterp,xDim,N);
    end
end