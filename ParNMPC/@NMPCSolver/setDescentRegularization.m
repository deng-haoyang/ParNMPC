function setDescentRegularization(solver,value)
% descent regularization parameter
% nonsingular regularization parameter
if value > 0
    % Global variable
    global ParNMPCGlobalVariable

    solver.descentRegularization = value;
    ParNMPCGlobalVariable.descentRegularization = value;
else
    error('Descent regularization parameter must be nonnegtive!');
end

end