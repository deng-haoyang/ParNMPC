% set options
options              = createRTOptions(); 
options.DoP          = 4; 
options.rho          = 1e-2; 
options.maxIter      = 10; 
options.checkKKTErrorAfterIteration = true; 
%% closed-loop simulation example
options.x0 = x0; 
options.p  = p;   
options.Ts = 0.001; 
% initial guess
options.solution = solution;
%% generate code
RT_NMPC_Solve_CodeGen('C',options); 
