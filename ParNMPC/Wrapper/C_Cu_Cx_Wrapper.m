function [C,Cu,Cx] = C_Cu_Cx_Wrapper(u,x,p,parIdx)
% Cu and Cx are calculated using finite difference by default

% parIdx: index of the core (for reentrant purpose)
    [xDim,~] = size(x);
    [uDim,~] = size(u);
    C = C_Wrapper(u,x,p,parIdx);
    [muDim,~] = size(C);
    Cu = zeros(muDim,uDim);
    Cx = zeros(muDim,xDim);
    h  = 1e-8;
    % Cu
    for i=1:uDim
         ei = zeros(uDim,1);
         ei(i,1) = 1;
         Cu(:,i) = (C_Wrapper(u+ei*h,x,p,parIdx) - C)/h;
    end
    % Cx
    for i=1:xDim
         ei = zeros(xDim,1);
         ei(i,1) = 1;
         Cx(:,i) = (C_Wrapper(u,x+ei*h,p,parIdx) - C)/h;
    end
end