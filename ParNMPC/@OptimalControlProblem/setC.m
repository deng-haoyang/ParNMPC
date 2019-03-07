function setC(OCP,C)
    global ParNMPCGlobalVariable
	OCP.C = symfun(C,[OCP.u;OCP.x;OCP.p]);
    C_formula = formula(OCP.C);
    [muDim,~] = size(C_formula);
    OCP.dim.mu = muDim;
    OCP.mu     = sym('mu',[OCP.dim.mu,1]);
    ParNMPCGlobalVariable.dim.mu = muDim;
    ParNMPCGlobalVariable.solutionInitGuess.mu = zeros(muDim,ParNMPCGlobalVariable.N);
end