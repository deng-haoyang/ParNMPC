function [solutionInit,solutionEnd,output] = ...
            NMPC_Solve(x0,pSplit,solutionInitialGuess,NMPCSolveOptions)

    lambdaSplit  = solutionInitialGuess.lambdaSplit;
    muSplit      = solutionInitialGuess.muSplit;
    uSplit       = solutionInitialGuess.uSplit;
    xSplit       = solutionInitialGuess.xSplit;
    LAMBDASplit  = solutionInitialGuess.LAMBDASplit;
    
    MaxIterNumInit         = NMPCSolveOptions.MaxIterNumInit;
    barrierParaInit        = NMPCSolveOptions.barrierParaInit;
    TolInit                = NMPCSolveOptions.TolInit;
    barrierParaDescentRate = NMPCSolveOptions.barrierParaDescentRate;
    MaxIterNumTotal        = NMPCSolveOptions.MaxIterNumTotal;
    barrierParaEnd         = NMPCSolveOptions.barrierParaEnd;
    TolEnd                 = NMPCSolveOptions.TolEnd;
    
    output.timeElapsed = 0;
    barrierPara        = barrierParaInit;
    mode               = 1;

    for iter=1:MaxIterNumTotal
        [lambdaSplit,...
         muSplit,...
         uSplit,...
         xSplit,...
         LAMBDASplit,...
         cost,...
         error,...
         timeElapsed] = NMPC_Iter(x0,...
                                  lambdaSplit,...
                                  muSplit,...
                                  uSplit,...
                                  xSplit,...
                                  pSplit,...
                                  LAMBDASplit,...
                                  barrierPara);
        switch mode
            case 1
                if (error<TolInit) || (iter >= MaxIterNumInit)
                    mode = 2;
                    solutionInit.lambdaSplit = lambdaSplit;
                    solutionInit.muSplit     = muSplit;
                    solutionInit.uSplit      = uSplit;
                    solutionInit.xSplit      = xSplit;
                    solutionInit.LAMBDASplit = LAMBDASplit;
                    
                    output.iterInit          = iter;
                    output.errorInit         = error;
                    output.costInit          = cost;
                    
                    if barrierParaInit == barrierParaEnd
                        break;
                    end
                end
            case 2
                barrierPara = barrierPara * barrierParaDescentRate;
                barrierPara(barrierPara<barrierParaEnd) = barrierParaEnd;
                if (error<TolEnd) && (barrierPara == barrierParaEnd)
                    break;
                end
        end
    end
    solutionEnd.lambdaSplit = lambdaSplit;
    solutionEnd.muSplit     = muSplit;
    solutionEnd.uSplit      = uSplit; 
    solutionEnd.xSplit      = xSplit;
    solutionEnd.LAMBDASplit = LAMBDASplit;
    output.costEnd        = cost;
    output.errorEnd       = error;
    output.timeElapsed = output.timeElapsed + timeElapsed;
    output.barrierPara = barrierPara;
    output.iterTotal   = iter;
    
end

