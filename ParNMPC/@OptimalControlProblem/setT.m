function setT(OCP,T)
    OCP.T = T;
    OCP.deltaTau = OCP.T/OCP.N;
end