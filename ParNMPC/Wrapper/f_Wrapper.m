function dx = f_Wrapper(u,x,p,parIdx)
% dx = f(u,x,p)
% parIdx: index of the core (for reentrant purpose)

    if coder.target('MATLAB') 
        % Specify your own f(u,x,p) function for normal excution
        
    else 
        % Specify your own f(u,x,p) function for code generation
        
    end
    
end