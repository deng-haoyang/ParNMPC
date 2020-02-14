function setf(obj,f)
    if  isa(f,'char')
        obj.f = 'external';
    else
        obj.f = f;
    end
end