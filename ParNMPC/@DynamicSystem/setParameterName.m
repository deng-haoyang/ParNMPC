function varargout = setParameterName(obj,varargin)
    nVarargs = length(varargin);
    name = varargin{1};
    if nVarargs == 2
        index = varargin{2};
    else
        index = 1:obj.dim.p;
    end
    varargout = cell(size(index));
    j = 1;
    for i=index
        obj.p(i) = sym(name{j});
        varargout{j} = sym(name{j});
        j = j+1;
    end
end