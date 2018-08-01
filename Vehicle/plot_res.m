
data = load('GEN_log_rec.mat');

plot(data.rec.x(:,1),data.rec.x(:,2));
hold on
circle(0,0,sqrt(1));
