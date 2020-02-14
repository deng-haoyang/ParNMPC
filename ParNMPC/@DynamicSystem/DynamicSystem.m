classdef DynamicSystem < handle
   properties
      dim % dimension - sturct
      u % symbolic variable
      x % symbolic variable
      p % symbolic variable
      f % symbolic function
      M % symbolic function
      isMEnabled = false; % enable dot x = inv(M)*f
      THRESHOLD_DIM_UX = 30;
   end
   methods
      function plant = DynamicSystem(uDim,...
                                     xDim,...
                                     pDim)
          % init dim
          plant.dim.u = uDim;
          plant.dim.x = xDim;
          plant.dim.p = pDim;
          % create symVar
          plant.u = sym('u',[plant.dim.u,1]);
          plant.x = sym('x',[plant.dim.x,1]);
          plant.p = sym('p',[plant.dim.p,1]);
          if size(plant.u,1) ~= plant.dim.u
              plant.u = plant.u.';
              plant.x = plant.x.';
              plant.p = plant.p.';
          end
          
          % 
%           global isMEnabled
%           isMEnabled = false;
      end
      setf(plant,f)
      setM(plant,M)
      varargout = setStateName(plant,varargin)
      varargout = setInputName(plant,varargin)
      varargout = setParameterName(plant,varargin)
      showInfo(plant)
      codeGen(plant)
      SIM_GEN_f_FuncGen(plant)
   end
end