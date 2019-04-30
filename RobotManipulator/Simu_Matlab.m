%% For code generation
function Simu_Matlab %#codegen
simuLength = 8;   
Ts         = 0.001; % sampling interval 
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
rec.x       = ones(simuSteps+1,dim.x);
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
options.DoP          = 4; % degree of parallism: 1 = in serial, otherwise in parallel
options.isLineSearch = false;
options.lineSearchMethod = 'filter';
options.rhoInit      = 1e-3;
options.rhoEnd       = 1e-3;
options.tolEnd       = 1e-3;
options.maxIterTotal = 10; 
options.maxIterInit  = 10;
options.checkKKTErrorAfterIteration = false; % do not check the KKT error after iteration
% init
tTotal   = 0;
output   = createOutput();
solution = createSolution(dim,N);

for step = 1:simuSteps %simulation steps
    % Set the reference angle q_ref with a rate limit
    % 0<t<4: q_ref = [0,   pi/2,0,    pi/2, 0,    pi/2, 0]
    % 4<t<8: q_ref = [pi/2,0,   pi/2, 0,    pi/2, 0,    pi/2]
    if step >= 1 && step < 4000
        ref_prev = [0,0,0,0,0,0,0];
        ref_new  = [0,pi/2,0,pi/2,0,pi/2,0];
        k = step*0.008;
        k(k>1) = 1;
        ref = k*ref_new + (1-k)*ref_prev;
        for iRef = 1:7
            p(iRef,:) =  ref(iRef);
        end
    elseif step >= 4000
        ref_prev = [0,pi/2,0,pi/2,0,pi/2,0];
        ref_new  = [pi/2,0 ,pi/2,0,   pi/2,0,pi/2];
        k = (step-4000)*0.008;
        k(k>1) = 1;
        ref = k*ref_new + (1-k)*ref_prev;
        for iRef = 1:7
            p(iRef,:) =  ref(iRef);
        end
    end

    % Solve the optimal control problem
    x0Measured = x0;
    [solution,output] = NMPC_Solve(x0Measured,p,options);

    tTotal        = tTotal + output.timeElapsed.total;
    
    % Obtain the first optimal control input
    uOptimal = solution.u(:,1);
    
    % System simulation by the 4th-order Explicit Runge-Kutta Method
    pSimVal = zeros(0,1);
    x0 = SIM_Plant_RK4(uOptimal(1:7,1),x0,pSimVal,Ts);
    
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
    % show Time Elapsed for RTI
    fmt1 = coder.opaque( 'const char *',['"',...
                                        'Time Elapsed for NMPC_Solve: %f s\r\n',...
                                        '"']);
    coder.ceval('printf',fmt1, tTotal);
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