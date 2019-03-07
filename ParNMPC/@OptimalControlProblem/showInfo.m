function showInfo(OCP)
    disp(' ');
    disp('--------------------OptimalControlProblem Information--------------------');
    disp([num2str(OCP.dim.u) ' inputs (u), ',num2str(OCP.dim.x),' states (x), ',num2str(OCP.dim.p) ' parameters (p)']);
    disp([num2str(OCP.dim.mu) ' equality constraints (C), ', num2str(OCP.dim.z) ' inequality constraints (G)']);
    
    T = sym(OCP.T);
    disp(['Prediction horizon (T): ',char(T) ]);
    disp(['Discretization grids (N): ',num2str(OCP.N)]);
    disp(['Discretization method: ',OCP.discretizationMethod]);
    if OCP.isMEnabled
        disp(['is M enabled: Yes']);
    else
        disp(['is M enabled: No']);
    end
    disp('-------------------------------------------------------------------------');
end