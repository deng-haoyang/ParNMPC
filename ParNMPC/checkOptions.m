function checkOptions(options)
    if options.rhoInit<options.rhoEnd
        error('The end barrier parameter (rhoEnd) should be smaller than the initial barrier parameter (rhoInit)!');
    end
    if options.rhoEnd<=0
        error('The end barrier parameter (rhoEnd) should be positive!');
    end
    if options.maxIterInit>options.maxIterTotal
        error('Max number of iterations should be greater than that for the initial barrier parameter!');
    end
    if options.rhoDecayRate>=1 || options.rhoDecayRate<=0
        error('The barrier parameter decaying rate (rhoDecayRate) should be in (0,1)!');
    end
end