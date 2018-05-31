function KKTs = OCP_KKTs(X) %#codegen
global x0Global pValGlobal...
       dimGlobal isMEnabledGlobal discretizationMethodGlobal NGlobal

lambdaDim = dimGlobal.lambda;
muDim     = dimGlobal.mu;
uDim      = dimGlobal.u;
xDim      = dimGlobal.x;
subDim    = dimGlobal.subDim;
pDim      = dimGlobal.p;
N         = NGlobal;
discretizationMethod = discretizationMethodGlobal;
isMEnabled = isMEnabledGlobal;

pVal      = pValGlobal;




XSplit = reshape(X,subDim,N);
lambda = XSplit(1:lambdaDim,:);
mu     = XSplit(lambdaDim+1:lambdaDim+muDim,:);
u      = XSplit(lambdaDim+muDim+1:lambdaDim+muDim+uDim,:);
x      = XSplit(lambdaDim+muDim+uDim+1:end,:);
    
lambdaNext    = zeros(lambdaDim,N);
xPrev         = zeros(xDim,N);

xPrev(:,1)    = x0Global;
for i=2:1:N
    xPrev(:,i) = x(:,i-1);
    lambdaNext(:,i-1) = lambda(:,i);
end
KKTsMatrix = zeros(subDim,N);
if coder.target('MATLAB')% Normal excution
    numThreads = 0;
else % Code generation
    numThreads = N;
end
parfor (i=1:1:N,numThreads)
    lambda_i = lambda(:,i);
    mu_i = mu(:,i);
    u_i = u(:,i);
    x_i = x(:,i);
    p_i = pVal(:,i);
    xPrev_i = xPrev(:,i);
    lambdaNext_i = lambdaNext(:,i);
    
    [L_i,Lu_i,Lx_i] = OCP_L_Lu_Lx(u_i,x_i,p_i);
    [C_i,Cu_i,Cx_i] = OCP_C_Cu_Cx(u_i,x_i,p_i);
    [F_i,Fu_i,Fx_i] = F_Fu_Fx(u_i,x_i,p_i,...
                              discretizationMethod,...
                              isMEnabled);
    xEq_i      = F_i + xPrev_i;
    
    HuT_i      = Lu_i.' + Fu_i.'*lambda_i;
    lambdaEq_i = lambdaNext_i + ...
                 Lx_i.' + Fx_i.'*lambda_i;
    if muDim ~= 0
        HuT_i      = HuT_i + Cu_i.'*mu_i;
        lambdaEq_i = lambdaEq_i + Cx_i.'*mu_i;
    end
    KKTsMatrix(:,i) = [xEq_i;...
                       C_i;...
                       HuT_i;...
                       lambdaEq_i];
end
KKTs = KKTsMatrix(:);
