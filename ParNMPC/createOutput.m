function output = createOutput
    output.iterInit    = 0;
    output.cost        = 0;
    output.KKTError       = 0;
    output.timeElapsed.searchDirection = 0;
    output.timeElapsed.lineSearch = 0;
    output.timeElapsed.KKTErrorCheck = 0;
    output.timeElapsed.total = 0;
    output.rho         = 0;
    output.iterTotal     = 0;
    output.exitflag    = 0;
end


