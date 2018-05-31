function cost = getCost(solver,u,x,p)

N    = solver.OCP.N;
L    = zeros(N,1);
for i=1:N
    [L(i),Lu,Lx] = OCP_L_Lu_Lx(u(:,i),x(:,i),p(:,i));
end
cost = sum(L(:));

end