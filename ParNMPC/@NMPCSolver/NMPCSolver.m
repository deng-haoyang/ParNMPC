classdef NMPCSolver < handle
   properties
      OCP
      % Newton GaussNewton_LC GaussNewon
      HessianApproximation      = 'GaussNewton';
      nonsingularRegularization = 1e-8;
      descentRegularization     = 0;
   end
   properties( Access = private)
      % default: Euler + GaussNewton + M disabled
      solverMode = uint32(0);
   end
   methods
      function solver = NMPCSolver(OCP)
            solver.OCP = OCP;
            global nonsingularRegularization descentRegularization
            nonsingularRegularization = solver.nonsingularRegularization;
            descentRegularization     = solver.descentRegularization;
      end
      codeGen(solver)
      solverMode = getSolverMode(solver)
      setHessianApproximation(solver,method)
      setNonsingularRegularization(solver,value)
      setDescentRegularization(solver,value)
   end
end