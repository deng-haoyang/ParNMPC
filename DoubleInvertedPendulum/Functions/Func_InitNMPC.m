% Define Structures
wholeDim         = subDim*N;
xPrevVal         = zeros(xDim,N);
lambdaNextVal    = zeros(lambdaDim,N);
xDiff            = zeros(xDim,N);
lambdaDiff       = zeros(lambdaDim,N);
theta            = zeros(xDim,xDim,N);
jacoLambdaInv    = zeros(subDim,subDim,N);
jaco             = zeros(subDim,subDim,N);
currentIteration = zeros(subDim,N);
currentEval      = zeros(subDim,N);
% init ith iteration
for i=1:N
    currentIteration(:,i) = initSolution((i-1)*subDim+1:i*subDim);
end
% init coupled variables
for i=1:N
    % backward lambda init
    if i < N
        lambdaNextVal(:,i) = currentIteration(1:lambdaDim,i+1);
    end
    % forward state init
    if i == 1
        xPrevVal(:,i) = x0Value;
    else
        xPrevVal(:,i) = currentIteration(end-xDim+1:end,i-1);
    end
end

for i=1:N
    if isHxxExplicit
        jaco(:,:,i) = ...
            GEN_Func_dKKT(currentIteration(:,i),pVal(:,i));
    else
        jaco(:,:,i) = ...
            Func_dKKT_FD(currentIteration(:,i),pVal(:,i),xDim,subDim,FDStep);
    end
end
% init theta
for i=N:-1:1
    jacoLambdaInv(:,:,i)  = inv(jaco(:,:,i));
    theta_1 = jacoLambdaInv(1:lambdaDim,1:lambdaDim,i);
    if i>1
        theta(:,:,i-1) = theta_1;
        jaco(end - xDim+1:end, end - xDim+1:end,i-1) = ...
            jaco(end - xDim+1:end, end - xDim+1:end,i-1) - ...
            theta_1;
    end
end
