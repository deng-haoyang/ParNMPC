function dKKT = Func_dKKT_FD(in1,in2,xDim,subDim,h)

dKKT = GEN_Func_dKKT_NoHxx(in1,in2);
Hxdt = GEN_Func_Hxdt(in1,in2);

Hxx = zeros(xDim,xDim);
e0 = zeros(subDim,1);
for i = 1:xDim
    ei = e0;
    ei(end-xDim+i) = 1;
    Hxx(:,i) = (GEN_Func_Hxdt(in1+ei*h,in2) - Hxdt)/h;
end

dKKT(end-xDim+1:end,end-xDim+1:end) = Hxx;