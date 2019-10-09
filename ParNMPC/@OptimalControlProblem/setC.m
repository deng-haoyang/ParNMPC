function setC(OCP,varargin)
% set function C
% for example: setC('external',dim) or setC(C)

    global ParNMPCGlobalVariable
    
    nVarargs = length(varargin);
    C = varargin{1};
    
    % setC('external',dim)
    if nVarargs == 1
        if  isa(C,'char')
            error('setC should be setC(''external'',dim) or setC(C)!');
        else
            OCP.C = symfun(C,[OCP.u;OCP.x;OCP.p]);
            C_formula = formula(OCP.C);
            [muDim,~] = size(C_formula);
        end
    % setC(C)
    elseif nVarargs == 2 
        if  isa(C,'char')
            OCP.C = 'external';
            muDim = varargin{2};
        else
            error('setC should be setC(''external'',dim) or setC(C)!');
        end
    end
    
    % set size and init
    OCP.dim.mu = muDim;
    OCP.mu     = sym('mu',[OCP.dim.mu,1]);
    if size(OCP.mu,1) ~= OCP.dim.mu
       OCP.mu = OCP.mu.';
    end
    ParNMPCGlobalVariable.dim.mu = muDim;
    ParNMPCGlobalVariable.solutionInitGuess.mu = zeros(muDim,ParNMPCGlobalVariable.N);
end