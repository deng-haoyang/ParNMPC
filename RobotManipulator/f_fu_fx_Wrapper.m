function [f,fu,fx] = f_fu_fx_Wrapper(u,x,p,parIdx)

% dx = f(u,x,p)
    coder.cinclude('iiwa14.h');
    [xDim,~] = size(x);
    [uDim,~] = size(u);
    f = f_Wrapper(u,x,p,parIdx);
    fu = zeros(xDim,uDim);
    fx = zeros(xDim,xDim);
    
    q = x(1:7,1);
    qd = x(8:end,1);
    tau = u(1:7,1);
    
    dq  = zeros(7,7);
    dqd = zeros(7,7);
    dtau= zeros(7,7);
    
    coder.ceval('derivatives_cal', ...
                coder.ref(q),...
                coder.ref(qd),...
                coder.ref(tau),...
                coder.ref(dq),...
                coder.ref(dqd),...
                coder.ref(dtau),...
                parIdx);
    fu(8:end,1:7) = dtau;
    fx = [zeros(7,7),eye(7);dq,dqd];
end