function showInfo(solver)
    disp(' ');
    disp('--------------------------NMPCSolver Information-------------------------');
    disp(['Hessian approximation method: ',solver.HessianApproximation]);
    if solver.nonsingularRegularization == 1e-9
        disp(['Nonsingular regularization parameter: ','1e-9 (default)']);
    else
        disp(['Nonsingular regularization parameter: ',num2str(solver.nonsingularRegularization)]);
    end
    if solver.descentRegularization == 0
        disp(['Descent regularization parameter: ','0 (default)']);
    else
        disp(['Descent regularization parameter: ',num2str(solver.descentRegularization)]);
    end
    if solver.isApproximateInvFx
        disp('inv(Fx) is approximated by inv(Fx) = -Fx-2I ');
    else
        disp('inv(Fx) is calculated exactly (default)');
    end
    disp('-------------------------------------------------------------------------');
end