function [L,LBarrier,Lu,Lx] = OCP_L_Lu_Lx(u,x,p,barrierPara) %#codegen
    L  = OCP_GEN_L(u,x,p);
    Lu = OCP_GEN_Lu(u,x,p);
    Lx = OCP_GEN_Lx(u,x,p);
    
    LBarrier  = OCP_GEN_LBarrier(u,x,p,barrierPara);
    LBarrieru = OCP_GEN_LBarrieru(u,x,p,barrierPara);
    LBarrierx = OCP_GEN_LBarrierx(u,x,p,barrierPara);
    
    Lu = Lu + LBarrieru;
    Lx = Lx + LBarrierx;
end