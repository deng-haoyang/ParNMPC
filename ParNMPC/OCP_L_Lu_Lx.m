function [L,Lu,Lx] = OCP_L_Lu_Lx(u,x,p) %#codegen
    L  = OCP_GEN_L(u,x,p);
    Lu = OCP_GEN_Lu(u,x,p);
    Lx = OCP_GEN_Lx(u,x,p);
end