function setNonsingularRegularization(solver,value)
% nonsingular regularization parameter
if value > 0
    global nonsingularRegularization
    solver.nonsingularRegularization = value;
    nonsingularRegularization = value;
else
    warning('Nonsingular regularization parameter must be nonnegtive!');
end

end