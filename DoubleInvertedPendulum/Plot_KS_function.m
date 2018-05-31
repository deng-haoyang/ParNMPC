% KS function
xMax = 0.19;
xMin = -0.19;
p = 0.01;
i=1;
range = -0.22:0.001:0.22;
L = zeros(size(range));
for x = range
    L(i) =  1000*p*log(1 + exp(1/p*(x-xMax)))...
          + 1000*p*log(1 + exp(1/p*(xMin-x)));
    i = i+1;
end
plot(range.',L.');