function F = OCP_F(u,x,p,discretizationMethod,isMEnabled) %#codegen

    if isMEnabled
        fdt = OCP_GEN_fdt(u,x,p);
        % forced to 'Euler'
        M = OCP_GEN_M(u,x,p);
        invM = inv(M);
        invMf = invM*fdt;
        % F
        F = invMf - x;
    else % M disabled
        switch discretizationMethod
            case 'RK2'
                fdt   = OCP_GEN_fdt(u,x,p);   
                f12dt = OCP_GEN_fdt(u,x-fdt/2,p);   

                F  =  f12dt  - x;
            case 'RK4'
                fdt   = OCP_GEN_fdt(u,x,p);   % k1
                f12dt = OCP_GEN_fdt(u,x-fdt/2,p); % k2
                f22dt = OCP_GEN_fdt(u,x-f12dt/2,p); % k3
                f3dt  = OCP_GEN_fdt(u,x-f22dt,p); % k4

                F = (fdt+2*f12dt+2*f22dt+f3dt)/6 - x;

            otherwise % 'Euler'
                fdt = OCP_GEN_fdt(u,x,p);
                F  = fdt - x;
        end
    end
end