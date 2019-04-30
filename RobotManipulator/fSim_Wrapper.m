function dx = fSim_Wrapper(u,x,p)
% dx = f(u,x,p)
    if coder.target('MATLAB') 
        % Specify your own f(u,x,p) function for normal excution
    else 
        % Specify your own f(u,x,p) function for code generation
        coder.cinclude('iiwa14.h');
        q = x(1:7,1);
        qd = x(8:end,1);
        qdd = zeros(7,1);
        tau = u(1:7,1);
        coder.ceval('sim_qdd_cal',  coder.ref(q),...
                                    coder.ref(qd),...
                                    coder.ref(qdd),...
                                    coder.ref(tau));
        dx  = [qd;qdd];
    end
end