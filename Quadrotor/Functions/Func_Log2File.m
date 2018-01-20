fileID = fopen('GEN_log_rec.txt','w');
% printf header
for j=1:xDim
    fprintf(fileID,'%s\t',['x',char(48+j)]);
end
for j=1:uDim
    fprintf(fileID,'%s\t',['u',char(48+j)]);
end
fprintf(fileID,'%s\t','error');
fprintf(fileID,'%s\t','numIter');
fprintf(fileID,'%s\n','cpuTime');
% printf data
for i=1:simuSteps
    for j=1:xDim
        fprintf(fileID,'%f\t',rec.x(i,j));
    end
    for j=1:uDim
        fprintf(fileID,'%f\t',rec.u(i,j));
    end
    fprintf(fileID,'%f\t',rec.error(i,1));
    fprintf(fileID,'%f\t',rec.numIter(i,1));
    fprintf(fileID,'%f\n',rec.cpuTime(i,1));
end
fclose(fileID);