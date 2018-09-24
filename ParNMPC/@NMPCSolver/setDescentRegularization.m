function setDescentRegularization(solver,value)
% descent regularization parameter
% nonsingular regularization parameter
if value > 0
    global descentRegularization
    solver.descentRegularization = value;
    descentRegularization = value;
else
    error('Descent regularization parameter must be nonnegtive!');
end

end