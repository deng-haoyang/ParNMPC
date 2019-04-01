function SIM_GEN_f_FuncGen(plant)
    fileID = fopen('./funcgen/SIM_GEN_f.m','w');
    
    fprintf(fileID, 'function f = SIM_GEN_f(u,x,p)\n');
    fprintf(fileID, '   f = fSim_Wrapper(u,x,p);\n');
    fprintf(fileID, 'end');

    fclose(fileID);

end