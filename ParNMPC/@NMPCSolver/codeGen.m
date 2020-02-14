function codeGen(solver)
unknowns = [solver.OCP.lambda;...
            solver.OCP.mu;...
            solver.OCP.u;...
            solver.OCP.x;...
            solver.OCP.p];
        
        
if solver.OCP.dim.x + solver.OCP.dim.u < solver.OCP.THRESHOLD_DIM_UX
    isOptimize = true;
else
    isOptimize = false;
end
% LAll = solver.OCP.L + rho*solver.OCP.LBarrier.all;
L = solver.OCP.L;

if  solver.OCP.isMEnabled == false
    switch solver.HessianApproximation
        case 'GaussNewton'
            A_ = L;
        case 'GaussNewtonLC'
            A_ = L + solver.OCP.mu.'*solver.OCP.C;
        case 'GaussNewtonLF'
            F = solver.OCP.f * solver.OCP.deltaTau - solver.OCP.x;
            A_ = L + solver.OCP.lambda.'*F;
        case 'Newton'
            F = solver.OCP.f * solver.OCP.deltaTau - solver.OCP.x;
            A_ = L + solver.OCP.mu.'*solver.OCP.C + solver.OCP.lambda.'*F;
        otherwise
            A_ = L;
    end
else
    switch solver.HessianApproximation
        case 'GaussNewton'
            A_ = L;
        case 'GaussNewtonLC'
            A_ = L + solver.OCP.mu.'*solver.OCP.C;
        otherwise
            A_ = L;
    end
end
showInfo(solver);
%% Generate Hessian for NMPC
disp('Generating Hessian...')
A = A_;
Au  = jacobian(A,solver.OCP.u);
Ax  = jacobian(A,solver.OCP.x);

Auu = jacobian(Au,solver.OCP.u);
Aux = jacobian(Au,solver.OCP.x);
Axx = jacobian(Ax,solver.OCP.x);
% Condensing of z
if solver.OCP.dim.z ~= 0
    Gu = jacobian(solver.OCP.G,solver.OCP.u);
    Gx = jacobian(solver.OCP.G,solver.OCP.x);
    G  = solver.OCP.G;
    AuuCondensed = formula(Auu) + formula(Gu.'*diag(solver.OCP.z./G)*Gu);%
    AuxCondensed = formula(Aux) + formula(Gu.'*diag(solver.OCP.z./G)*Gx);%
    AxxCondensed = formula(Axx) + formula(Gx.'*diag(solver.OCP.z./G)*Gx);%
else
    AuuCondensed = formula(Auu);%
    AuxCondensed = formula(Aux);%
    AxxCondensed = formula(Axx);%
end
LambdaMuUXZP = {solver.OCP.lambda;...
               solver.OCP.mu;...
               solver.OCP.u;...
               solver.OCP.x;...
               solver.OCP.z;...
               solver.OCP.p};

matlabFunction(AuuCondensed,AuxCondensed,AxxCondensed,...
    'File','./funcgen/OCP_GEN_Auu_Aux_Axx_Condensed',...
    'Vars',LambdaMuUXZP,...
    'Outputs',{'AuuCondensed','AuxCondensed','AxxCondensed'},'Optimize',isOptimize);
disp('Done!');
end