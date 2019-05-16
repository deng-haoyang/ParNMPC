function C = C_Wrapper(u,x,p,parIdx)
% C = C(u,x,p)
% parIdx: index of the core (for reentrant purpose)

    if coder.target('MATLAB') 
        % Specify your own C(u,x,p) function for normal excution
        
    else 
        % Specify your own C(u,x,p) function for code generation
        
    end
    
end