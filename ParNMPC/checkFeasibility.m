function checkFeasibility(solution,p)
    u = solution.u;
    x = solution.x;
    z = solution.z;
    
    if ~isempty(z)
        if ~isempty(z(z<0))
            error('Initial guess of z must be positive (z > 0)!');
        end
    end
    
    [~,N] = size(u);
    for i=1:N
        G_i = OCP_G(u(:,i),x(:,i),p(:,i));
        if ~isempty(G_i(G_i<=0))
           error(['Initial guess of G must be positive (G > 0)! Non-positive stage: ',num2str(i)]);
        end
    end
end