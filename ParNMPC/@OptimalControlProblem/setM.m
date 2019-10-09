function setM(OCP,M)
    OCP.M = symfun(M,[OCP.u;OCP.x;OCP.p]);
    OCP.isMEnabled = true;
    global ParNMPCGlobalVariable
    ParNMPCGlobalVariable.isMEnabled = true;
end