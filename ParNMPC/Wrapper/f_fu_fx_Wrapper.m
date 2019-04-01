function [f,fu,fx] = f_fu_fx_Wrapper(u,x,p)
% fu and fx are calculated using forward difference by default

% dx = f(u,x,p)
    [xDim,~] = size(x);
    [uDim,~] = size(u);
    f = f_Wrapper(u,x,p);
    fu = zeros(xDim,uDim);
    fx = zeros(xDim,xDim);
    h  = 1e-8;
    % fu
    for i=1:uDim
         ei = zeros(uDim,1);
         ei(i,1) = 1;
         fu(:,i) = (f_Wrapper(u+ei*h,x,p) - f)/h;
    end
    % fx
    for i=1:xDim
         ei = zeros(xDim,1);
         ei(i,1) = 1;
         fx(:,i) = (f_Wrapper(u,x+ei*h,p) - f)/h;
    end
end