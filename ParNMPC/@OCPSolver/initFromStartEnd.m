function [lambda,mu,u,x] =...
    initFromStartEnd(solver,lambdaStart,muStart,uStart,xStart,...
                            lambdaEnd,  muEnd,  uEnd,  xEnd)
    lambdaDim = solver.OCP.dim.lambda;
    muDim     = solver.OCP.dim.mu;
    uDim      = solver.OCP.dim.u;
    xDim      = solver.OCP.dim.x;
    N         = solver.OCP.N;
    subDim    = solver.OCP.dim.subDim;
    
    XStart = [lambdaStart;...
               muStart;...
               uStart;...
               xStart];
    XEnd = [lambdaEnd;...
               muEnd;...
               uEnd;...
               xEnd];
    XInterp = zeros(subDim,N);
        for i = 1:subDim
            if N == 1
                XInterp(i,:) = XStart(i);
            else
                interpStep = 1/(N-1);
                XInterp(i,:) = ...
                    interp1([XStart(i),XEnd(i)],1:interpStep:2,'pchip');
            end
        end
    XSplit = reshape(XInterp,subDim,N);
    lambda = XSplit(1:lambdaDim,:);
    mu     = XSplit(lambdaDim+1:lambdaDim+muDim,:);
    u      = XSplit(lambdaDim+muDim+1:lambdaDim+muDim+uDim,:);
    x      = XSplit(lambdaDim+muDim+uDim+1:end,:);
end
