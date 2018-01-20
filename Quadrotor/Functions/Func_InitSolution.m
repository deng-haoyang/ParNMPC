initSolution = zeros(subDim*N,1);
switch initMethod
    case INIT_BY_INPUT
        disp('Initialized from input data......');
        for i =1:N
            initSolution((i-1)*subDim+1:i*subDim)  = ...
                [lambdaInitGuess((i-1)*lambdaDim+1:i*lambdaDim);...
                 muInitGuess((i-1)*muDim+1:i*muDim);...
                 uInitGuess((i-1)*uDim+1:i*uDim);...
                 xInitGuess((i-1)*xDim+1:i*xDim)];
        end
    case INIT_BY_REF_GUESS
        disp('Initialized by guess!');
        solutionStartValueGuess = [lambdaStartValueGuess;...
                                   muStartValueGuess;...
                                   uStartValueGuess;...
                                   xStartValueGuess];
        solutionFinalValueGuess = [lambdaFinalValueGuess;...
                                   muFinalValueGuess;...
                                   uFinalValueGuess;...
                                   xFinalValueGuess];
        solutionInterp = zeros(subDim,N);
        for i = 1:subDim
            if N == 1
                solutionInterp(i,:) = solutionStartValueGuess(i);
            else
                interp_step = 1/(N-1);
                solutionInterp(i,:) = ...
                    interp1([solutionStartValueGuess(i),solutionFinalValueGuess(i)],...
                            1:interp_step:2,'pchip');
            end
        end
        for i = 1:N
            initSolution((i-1)*subDim+1:i*subDim) = solutionInterp(:,i);
        end
    case INIT_BY_FILE
        try
            load('../initialSolution.mat');
            % Interpolation
            initSolution_interp = zeros(N*subDim,1);
            if N == 1
                initSolution_interp = initSolution(1:subDim,1);
            else
                for i=1:subDim
                    data_orig = initSolution(i:subDim:end);
                    [size_o,~] = size(data_orig);
                    interp_step = (size_o-1)/(N-1);
                    interp_point = 1:interp_step:size_o;
                    data_interp = interp1(data_orig,interp_point,'pchip');
                    initSolution_interp(i:subDim:end) = data_interp.';
                end
            end
            disp('Initialized from file......');
            initSolution = initSolution_interp;
        catch
            error('Initialize from initialSolution.mat failed, please try another initialization method!');
        end
end
