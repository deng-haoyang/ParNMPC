function [cieq,ceq] = fmincon_Eq(X)

global pValGlobal dimGlobal NGlobal x0Global 
uDim = dimGlobal.u;
muDim = dimGlobal.mu;
xDim = dimGlobal.x;
N    = NGlobal;
global ParNMPCGlobalVariable

discretizationMethod = ParNMPCGlobalVariable.discretizationMethod;
isMEnabled = ParNMPCGlobalVariable.isMEnabled;
ux_vec   = reshape(X,uDim+xDim,NGlobal);
u      = ux_vec(1:uDim,:);
x      = ux_vec(uDim+1:end,:);

xPrev         = zeros(xDim,N);
xPrev(:,1)    = x0Global;
for i=2:1:N
    xPrev(:,i) = x(:,i-1);
end

xEq = zeros(xDim,N);
C   = zeros(muDim,N);

for i = 1:N
    u_i = u(:,i);
    x_i = x(:,i);
    p_i = pValGlobal(:,i);
    xPrev_i = xPrev(:,i);
    
    F_i   = OCP_F(u_i,x_i,p_i,discretizationMethod,isMEnabled);
    xEq_i = F_i + xPrev_i;
    C_i   = OCP_C(u_i,x_i,p_i);
    
    xEq(:,i) = xEq_i;
    C(:,i)   = C_i;
end
cieq = [];     % Compute nonlinear inequalities at X.
ceq = [xEq(:);C(:)];   % Compute nonlinear equalities at x.
