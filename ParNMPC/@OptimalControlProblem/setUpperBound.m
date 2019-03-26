function setUpperBound(OCP,field,boundValue,barrierParameter)
    % Global variable
    global ParNMPCGlobalVariable
    
    boundValue(boundValue>OCP.veryBigNum) = OCP.veryBigNum;
    
    switch field
        case 'x'
            OCP.xMax.value = boundValue;
            OCP.xMax.barrierParameter = barrierParameter;
            ParNMPCGlobalVariable.xMax = OCP.xMax.value;
            OCP.LBarrier.xMax = sym(0);
            for i = 1:OCP.dim.x
                % xMax
                if OCP.xMax.value(i) ~= OCP.veryBigNum
                    OCP.LBarrier.xMax = OCP.LBarrier.xMax - ...
                        OCP.barrierPara*OCP.xMax.barrierParameter(i)*log(OCP.xMax.value(i)-OCP.x(i));
                end
            end
            
        case 'u'
            OCP.uMax.value = boundValue;
            OCP.uMax.barrierParameter = barrierParameter;
            ParNMPCGlobalVariable.uMax = OCP.uMax.value;
            OCP.LBarrier.uMax = sym(0);
            for i = 1:OCP.dim.u
                % uMax
                if OCP.uMax.value(i) ~= OCP.veryBigNum
                    OCP.LBarrier.uMax = OCP.LBarrier.uMax - ...
                        OCP.barrierPara*OCP.uMax.barrierParameter(i)*log(OCP.uMax.value(i)-OCP.u(i));
                end
            end
    
        case 'G'
            OCP.GMax.value = boundValue;
            OCP.GMax.barrierParameter = barrierParameter;
            ParNMPCGlobalVariable.GMax = OCP.GMax.value;
            % barrier function
            G_formula = formula(OCP.G);
            [GDim,unused] = size(G_formula);
            [GMaxDim,unused] = size(OCP.GMax.value);
            OCP.LBarrier.GMax = sym(0);

            if GMaxDim == GDim 
                for i = 1:GDim
                    % GMax
                    if OCP.GMax.value(i)~=OCP.veryBigNum
                        OCP.LBarrier.GMax = OCP.LBarrier.GMax - ...
                            OCP.barrierPara*OCP.GMax.barrierParameter(i)*log(OCP.GMax.value(i)-G_formula(i));
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