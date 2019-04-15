function [lambdaSplit,muSplit,uSplit,xSplit,filter,stepSize,timeElapsed] = ...
    NMPC_LineSearch_Filter(x0,pSplit,rho,...
                          lambdaSplit_k,muSplit_k,uSplit_k,xSplit_k,...
                          lambdaSplit,muSplit,uSplit,xSplit,filter)

    timerStart = Timer();
    
    % Global variables
    global ParNMPCGlobalVariable
    xDim             = ParNMPCGlobalVariable.dim.x;
    [~,sizeSeg,DoP]  = size(xSplit);
    filterWidth = size(filter,2);
    % Local 
    
    % Init 
    stepSize            = 1;
    stepSizeDecayRate   = 0.75;
    stepSizeMin         = 5e-2;
    isAccept            = false;
    beta                = 5e-3;
    % Coupling variable for each segment
    xPrev           = zeros(xDim,sizeSeg,DoP);
    xPrev(:,1,1)    = x0;
    %%
    if norm(xSplit(:)-xSplit_k(:),1)<1e-7
        stepSize = 1;
    else
        %% search a step size 
        while stepSize>stepSizeMin
            % stepSize
            u_stepSize = (1-stepSize)*uSplit_k + stepSize*uSplit;
            x_stepSize = (1-stepSize)*xSplit_k + stepSize*xSplit;
            for i=2:1:DoP
                xPrev(:,1,i) = (1-stepSize)*xSplit_k(:,sizeSeg,i-1) + stepSize*xSplit(:,sizeSeg,i-1);
            end
            [l1Norm_LALL,l1Norm_xEq,l1Norm_C] = NMPC_LineSearch_Filter_PairEval(xPrev,rho,u_stepSize,x_stepSize,pSplit);
            for i = 1:filterWidth
                if filter(3,i) == 1 % compare the pair that is in the filter
                    if l1Norm_LALL<filter(1,i) || l1Norm_xEq + l1Norm_C < filter(2,i) 
                        isAccept = true;
                    else
                        isAccept = false;
                    end
                end
            end
            % add when initialized
            if sum(filter(3,:)) == 0
                isAccept = true;
            end
            if isAccept
                % remove all dominated pairs
                for i = 1:filterWidth
                    if (1-beta)*l1Norm_LALL - beta*(l1Norm_xEq + l1Norm_C)<filter(1,i) &&...
                            (1-beta)*(l1Norm_xEq + l1Norm_C) <filter(2,i)
                        filter(3,i) = 0;
                    end
                end
                % add pair
                for i = 1:filterWidth
                    if filter(3,i) == 0
                        filter(1,i) = (1-beta)*l1Norm_LALL - beta*(l1Norm_xEq + l1Norm_C);
                        filter(2,i) = (1-beta)*(l1Norm_xEq + l1Norm_C);
                        filter(3,i) = 1;
                        break;
                    end
                end
            end
                
            if isAccept
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