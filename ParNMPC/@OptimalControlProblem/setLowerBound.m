function setLowerBound(OCP,field,boundValue,barrierParameter)
    global xMin uMin GMin
    boundValue(boundValue<-OCP.veryBigNum) = -OCP.veryBigNum;
    switch field
        case 'x'
            OCP.xMin.value = boundValue;
            OCP.xMin.barrierParameter = barrierParameter;
            xMin = OCP.xMin.value;
            
            OCP.LBarrier.xMin = sym(0);
            for i = 1:OCP.dim.x
                % xMin
                if OCP.xMin.value(i) ~= -OCP.veryBigNum
                    OCP.LBarrier.xMin =  OCP.LBarrier.xMin - ...
                        OCP.xMin.barrierParameter(i)*log(OCP.x(i)-OCP.xMin.value(i));
                end
            end
            
        case 'u'
            OCP.uMin.value = boundValue;
            OCP.uMin.barrierParameter = barrierParameter;
            uMin = OCP.uMin.value;
            
            OCP.LBarrier.uMin = sym(0);
            for i = 1:OCP.dim.u
                if OCP.uMin.value(i) ~= -OCP.veryBigNum
                    OCP.LBarrier.uMin = OCP.LBarrier.uMin - ...
                        OCP.uMin.barrierParameter(i)*log(OCP.u(i)-OCP.uMin.value(i));
                end
            end
            
        case 'G'
            OCP.GMin.value = boundValue;
            OCP.GMin.barrierParameter = barrierParameter;
            GMin = OCP.GMin.value;
            % barrier function
            G_formula = formula(OCP.G);
            [GDim,unused] = size(G_formula);
            [GMinDim,unused] = size(OCP.GMin.value);
            OCP.LBarrier.GMin = sym(0);
            if GMinDim == GDim
                for i = 1:GDim
                    % GMin
                    if OCP.GMin.value(i) ~= -OCP.veryBigNum
                        OCP.LBarrier.GMin = OCP.LBarrier.GMin - ...
                            OCP.GMin.barrierParameter(i)*log(G_formula(i)-OCP.GMin.value(i));
                    end
                end
            end
            
        otherwise
            error('The first parameter can only be ''x'', ''u'', or ''G''! ');
    end
    % update the sum of the barrier function
    OCP.LBarrier.all =   OCP.LBarrier.uMax + OCP.LBarrier.uMin ...
                   + OCP.LBarrier.xMax + OCP.LBarrier.xMin ...
                   + OCP.LBarrier.GMax + OCP.LBarrier.GMin;
end