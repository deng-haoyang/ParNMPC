function showInfo(plant)
    disp(' ');
    disp('-------------------------DynamicSystem Information-----------------------');
    disp([num2str(plant.dim.u) ' inputs (u), ',num2str(plant.dim.x),' states (x), ',num2str(plant.dim.p) ' parameters (p)']);
    
    if plant.isMEnabled
        disp(['is M enabled: Yes']);
    else
        disp(['is M enabled: No']);
    end
    disp('-------------------------------------------------------------------------');
end