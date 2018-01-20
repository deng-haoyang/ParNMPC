function t = Func_GetTime()
t = 0;
if coder.target('MATLAB')
    % count time
    t = cputime;
else
    t = coder.ceval('omp_get_wtime');
end