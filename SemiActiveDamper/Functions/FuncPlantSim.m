function xNext = FuncPlantSim(u,x,pSim,Ts)

k1 = Ts*GEN_Func_fSim([u;x;     pSim]);
k2 = Ts*GEN_Func_fSim([u;x+k1/2;pSim]);
k3 = Ts*GEN_Func_fSim([u;x+k2/2;pSim]);
k4 = Ts*GEN_Func_fSim([u;x+k3;  pSim]);
% update current state
xNext = x + (k1+2*k2+2*k3+k4)/6;