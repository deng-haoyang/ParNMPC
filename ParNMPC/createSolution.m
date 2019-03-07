function solution = createSolution(dim,N)

    solution.lambda = zeros(dim.lambda,   N);
    solution.mu     = zeros(dim.mu,       N);
    solution.u      = zeros(dim.u,        N);
    solution.x      = zeros(dim.x,        N);
    solution.z      = zeros(dim.z,        N);
    solution.LAMBDA = zeros(dim.x, dim.x, N);
    
end


