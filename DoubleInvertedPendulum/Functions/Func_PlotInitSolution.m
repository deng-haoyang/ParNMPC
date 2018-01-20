for i=1:xDim
    subplot(4,xDim,i);
    plot(initSolution(i:subDim:end));
    ylabel('lambda');
end
for i=1:muDim
    subplot(4,xDim,i+xDim);
    plot(initSolution(xDim+i:subDim:end));
    ylabel('mu');
end
for i=1:uDim
    subplot(4,xDim,i+xDim+xDim);
    plot(initSolution(xDim+muDim+i:subDim:end));
    ylabel('u');
end
for i=1:xDim
    subplot(4,xDim,i+xDim+xDim+xDim);
    plot(initSolution(xDim+muDim+uDim+i:subDim:end));
    ylabel('x');
end
