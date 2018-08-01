classdef OptimalControlProblem < DynamicSystem
   properties
      lambda % symbolic variable
      mu % symbolic variable
      L % symbolic function
      C % symbolic function
      N % num of discretization grids - interger variable
      T % prediction horizon - double variable
      G % polytopic constraint
      deltaTau % step size of discretization - double variable
      discretizationMethod = 'Euler'
      uMax
      uMin
      xMax
      xMin
      GMax % upper bound of the polytopic constraint G
      GMin
      LBarrier
      veryBigNum = 7.7777e77;
   end
   methods
      function OCP = OptimalControlProblem(muDim,...
                                           uDim,...
                                           xDim,...
                                           pDim,...
                                           T,...
                                           N)
          % init all parameters
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
          %
          OCP.LBarrier.uMax = sym(0);
          OCP.LBarrier.uMin = sym(0);
          OCP.LBarrier.xMax = sym(0);
          OCP.LBarrier.xMin = sym(0);
          OCP.LBarrier.GMax = sym(0);
          OCP.LBarrier.GMin = sym(0);
          OCP.LBarrier.all  = sym(0);
          %
          OCP.GMax.value = zeros(0,1);
          OCP.GMin.value = zeros(0,1);
          OCP.GMax.barrierParameter = zeros(0,1);
          OCP.GMin.barrierParameter = zeros(0,1);
          OCP.G = symfun(zeros(0,1),[OCP.u;OCP.x;OCP.p]);
          %
          OCP.uMax.value =  ones(OCP.dim.u,1)*OCP.veryBigNum;
          OCP.uMin.value = -ones(OCP.dim.u,1)*OCP.veryBigNum;
          OCP.xMax.value =  ones(OCP.dim.x,1)*OCP.veryBigNum;
          OCP.xMin.value = -ones(OCP.dim.x,1)*OCP.veryBigNum;
          % 
          global uMax uMin xMax xMin GMax GMin discretizationMethod veryBigNum
          uMax = OCP.uMax.value;
          uMin = OCP.uMin.value;
          xMax = OCP.xMax.value;
          xMin = OCP.xMin.value;
          GMax = OCP.GMax.value;
          GMin = OCP.GMin.value;
          discretizationMethod = 'Euler';
          veryBigNum = OCP.veryBigNum;
          % make dir and add to path
          [mkdirs,mkdirmess,mkdirmessid] = mkdir('./funcgen');
          [mkdirs,mkdirmess,mkdirmessid] = mkdir('./codegen/lib/OCP_F_Fu_Fx');
          addpath('./funcgen/')
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
      setG(OCP,G)
      setUpperBound(OCP,field,boundValue,barrierParameter)
      setLowerBound(OCP,field,boundValue,barrierParameter)
      setDiscretizationMethod(OCP,method)
      codeGen(OCP)
   end
end