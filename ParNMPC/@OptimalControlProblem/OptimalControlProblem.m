classdef OptimalControlProblem < DynamicSystem
   properties
      lambda % symbolic variable
      mu % symbolic variable
      L % symbolic function
      C % symbolic function
      N % num of discretization grids - interger variable
      T % prediction horizon - double variable
      deltaTau % step size of discretization - double variable
      discretizationMethod = 'Euler';
   end
   methods
      function OCP = OptimalControlProblem(muDim,...
                                           uDim,...
                                           xDim,...
                                           pDim,...
                                           T,...
                                           N)
          % 
          OCP = OCP@DynamicSystem(uDim,xDim,pDim);
          % init dim
          OCP.dim.lambda = xDim;
          OCP.dim.mu = muDim;
          OCP.dim.subDim = OCP.dim.lambda+OCP.dim.mu+OCP.dim.u+OCP.dim.x;
          % create symVar
          OCP.lambda = sym('lambda',[OCP.dim.lambda,1]);
          OCP.mu = sym('mu',[OCP.dim.mu,1]);
          %
          OCP.T = T;
          OCP.N = N;
          OCP.deltaTau = OCP.T/OCP.N;
          % make dir and add to path
          [mkdirs,mkdirmess,mkdirmessid] = mkdir('./funcgen');
          [mkdirs,mkdirmess,mkdirmessid] = mkdir('./codegen/mex/OCP_KKTs');
          [mkdirs,mkdirmess,mkdirmessid] = mkdir('./codegen/lib/OCP_F_Fu_Fx');
          addpath('./funcgen/')
          addpath('./codegen/mex/OCP_KKTs')
          addpath('./codegen/lib/OCP_F_Fu_Fx')
      end
      setf(OCP,f)
      setM(OCP,M)
      varargout = setStateName(OCP,varargin)
      varargout = setInputName(OCP,varargin)
      varargout = setParameterName(OCP,varargin)
      setL(OCP,L)
      setC(OCP,C)
      setT(OCP,T)
      setDiscretizationMethod(OCP,method)
      codeGen(OCP)
   end
end