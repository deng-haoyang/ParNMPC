function dx = fSim_Wrapper(u,x,p)
% dx = f(u,x,p)
    if coder.target('MATLAB') 
        % Specify your own f(u,x,p) function for normal excution
        
    else 
        % Specify your own f(u,x,p) function for code generation
        
    end
    
end