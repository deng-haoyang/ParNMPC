function setHessianApproximation(solver,method)
% state 0: ok
% state 1: HessianApproximation was forced to GaussNewton due to
% high order discretization methods
% state 2: Not HessianApproximation method selected
if strcmp(solver.OCP.discretizationMethod,'Euler') && solver.OCP.isMEnabled == false
    switch method
        case 'GaussNewton'
            solver.HessianApproximation = 'GaussNewton';
        case 'GaussNewtonLC'
            solver.HessianApproximation = 'GaussNewtonLC';
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
            solver.HessianApproximation = 'GaussNewtonLC';
        otherwise
            solver.HessianApproximation = 'GaussNewton';
    end
end
end