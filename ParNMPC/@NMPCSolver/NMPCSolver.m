classdef NMPCSolver < handle
   properties
      OCP
      % Newton GaussNewton_LC GaussNewon
      HessianApproximation = 'GaussNewton';
   end
   properties( Access = private)
      % default: Euler + GaussNewton + M disabled
      solverMode = uint32(0);
   end
   methods
      function solver = NMPCSolver(OCP)
            solver.OCP = OCP;
      end
      codeGen(solver)
      solverMode = getSolverMode(solver)
      setHessianApproximation(solver,method)
   end
end