function solverMode = getSolverMode(solver)
    solver.solverMode = uint32(0);
    
    % discretizationMethod
    switch solver.OCP.discretizationMethod
        case 'Euler'
            solver.solverMode = bitset(solver.solverMode, 1,0);
            solver.solverMode = bitset(solver.solverMode, 2,0);
            solver.solverMode = bitset(solver.solverMode, 3,0);
        case 'RK4'
            solver.solverMode = bitset(solver.solverMode, 1,1);
            solver.solverMode = bitset(solver.solverMode, 2,0);
            solver.solverMode = bitset(solver.solverMode, 3,0);
        otherwise % default: Euler
            solver.solverMode = bitset(solver.solverMode, 1,0);
            solver.solverMode = bitset(solver.solverMode, 2,0);
            solver.solverMode = bitset(solver.solverMode, 3,0);
    end
    
    % HessianApproximation
    switch solver.HessianApproximation
        case 'GaussNewton'
            solver.solverMode = bitset(solver.solverMode, 4,0);
            solver.solverMode = bitset(solver.solverMode, 5,0);
            solver.solverMode = bitset(solver.solverMode, 6,0);
        case 'GaussNewtonLC'
            solver.solverMode = bitset(solver.solverMode, 4,1);
            solver.solverMode = bitset(solver.solverMode, 5,0);
            solver.solverMode = bitset(solver.solverMode, 6,0);
        case 'Newton'
            solver.solverMode = bitset(solver.solverMode, 4,0);
            solver.solverMode = bitset(solver.solverMode, 5,1);
            solver.solverMode = bitset(solver.solverMode, 6,0);
        otherwise % default: GaussNewton
            solver.solverMode = bitset(solver.solverMode, 4,0);
            solver.solverMode = bitset(solver.solverMode, 5,0);
            solver.solverMode = bitset(solver.solverMode, 6,0);
    end
    % isMEnabled
    if solver.OCP.isMEnabled
        solver.solverMode = bitset(solver.solverMode, 7,1);
    else
        solver.solverMode = bitset(solver.solverMode, 7,0);
    end
    solverMode = solver.solverMode;
end