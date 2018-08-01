function codeGen(solver)
unknowns = [solver.OCP.lambda;...
            solver.OCP.mu;...
            solver.OCP.u;...
            solver.OCP.x;...
            solver.OCP.p];
        
LAll = solver.OCP.L + solver.OCP.LBarrier.all;

if strcmp(solver.OCP.discretizationMethod,'Euler') && solver.OCP.isMEnabled == false
    switch solver.HessianApproximation
        case 'GaussNewton'
            A_ = LAll;
        case 'GaussNewtonLC'
            A_ = LAll + solver.OCP.mu.'*solver.OCP.C;
        case 'Newton'
            F = solver.OCP.f * solver.OCP.deltaTau - solver.OCP.x;
            A_ = LAll + solver.OCP.mu.'*solver.OCP.C + solver.OCP.lambda.'*F;
        otherwise
            A_ = LAll;
    end
else
    switch solver.HessianApproximation
        case 'GaussNewton'
            A_ = LAll;
        case 'GaussNewtonLC'
            A_ = LAll + solver.OCP.mu.'*solver.OCP.C;
        otherwise
            A_ = LAll;
    end
end
%% Generate Hessian for NMPC
A = symfun(A_,unknowns);
Au  = jacobian(A,solver.OCP.u);
Ax  = jacobian(A,solver.OCP.x);

Auu = jacobian(Au,solver.OCP.u);
Aux = jacobian(Au,solver.OCP.x);
Axx = jacobian(Ax,solver.OCP.x);
LambdaMuUXP = {solver.OCP.lambda;...
               solver.OCP.mu;...
               solver.OCP.u;...
               solver.OCP.x;...
               solver.OCP.p};
matlabFunction(Auu,...
    'File','./funcgen/OCP_GEN_Auu',...
    'Vars',LambdaMuUXP,...
        'Outputs',{'Auu'});

matlabFunction(Aux,...
    'File','./funcgen/OCP_GEN_Aux',...
    'Vars',LambdaMuUXP,...
        'Outputs',{'Aux'});

matlabFunction(Axx,...
    'File','./funcgen/OCP_GEN_Axx',...
    'Vars',LambdaMuUXP,...
        'Outputs',{'Axx'});
end