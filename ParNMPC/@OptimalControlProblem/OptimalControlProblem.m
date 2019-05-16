classdef OptimalControlProblem < DynamicSystem
   properties
      lambda % symbolic variable
      mu = sym('mu',[0,1])% symbolic variable
      z  = sym('z', [0,1])% symbolic variable
      L % symbolic function
      LBarrier = sym(0)% barrier function LAll = L + rho*LBarrier
      C % symbolic function
      N % num of discretization grids - interger variable
      T % prediction horizon - double variable
      G % polytopic constraint G>=0 
      deltaTau % step size of discretization - double variable
      discretizationMethod = 'Euler'
   end
   methods
      function OCP = OptimalControlProblem(uDim,...
                                           xDim,...
                                           pDim,...
                                           N)
          % init all parameters
          OCP = OCP@DynamicSystem(uDim,xDim,pDim);
          % init dim
          OCP.dim.lambda = xDim;
          OCP.dim.mu     = 0;
          OCP.dim.z      = 0;
          OCP.dim.subDim = OCP.dim.lambda+OCP.dim.mu+OCP.dim.u+OCP.dim.x;
          % create symVar
          OCP.lambda = sym('lambda',[OCP.dim.lambda,1]); 
          if size(OCP.lambda,1) ~= OCP.dim.lambda
              OCP.lambda = OCP.lambda.';
          end
          if size(OCP.mu,1) ~= 0
              OCP.mu = OCP.mu.';
              OCP.z = OCP.z.';
          end
          %
          OCP.N = N; 
          % Global variable
          global ParNMPCGlobalVariable
          ParNMPCGlobalVariable.discretizationMethod = 'Euler';
          ParNMPCGlobalVariable.dim        = OCP.dim;
          ParNMPCGlobalVariable.isMEnabled = false;
%           ParNMPCGlobalVariable.isfExternal= false;
          ParNMPCGlobalVariable.N          = N;
          ParNMPCGlobalVariable.solutionInitGuess.lambda = zeros(xDim,N);
          ParNMPCGlobalVariable.solutionInitGuess.u      = zeros(uDim,N);
          ParNMPCGlobalVariable.solutionInitGuess.x      = zeros(xDim,N);
          ParNMPCGlobalVariable.solutionInitGuess.LAMBDA = -100*kron(eye(xDim),ones(N,1));
          
          
          % make dir and add to path
          [mkdirs,mkdirmess,mkdirmessid] = mkdir('./funcgen');
          addpath('./funcgen/')
      end
      setf(OCP,f)
      setM(OCP,M)
      varargout = setStateName(OCP,varargin)
      varargout = setInputName(OCP,varargin)
      varargout = setParameterName(OCP,varargin)
      setL(OCP,L)
      setC(OCP,varargin)
      setT(OCP,T)
      setG(OCP,G)
      setDiscretizationMethod(OCP,method)
      codeGen(OCP)
      showInfo(OCP)
      createNonemptySolution_FuncGen(OCP)
      OCP_GEN_fdt_FuncGen(OCP) % when external f is used  
      OCP_GEN_fdt_fudt_fxdt_FuncGen(OCP) % when external f is used
      OCP_GEN_C_FuncGen(OCP) % when external C is used  
      OCP_GEN_C_Cu_Cx_FuncGen(OCP) % when external C is used
   end
end