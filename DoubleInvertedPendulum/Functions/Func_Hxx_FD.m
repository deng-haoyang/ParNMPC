function Hxx = Func_Hxx_FD(in1,in2,xDim,subDim,FDStep)

Hxdt = GEN_Func_Hxdt(in1,in2);

Hxx = zeros(xDim,xDim);
e0 = zeros(subDim,1);
for i = 1:xDim
    ei = e0;
    ei(end-xDim+i) = 1;
    Hxx(:,i) = (GEN_Func_Hxdt(in1+ei*FDStep,in2) - Hxdt)/FDStep;
end
