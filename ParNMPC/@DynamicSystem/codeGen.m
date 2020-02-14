function codeGen(plant)
    if plant.dim.x + plant.dim.u < plant.THRESHOLD_DIM_UX
        isOptimize = true;
    else
        isOptimize = false;
    end

    showInfo(plant);
    disp('Generating plant...');
    if ~plant.isMEnabled
       % init M
       plant.M = sym(eye(plant.dim.x));
    end
    if isa(plant.f,'char')
        % external
        isExistfWrapper = exist('./fSim_Wrapper.m','file');
        if isExistfWrapper ~= 2
            copyfile('../ParNMPC/Wrapper/fSim_Wrapper.m','./fSim_Wrapper.m');
            disp('Please specify your own f(u,x,p) function in fSim_Wrapper.m');   
        else
            disp('fSim_Wrapper.m already exists and will be kept');
        end
        plant.SIM_GEN_f_FuncGen();
    else
        matlabFunction(plant.f,...
            'File','./funcgen/SIM_GEN_f',...
            'Vars',{plant.u;plant.x;plant.p},...
            'Outputs',{'f'},'Optimize',isOptimize);
    end
    matlabFunction(plant.M,...
        'File','./funcgen/SIM_GEN_M',...
        'Vars',{plant.u;plant.x;plant.p},...
        'Outputs',{'M'},'Optimize',isOptimize);
    disp('Done!')
end