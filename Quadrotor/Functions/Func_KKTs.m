function F = Func_KKTs(x) 
global x0Value xDim N pVal subDim
if N == 1
    F = GEN_Func_KKT(x,...
        x0Value,...
        zeros(xDim,1),...
        pVal(:,1));
else
    for i=1:N
        x_i = x((i-1)*subDim+1:i*subDim);
        if i == 1
            xPrev = x0Value;
            lambdaNext = x(i*subDim+1:i*subDim+xDim);
        elseif i == N
            xPrev = x((i-1)*subDim-xDim+1:(i-1)*subDim);
            lambdaNext = zeros(xDim,1);
        else
            xPrev = x((i-1)*subDim-xDim+1:(i-1)*subDim);
            lambdaNext = x(i*subDim+1:i*subDim+xDim);
        end
        F((i-1)*subDim+1:i*subDim) = GEN_Func_KKT(x_i,...
                                                  xPrev,...
                                                  lambdaNext,...
                                                  pVal(:,i));
    end
end
