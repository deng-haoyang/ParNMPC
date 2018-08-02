
data = load('GEN_log_rec.mat');

plot(data.rec.x(:,1),data.rec.x(:,2));
hold on
circle(0,0,sqrt(1));
hold on
circle(2,2,sqrt(1));
hold on
plot(xRef(1),xRef(2),'*')
hold on
plot(x0(1),x0(2),'o')