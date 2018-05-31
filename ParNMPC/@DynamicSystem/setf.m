function setf(obj,f)
    obj.f = symfun(f,[obj.u;obj.x;obj.p]);
end