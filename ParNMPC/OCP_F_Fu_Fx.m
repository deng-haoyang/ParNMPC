function [F,Fu,Fx] = OCP_F_Fu_Fx(u,x,p,discretizationMethod,isMEnabled,parIdx) %#codegen
    [xDim,unused] = size(x);
    [uDim,unused] = size(u);
    Ix = eye(xDim);

    if isMEnabled
        [fdt,fudt,fxdt] = OCP_GEN_fdt_fudt_fxdt(u,x,p,parIdx);
        % forced to 'Euler'
        M = OCP_GEN_M(u,x,p);
        invM = inv(M);
        invMf = invM*fdt;
        % F
        F = invMf - x;
        % Fu
        MuInvMf = zeros(xDim,uDim);
        Mu = OCP_GEN_Mu(u,x,p);
        for i=1:uDim
            MuInvMf(:,i) = Mu(:,(i-1)*xDim+1:i*xDim)*invMf;
        end
        Fu = invM*(fudt-MuInvMf);
        % Fx
        MxInvMf = zeros(xDim,xDim);
        Mx = OCP_GEN_Mx(u,x,p);
        for i=1:xDim
            MxInvMf(:,i) = Mx(:,(i-1)*xDim+1:i*xDim)*invMf;
        end
        Fx = invM*(fxdt-MxInvMf) - Ix;
    else % M disabled
        switch discretizationMethod
            case 'RK2'
                [fdt,fudt,fxdt] = OCP_GEN_fdt_fudt_fxdt(u,x,p,parIdx);   
                [f12dt,fu12dt,fx12dt] = OCP_GEN_fdt_fudt_fxdt(u,x-fdt/2,p,parIdx);   

                F  =  f12dt  - x;
                Fu =  fu12dt - 0.5*fx12dt*fudt;
                Fx =  fx12dt - 0.5*fx12dt*fxdt - Ix;
            case 'RK4'
                [fdt,fudt,fxdt]       = OCP_GEN_fdt_fudt_fxdt(u,x,p,parIdx);   % k1
                [f12dt,fu12dt,fx12dt] = OCP_GEN_fdt_fudt_fxdt(u,x-fdt/2,p,parIdx); % k2
                [f22dt,fu22dt,fx22dt] = OCP_GEN_fdt_fudt_fxdt(u,x-f12dt/2,p,parIdx); % k3
                [f3dt,fu3dt,fx3dt]    = OCP_GEN_fdt_fudt_fxdt(u,x-f22dt,p,parIdx); % k4

                F = (fdt+2*f12dt+2*f22dt+f3dt)/6 - x;

                k1u =  fudt;
                k2u =  fu12dt -0.5*fx12dt*k1u;
                k3u =  fu22dt -0.5*fx22dt*k2u;
                k4u =  fu3dt - fx3dt*k3u;
                Fu  =  (k1u+2*k2u+2*k3u+k4u)/6;

                k1x = fxdt;
                k2x = fx12dt - 0.5*fx12dt*k1x;
                k3x = fx22dt - 0.5*fx22dt*k2x;
                k4x = fx3dt*(Ix - k3x);
                Fx  = (k1x+2*k2x+2*k3x+k4x)/6 - Ix;
            otherwise % 'Euler'
                [fdt,fudt,fxdt] = OCP_GEN_fdt_fudt_fxdt(u,x,p,parIdx);
                F  = fdt - x;
                Fu = fudt;
                Fx = fxdt - Ix;
        end
    end
end