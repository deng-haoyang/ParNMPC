function t = Timer()
t = 0;
if coder.target('MATLAB')
    % count time
    t = cputime;
else
    coder.cinclude('omp.h');
    t = coder.ceval('omp_get_wtime');
end