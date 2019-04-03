 function  options = createOptions
 % Create options for NMPC_Solve
    %% options for the initial rho
    % initial rho
    options.rhoInit      = 1e-1;
    % max number of iterations for the initial rho problem
    options.maxIterInit  = 10;
    % KKT tolerence for the initial rho problem
    options.tolInit      = 1e-1;
    %% barrier parameter decaying rate
    options.rhoDecayRate = 0.5;
    %% options for the target rho
    % target/end rho
    options.rhoEnd       = 1e-2;
    % max number of iterations for the initial rho problem
    options.maxIterTotal = 20;
    % KKT tolerence for the end rho problem
    options.tolEnd       = 1e-2;
    %% line search parameters
    % enable or disable line search
    options.isLineSearch       = false;
    % line search method
    options.lineSearchMethod   = 'merit';
    %% degree of parallism
    % 1: in serial, otherwise in parallel
    options.DoP          = 1;
    %% display
    options.printLevel   = 0;
    %% check KKT error after iteration
    % whether to check the KKT error after iteration
    options.checkKKTErrorAfterIteration = true;
end