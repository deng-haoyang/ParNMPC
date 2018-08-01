function setG(OCP,G)
    global GMax GMin
    OCP.G = symfun(G,[OCP.u;OCP.x;OCP.p]);
    
    G_formula = formula(OCP.G);
    [GDim,unused] = size(G_formula);
    [GMaxDim,unused] = size(OCP.GMax.value);
    [GMinDim,unused] = size(OCP.GMin.value);
    
    OCP.LBarrier.GMax = sym(0);
    OCP.LBarrier.GMin = sym(0);
    
    if GMaxDim == GDim 
        for i = 1:GDim
            % GMax
            if ~isinf(OCP.GMax.value(i))
                OCP.LBarrier.GMax = OCP.LBarrier.GMax - ...
                    OCP.GMax.barrierParameter(i)*log(OCP.GMax.value(i)-G_formula(i));
            end
        end
    end
    if GMinDim == GDim
        for i = 1:GDim
            % GMin
            if ~isinf(OCP.GMin.value(i))
                OCP.LBarrier.GMin = OCP.LBarrier.GMin - ...
                    OCP.GMin.barrierParameter(i)*log(G_formula(i)-OCP.GMin.value(i));
            end
        end
    end
    % update the sum of the barrier function
    OCP.LBarrier.all =   OCP.LBarrier.uMax + OCP.LBarrier.uMin ...
                       + OCP.LBarrier.xMax + OCP.LBarrier.xMin ...
                       + OCP.LBarrier.GMax + OCP.LBarrier.GMin;
    % init GMax GMin if they have not been initialized
    [GMaxDim,unused] = size(OCP.GMax.value);
    [GMinDim,unused] = size(OCP.GMin.value);
    if GMaxDim == 0
        OCP.GMax.value = ones(GDim,1)*OCP.veryBigNum;
        GMax = OCP.GMax.value;
    end
    if GMinDim == 0
        OCP.GMin.value = -ones(GDim,1)*OCP.veryBigNum;
        GMin = OCP.GMin.value;
    end
end