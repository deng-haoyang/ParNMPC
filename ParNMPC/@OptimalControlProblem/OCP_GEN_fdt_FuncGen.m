function OCP_GEN_fdt_FuncGen(OCP)
    fileID = fopen('./funcgen/OCP_GEN_fdt.m','w');
    
    fprintf(fileID, 'function fdt = OCP_GEN_fdt(u,x,p)\n');
    
    if isa(OCP.T,'numeric')
        fprintf(fileID, '   fdt = f_Wrapper(u,x,p)*%f;\n',OCP.deltaTau);
    else
        idx = 1:1:OCP.dim.p;
        TPosIdx = has(OCP.p,OCP.T);
        TPos = idx(TPosIdx>0);
        fprintf(fileID, '   fdt = f_Wrapper(u,x,p)*p(%d)/%d;\n',TPos,OCP.N);
    end
    
    fprintf(fileID, 'end');

    fclose(fileID);

end