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
% Global variable
global ParNMPCGlobalVariable
ParNMPCGlobalVariable.discretizationMethod = OCP.discretizationMethod;


end