function setHessianApproximation(solver,method)

if solver.OCP.isMEnabled == false
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
disp(['Hessian approximation method: ' solver.HessianApproximation]);
end