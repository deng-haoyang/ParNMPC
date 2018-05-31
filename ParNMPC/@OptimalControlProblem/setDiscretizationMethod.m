function setDiscretizationMethod(OCP,method)

switch method
    case 'Euler'
    	OCP.discretizationMethod = 'Euler';
    case 'RK4'
        OCP.discretizationMethod = 'RK4';
    otherwise
    	OCP.discretizationMethod = 'Euler';
end
end