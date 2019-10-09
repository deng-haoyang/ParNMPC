 function  options = createRTOptions
 % Create options for NMPC_Solve
    %% options
    % rho
    options.rho      = 1e-1;
    % max number of iterations
    options.maxIter  = 10; 
    % tolerance for the state equation
    options.xEqTol   = 1e-2; 
    % tolerance for the constraint equation
    options.CEqTol   = 1e-2; 
    % tolerance for the first-order optimality
    options.firstOrderOptTol = 1e-2; 
    %% degree of parallism
    % 1: in serial, otherwise in parallel
    options.DoP          = 1;
    %% lock memory
    options.lockMemory   = true;
    options.busyWaiting  = true;
    %% check KKT error after iteration
    % whether to check the KKT error after iteration
    options.checkKKTErrorAfterIteration = true;
    %% closed loop simulation example
    options.generateClosedLoopSimulationExample = true;
    options.x0 = [];
    options.p  = [];
    options.Ts = [];
    options.solution = [];
end