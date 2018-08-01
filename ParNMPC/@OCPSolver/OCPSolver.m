classdef OCPSolver < handle
   properties
      OCP
      NMPCSolver
      x0 % [xDim,1]
      lambda % [lambdaDim,N]
      mu % [muDim,N]
      u % [uDim,N]
      x % [xDim,N]
      p % [pDim,N]
      LAMBDA % [xDim,xDim,N]
   end
   methods
      function solver = OCPSolver(OCP,NMPCSolver,x0,par)
            solver.OCP = OCP;
            solver.NMPCSolver = NMPCSolver;
            solver.x0  = x0;
            solver.p   = par;
            % declare global variables for OCP_KKTs.m
            global x0Global pValGlobal NGlobal dimGlobal  
            x0Global   =  solver.x0;
            pValGlobal =  solver.p;
            dimGlobal  =  solver.OCP.dim;
            NGlobal = solver.OCP.N;
      end
      [lambda,mu,u,x] = OCPSolve(solver,lambdaInitGuess,muInitGuess,uInitGuess,xInitGuess,method,maxIter)
      [lambda,mu,u,x] = initFromMatFile(solver,matFile)
      [lambda,mu,u,x] = initFromStartEnd(solver,lambdaStart,muStart,uStart,xStart,...
                                                lambdaEnd,  muEnd,  uEnd,  xEnd)
      LAMBDA = getLAMBDA(solver,x0,lambda,mu,u,x,p)
      cost  = getCost(solver,u,x,p)
   end
end