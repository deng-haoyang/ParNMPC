function OCP_GEN_C_Cu_Cx_FuncGen(OCP)
    fileID = fopen('./funcgen/OCP_GEN_C_Cu_Cx.m','w');
    
    fprintf(fileID, 'function [C,Cu,Cx] = OCP_GEN_C_Cu_Cx(u,x,p,parIdx)\n');
    fprintf(fileID, '   [C,Cu,Cx] = C_Cu_Cx_Wrapper(u,x,p,parIdx);\n');
    fprintf(fileID, 'end');
    fclose(fileID);

end