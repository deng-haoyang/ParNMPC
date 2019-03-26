 function  options = NMPCSolveOptions
    options.MaxIterNumInit          = 10;
    options.barrierParaInit         = 1e-1;
    options.TolInit                 = 5e-3;
    
    options.barrierParaDescentRate  = 0.5;

    options.MaxIterNumTotal         = 20;
    options.barrierParaEnd          = 1e-3;
    options.TolEnd                  = 5e-3;
end