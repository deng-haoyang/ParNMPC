%% For closed-loop simulation or code generation
function Simu_Matlab %#codegen
simuLength = 7;   
Ts         = 0.01; % sampling interval
simuSteps  = floor(simuLength/Ts);

if coder.target('MATLAB')
    clear NMPC_Solve
end

% Load data
initData   = coder.load('GEN_initData.mat');
dim        = initData.dim;
N          = initData.N;
p          = initData.p;
x0         = initData.x0;

% define record variables
rec.x       = zeros(simuSteps+1,dim.x);
rec.x(1,:)  = x0.';
rec.u       = zeros(simuSteps,  dim.u);
rec.numIter = zeros(simuSteps,1);
rec.error   = zeros(simuSteps,1);
rec.cost    = zeros(simuSteps,1);
rec.t       = zeros(simuSteps,1);
rec.cpuTime                = zeros(simuSteps,1);
rec.cpuTimeSearchDirection = zeros(simuSteps,1);
rec.cpuTimeLineSearch      = zeros(simuSteps,1);
rec.cpuTimeKKTError        = zeros(simuSteps,1);

%% Simulation
options              = createOptions();
options.DoP          = 1; % degree of parallism: 1 = in serial, otherwise in parallel
options.isLineSearch = false;
options.rhoInit      = 1e-1;
options.rhoEnd       = 1e-1;
options.maxIterInit  = 10;
options.maxIterTotal = 10;

% init
tTotal   = 0;
output   = createOutput();
solution = createSolution(dim,N);

for step = 1:simuSteps %simulation steps
    % Solve the optimal control problem
    x0Measured = x0;
    [solution,output] = NMPC_Solve(x0Measured,p,options);
    tTotal        = tTotal + output.timeElapsed.total;
    
    %
    if mod(step,20)==0
        clf
        plot(solution.x(1,:),solution.x(2,:));
        hold on
        circle(0,0,sqrt(1));
        hold on
        circle(2,2,sqrt(1));
        hold on
        plot(3.5,2,'*')
        hold on
        plot(x0(1),x0(2),'o')
    end
    % Obtain the first optimal control input
    uOptimal = solution.u(:,1);
    
    % System simulation by the 4th-order Explicit Runge-Kutta Method
    pSimVal = zeros(0,1);
    x0 = SIM_Plant_RK4(uOptimal(1:4,1),x0,pSimVal,Ts);

    % Update parameters
    
    % Record data
    rec.x(step+1,:)      = x0Measured.';
    rec.u(step,:)        = uOptimal.';
    rec.error(step,:)    = output.KKTError;
    rec.cpuTime(step,:)  = output.timeElapsed.total*1e6;
    rec.cpuTimeSearchDirection(step,:)  = output.timeElapsed.searchDirection*1e6;
    rec.cpuTimeLineSearch(step,:)  = output.timeElapsed.lineSearch*1e6;
    rec.cpuTimeKKTError(step,:)  = output.timeElapsed.KKTErrorCheck*1e6;
    rec.t(step,:)        = step*Ts;
    rec.numIter(step,:)  = output.iterTotal;
    rec.cost(step,:)     = output.cost;
    if coder.target('MATLAB')
         disp(['Step: ',num2str(step),'/',num2str(simuSteps),...
               '   iterInit: ',num2str(output.iterInit),...
               '   iterTotal: ', num2str(output.iterTotal),...
               '   KKTError:' ,num2str(output.KKTError)]);
    end
end
%% Log to file
if coder.target('MATLAB')% Normal excution
    save('GEN_log_rec.mat','rec');
    % count time
    disp(['Time Elapsed for NMPC_Solve: ',num2str(tTotal) ' seconds ']);
else % Code generation
    coder.cinclude('stdio.h');
    coder.cinclude('omp.h');
    % show Time Elapsed for RTI
    fmt1 = coder.opaque( 'const char *',['"',...
                                        'Time Elapsed for NMPC_Solve: %f s\r\n',...
                                        'Timer Precision: %f us\r\n',...
                                        '"']);
    wtrick = 0; % Timer precision
    wtrick = coder.ceval('omp_get_wtick');
    wtrick = wtrick*1e6;
    coder.ceval('printf',fmt1, tTotal,wtrick);
    % Log to file
    fileID = fopen('GEN_log_rec.txt','w');
    % printf header
    for j=1:dim.x
        fprintf(fileID,'%s\t',['x',char(48+j)]);
    end
    for j=1:dim.u
        fprintf(fileID,'%s\t',['u',char(48+j)]);
    end
    fprintf(fileID,'%s\t','error');
    fprintf(fileID,'%s\t','numIter');
    fprintf(fileID,'%s\t','cpuTime');
    fprintf(fileID,'%s\t','cpuTimeSearchDirection');
    fprintf(fileID,'%s\t','cpuTimeLineSearch');
    fprintf(fileID,'%s\n','cpuTimeKKTError');
    % printf data
    for i=1:simuSteps
        for j=1:dim.x
            fprintf(fileID,'%f\t',rec.x(i,j));
        end
        for j=1:dim.u
            fprintf(fileID,'%f\t',rec.u(i,j));
        end
        fprintf(fileID,'%f\t',rec.error(i,1));
        fprintf(fileID,'%f\t',rec.numIter(i,1));
        fprintf(fileID,'%f\t',rec.cpuTime(i,1));
        fprintf(fileID,'%f\t',rec.cpuTimeSearchDirection(i,1));
        fprintf(fileID,'%f\t',rec.cpuTimeLineSearch(i,1));
        fprintf(fileID,'%f\n',rec.cpuTimeKKTError(i,1));
    end
    fclose(fileID);
end