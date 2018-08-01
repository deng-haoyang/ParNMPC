function L = fmincon_L(X)

global pValGlobal dimGlobal NGlobal 
uDim = dimGlobal.u;
xDim = dimGlobal.x;
N    = NGlobal;

ux_vec = reshape(X,uDim+xDim,NGlobal);
u      = ux_vec(1:uDim,:);
x      = ux_vec(uDim+1:end,:);

cost   = zeros(NGlobal,1);

for i = 1:NGlobal
    cost(i)  = OCP_GEN_L(u(:,i),x(:,i),pValGlobal(:,i));
                 + OCP_GEN_LBarrier(u(:,i),x(:,i),pValGlobal(:,i));
end

L = sum(cost(:));