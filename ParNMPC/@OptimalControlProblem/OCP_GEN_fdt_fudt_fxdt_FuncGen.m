function OCP_GEN_fdt_fudt_fxdt_FuncGen(OCP)
    fileID = fopen('./funcgen/OCP_GEN_fdt_fudt_fxdt.m','w');
    
    fprintf(fileID, 'function [fdt,fudt,fxdt] = OCP_GEN_fdt_fudt_fxdt(u,x,p,parIdx)\n');
    fprintf(fileID, '   [f,fu,fx] = f_fu_fx_Wrapper(u,x,p,parIdx);\n');
    if isa(OCP.T,'numeric')
        fprintf(fileID, '   fdt = f*%f;\n',OCP.deltaTau);
        fprintf(fileID, '   fudt = fu*%f;\n',OCP.deltaTau);
        fprintf(fileID, '   fxdt = fx*%f;\n',OCP.deltaTau);
    else
        idx = 1:1:OCP.dim.p;
        TPosIdx = has(OCP.p,OCP.T);
        TPos = idx(TPosIdx>0);
        fprintf(fileID, '   fdt  = f*p(%d)/%d;\n', TPos,OCP.N);
        fprintf(fileID, '   fudt = fu*p(%d)/%d;\n',TPos,OCP.N);
        fprintf(fileID, '   fxdt = fx*p(%d)/%d;\n',TPos,OCP.N);
    end
    fprintf(fileID, 'end');
    fclose(fileID);

end