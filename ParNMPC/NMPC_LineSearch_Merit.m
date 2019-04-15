function [lambdaSplit,muSplit,uSplit,xSplit,stepSize,timeElapsed] = ...
    NMPC_LineSearch_Merit(x0,pSplit,rho,...
                          lambdaSplit_k,muSplit_k,uSplit_k,xSplit_k,...
                          lambdaSplit,muSplit,uSplit,xSplit,phiX,phiC)

    timerStart = Timer();
    
    % Global variables
    global ParNMPCGlobalVariable
    xDim             = ParNMPCGlobalVariable.dim.x;
    [~,sizeSeg,DoP]  = size(xSplit);
    % Local 
    
    % Init 
    stepSize            = 1;
    epsilon             = 1e-7; % directional directive
    stepSizeDecayRate   = 0.75;
    stepSizeMin         = 5e-2;
    eta                 = 0.1; 
    
    % Coupling variable for each segment
    xPrev           = zeros(xDim,sizeSeg,DoP);
    xPrev(:,1,1)    = x0;
    %%
    if norm(xSplit(:)-xSplit_k(:),1)<1e-7
        stepSize = 1;
    else
        %% 0
        for i=2:1:DoP
            xPrev(:,1,i) = xSplit_k(:,sizeSeg,i-1);
        end
        merit_0 = NMPC_LineSearch_Merit_MeritEval(xPrev,rho,uSplit_k,xSplit_k,pSplit,phiX,phiC);
        %% epsilon
        for i=2:1:DoP
            xPrev(:,1,i) = (1-epsilon)*xSplit_k(:,sizeSeg,i-1) + epsilon*xSplit(:,sizeSeg,i-1);
        end
        u_epsilon = (1-epsilon)*uSplit_k + epsilon*uSplit;
        x_epsilon = (1-epsilon)*xSplit_k + epsilon*xSplit;
        merit_epsilon = NMPC_LineSearch_Merit_MeritEval(xPrev,rho,u_epsilon,x_epsilon,pSplit,phiX,phiC);
        %% directional directive of the merit function 
        DDmerit = (merit_epsilon - merit_0)/epsilon;
        %% search a step size  
        while stepSize>stepSizeMin
            % stepSize
            u_stepSize = (1-stepSize)*uSplit_k + stepSize*uSplit;
            x_stepSize = (1-stepSize)*xSplit_k + stepSize*xSplit;
            for i=2:1:DoP
                xPrev(:,1,i) = (1-stepSize)*xSplit_k(:,sizeSeg,i-1) + stepSize*xSplit(:,sizeSeg,i-1);
            end
            merit_stepSize = NMPC_LineSearch_Merit_MeritEval(xPrev,rho,u_stepSize,x_stepSize,pSplit,phiX,phiC);

            if merit_stepSize < merit_0 + eta*stepSize*DDmerit
                break;
            else
               stepSize  = stepSizeDecayRate*stepSize;
               stepSize(stepSize < stepSizeMin) = stepSizeMin;
            end
        end
    end
    %% 
    if stepSize ~= 1
        lambdaSplit = (1-stepSize)*lambdaSplit_k + stepSize* lambdaSplit;
        muSplit     = (1-stepSize)*muSplit_k     + stepSize* muSplit;
        uSplit      = (1-stepSize)*uSplit_k      + stepSize* uSplit;
        xSplit      = (1-stepSize)*xSplit_k      + stepSize* xSplit;
    end
    timerEnd = Timer();
    timeElapsed = timerEnd  - timerStart;
end