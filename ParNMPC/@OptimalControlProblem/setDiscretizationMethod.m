function setDiscretizationMethod(OCP,method)

switch method
    case 'Euler'
    	OCP.discretizationMethod = 'Euler';
    case 'RK2'
        OCP.discretizationMethod = 'RK2';
    case 'RK4'
        OCP.discretizationMethod = 'RK4';
    otherwise
    	OCP.discretizationMethod = 'Euler';
end
global discretizationMethod
discretizationMethod = OCP.discretizationMethod;

end