function setNonsingularRegularization(solver,value)
% nonsingular regularization parameter
if value > 0
    solver.nonsingularRegularization = value;
     % Global variable
    global ParNMPCGlobalVariable
    ParNMPCGlobalVariable.nonsingularRegularization = value;
else
    warning('Nonsingular regularization parameter must be nonnegtive!');
end

end