function [lambda,mu,u,x] = initFromMatFile(solver,matFile)
    lambdaDim = solver.OCP.dim.lambda;
    muDim     = solver.OCP.dim.mu;
    uDim      = solver.OCP.dim.u;
    xDim      = solver.OCP.dim.x;
    N         = solver.OCP.N;
    subDim    = solver.OCP.dim.subDim;
    
    try
        data = load(matFile);
        lambda = data.lambda;
        mu     = data.mu;
        u      = data.u;
        x      = data.x;
        
        XFileMatrix = [lambda;...
                       mu;...
                       u;...
                       x];
        XFile = XFileMatrix(:);
        
        % Interpolation
        XInterp = zeros(N*subDim,1);
        if N == 1
            XInterp = XFile(1:subDim,1);
        else
            for i=1:subDim
                dataOrig = XFile(i:subDim:end);
                [sizeOrig,~] = size(dataOrig);
                interpStep = (sizeOrig-1)/(N-1);
                interpPoint = 1:interpStep:sizeOrig;
                dataInterp = interp1(dataOrig,interpPoint,'pchip');
                XInterp(i:subDim:end) = dataInterp.';
            end
        end
        XSplit = reshape(XInterp,subDim,N);
        lambda = XSplit(1:lambdaDim,:);
        mu     = XSplit(lambdaDim+1:lambdaDim+muDim,:);
        u      = XSplit(lambdaDim+muDim+1:lambdaDim+muDim+uDim,:);
        x      = XSplit(lambdaDim+muDim+uDim+1:end,:);
    catch
        error('Error');
    end

end
