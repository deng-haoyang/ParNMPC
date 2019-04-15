classdef NMPCSolver < handle
   properties
      OCP
      % Newton GaussNewton_LC GaussNewon
      HessianApproximation      = 'GaussNewton';
      nonsingularRegularization = 1e-9;
      descentRegularization     = 0;
      isApproximateInvFx        = false;
   end
   methods
      function solver = NMPCSolver(OCP)
            solver.OCP = OCP;
             % Global variable
            global ParNMPCGlobalVariable
            ParNMPCGlobalVariable.nonsingularRegularization = solver.nonsingularRegularization;
            ParNMPCGlobalVariable.descentRegularization     = solver.descentRegularization;
            ParNMPCGlobalVariable.HessianApproximation      = 'GaussNewton';
            ParNMPCGlobalVariable.isApproximateInvFx        = false;
      end
      codeGen(solver)
      setHessianApproximation(solver,method)
      setNonsingularRegularization(solver,value)
      setDescentRegularization(solver,value)
      setInvFxMethod(solver,method)
      showInfo(solver)
   end
end