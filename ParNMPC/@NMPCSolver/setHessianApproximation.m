function setHessianApproximation(solver,method)

if solver.OCP.isMEnabled == false && ~isa(solver.OCP.f,'char') && ~isa(solver.OCP.C,'char')
    switch method
        case 'GaussNewton'
            solver.HessianApproximation = 'GaussNewton';
        case 'GaussNewtonLC'
            solver.HessianApproximation = 'GaussNewtonLC';
        case 'GaussNewtonLF'
            solver.HessianApproximation = 'GaussNewtonLF';
        case 'Newton'
            solver.HessianApproximation = 'Newton';
        otherwise
            solver.HessianApproximation = 'GaussNewton';
    end
else
    switch method
        case 'GaussNewton'
            solver.HessianApproximation = 'GaussNewton';
        case 'GaussNewtonLC'
            if ~isa(solver.OCP.C,'char')
                solver.HessianApproximation = 'GaussNewtonLC';
            else
                solver.HessianApproximation = 'GaussNewton';
            end
        case 'GaussNewtonLF'
            if ~isa(solver.OCP.f,'char')
                solver.HessianApproximation = 'GaussNewtonLF';
            else
                solver.HessianApproximation = 'GaussNewton';
            end
        otherwise
            solver.HessianApproximation = 'GaussNewton';
    end
end

global ParNMPCGlobalVariable
ParNMPCGlobalVariable.HessianApproximation      = solver.HessianApproximation;

end