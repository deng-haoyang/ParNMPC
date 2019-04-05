function setG(OCP,G)
    % assert
    Gux = jacobian(G,[OCP.u;OCP.x]);
    hasUX = has(Gux(:),[OCP.u;OCP.x]);
    if sum(hasUX(:)) ~= 0
        error('G must be a linear function of u and x!');
    end
    
    OCP.G = symfun(G,[OCP.u;OCP.x;OCP.p]);
    % Global variable
    global ParNMPCGlobalVariable
    G_formula = formula(OCP.G);
    [zDim,~] = size(G_formula);
    ParNMPCGlobalVariable.dim.z = zDim;
    ParNMPCGlobalVariable.solutionInitGuess.z = zeros(zDim,ParNMPCGlobalVariable.N);
    OCP.dim.z      = zDim;
    OCP.z          = sym('z',[OCP.dim.z,1]);
    OCP.LBarrier   = sym(0);
    %% barrier term
    for i = 1:zDim
        OCP.LBarrier = OCP.LBarrier - log(G_formula(i));
    end
    %% linear damping term
    for i = 1:zDim
        OCP.LBarrier = OCP.LBarrier + 1e-4*G_formula(i);
    end
end