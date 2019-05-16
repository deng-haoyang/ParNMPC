function OCP_GEN_C_FuncGen(OCP)
    fileID = fopen('./funcgen/OCP_GEN_C.m','w');
    
    fprintf(fileID, 'function C = OCP_GEN_C(u,x,p,parIdx)\n');
    fprintf(fileID, '   C = C_Wrapper(u,x,p,parIdx);\n');
    fprintf(fileID, 'end');

    fclose(fileID);

end