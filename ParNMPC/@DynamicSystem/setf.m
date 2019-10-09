function setf(obj,f)
    if  isa(f,'char')
        obj.f = 'external';
    else
        obj.f = symfun(f,[obj.u;obj.x;obj.p]);
    end
end