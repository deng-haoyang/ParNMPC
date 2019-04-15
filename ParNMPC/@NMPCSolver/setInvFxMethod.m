function setInvFxMethod(solver,method)
global ParNMPCGlobalVariable
switch method
    case 'approximate'
        solver.isApproximateInvFx = true;
        ParNMPCGlobalVariable.isApproximateInvFx      = true;
    otherwise
        solver.isApproximateInvFx = false;
        ParNMPCGlobalVariable.isApproximateInvFx      = false;
end

end