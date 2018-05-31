function setC(OCP,C)
	OCP.C = symfun(C,[OCP.u;OCP.x;OCP.p]);
end