function [C,Cu,Cx] = OCP_C_Cu_Cx(u,x,p) %#codegen
    C = OCP_GEN_C(u,x,p);
    Cu = OCP_GEN_Cu(u,x,p);
    Cx = OCP_GEN_Cx(u,x,p);
end