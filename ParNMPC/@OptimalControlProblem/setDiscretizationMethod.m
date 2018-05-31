function state = setDiscretizationMethod(OCP,method)
% state 0: ok
% state 1: Not Euler or RK4 selected

state = 0;
switch method
    case 'Euler'
    	OCP.discretizationMethod = 'Euler';
    case 'RK4'
        OCP.discretizationMethod = 'RK4';
    otherwise
    	OCP.discretizationMethod = 'Euler';
        state = 1;
end
end