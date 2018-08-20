function F = OCP_F(u,x,p,discretizationMethod,isMEnabled) %#codegen
    [xDim,unused] = size(x);
    [uDim,unused] = size(u);
        
    if isMEnabled
        % forced to 'Euler'
        M = OCP_GEN_M(u,x,p);
        invM = inv(M);
        invMf = invM*OCP_GEN_fdt(u,x,p);
        % F
        F = invMf - x;
    else % M disabled
        switch discretizationMethod
            case 'RK2'
                k1 = OCP_GEN_fdt(u,x,p);
                k2 = OCP_GEN_fdt(u,x-k1/2,p);
                F  = k2 - x;
            case 'RK4'
                k1 = OCP_GEN_fdt(u,x,p);
                k2 = OCP_GEN_fdt(u,x-k1/2,p);
                k3 = OCP_GEN_fdt(u,x-k2/2,p);
                k4 = OCP_GEN_fdt(u,x-k3,p);
                F = (k1+2*k2+2*k3+k4)/6 - x;
            otherwise % 'Euler'
                F = OCP_GEN_fdt(u,x,p) - x;
        end
    end

end