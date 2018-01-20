global subDim
lambdaDim  = xDim;
lambda     = sym('lambda',[lambdaDim,1]);
mu         = sym('mu',[muDim,1]);
u          = sym('u',[uDim,1]);
x          = sym('x',[xDim,1]);
p          = sym('p',[pDim,1]);
xPrev      = sym('xPrev',[xDim,1]);
lambdaNext = sym('lambdaNext',[lambdaDim,1]);
unknowns   = [lambda;mu;u;x];
uLocation  = lambdaDim+muDim+1:lambdaDim+muDim+uDim;
subDim     = uDim+xDim+muDim+lambdaDim;