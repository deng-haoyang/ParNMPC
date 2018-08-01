function [F,Fu,Fx] = OCP_F_Fu_Fx(u,x,p,discretizationMethod,isMEnabled) %#codegen
    [xDim,unused] = size(x);
    [uDim,unused] = size(u);
        
    if isMEnabled
        % forced to 'Euler'
        M = OCP_GEN_M(u,x,p);
        invM = inv(M);
        invMf = invM*OCP_GEN_fdt(u,x,p);
        % F
        F = invMf - x;
        % Fu
        MuInvMf = zeros(xDim,uDim);
        Mu = OCP_GEN_Mu(u,x,p);
        for i=1:uDim
            MuInvMf(:,i) = Mu(:,(i-1)*xDim+1:i*xDim)*invMf;
        end
        fu = OCP_GEN_fudt(u,x,p);
        Fu = invM*(fu-MuInvMf);
        % Fx
        MxInvMf = zeros(xDim,xDim);
        Mx = OCP_GEN_Mx(u,x,p);
        for i=1:xDim
            MxInvMf(:,i) = Mx(:,(i-1)*xDim+1:i*xDim)*invMf;
        end
        fx = OCP_GEN_fxdt(u,x,p);
        Fx = invM*(fx-MxInvMf) - eye(xDim);
    else % M disabled
        switch discretizationMethod
            case 'RK4'
                Ix = eye(xDim);
                k1 = OCP_GEN_fdt(u,x,p);
                k2 = OCP_GEN_fdt(u,x+k1/2,p);
                k3 = OCP_GEN_fdt(u,x+k2/2,p);
                k4 = OCP_GEN_fdt(u,x+k3,p);
                F = (k1+2*k2+2*k3+k4)/6 - x;

                k1u = OCP_GEN_fudt(u,x,p);
                k2u = OCP_GEN_fxdt(u,x+k1/2,p)*0.5*k1u + OCP_GEN_fudt(u,x+k1/2,p);
                k3u = OCP_GEN_fxdt(u,x+k2/2,p)*0.5*k2u + OCP_GEN_fudt(u,x+k2/2,p);
                k4u = OCP_GEN_fxdt(u,x+k3,p)*k3u + OCP_GEN_fudt(u,x+k3,p);
                Fu  =  (k1u+2*k2u+2*k3u+k4u)/6;

                k1x = OCP_GEN_fxdt(u,x,p);
                k2x = OCP_GEN_fxdt(u,x+k1/2,p)*(Ix + 0.5*k1x);
                k3x = OCP_GEN_fxdt(u,x+k2/2,p)*(Ix + 0.5*k2x);
                k4x = OCP_GEN_fxdt(u,x+k3,p)*(Ix + k3x);
                Fx  =  (k1x+2*k2x+2*k3x+k4x)/6 - Ix;
            otherwise % 'Euler'
                F = OCP_GEN_fdt(u,x,p) - x;
                Fu = OCP_GEN_fudt(u,x,p);
                Fx = OCP_GEN_fxdt(u,x,p) - eye(xDim);
        end
    end
end