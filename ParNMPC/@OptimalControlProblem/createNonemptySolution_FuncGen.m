function createNonemptySolution_FuncGen(OCP)
    dim = OCP.dim;
    N = OCP.N;
    fileID = fopen('./funcgen/createNonemptySolution.m','w');
    
    fprintf(fileID, 'function solution = createNonemptySolution()\n');
    fprintf(fileID, '   solution.lambda = zeros(%d,%d);\n',dim.lambda,N);
    if dim.mu ~= 0
        fprintf(fileID, '   solution.mu = zeros(%d,%d);\n',dim.mu,N);
    end
    fprintf(fileID, '   solution.u = zeros(%d,%d);\n',dim.u,N);
    fprintf(fileID, '   solution.x = zeros(%d,%d);\n',dim.x,N);
    if dim.z ~= 0
        fprintf(fileID, '   solution.z = zeros(%d,%d);\n',dim.z,N);
    end
    fprintf(fileID, '   solution.LAMBDA = zeros(%d,%d,%d);\n',dim.x,dim.x,N);    
    fprintf(fileID, 'end');

    fclose(fileID);

end