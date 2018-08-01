# ParNMPC

Homepage: https://deng-haoyang.github.io/ParNMPC/

**`ParNMPC`** is a MATLAB real-time optimization toolkit for nonlinear model predictive control (NMPC).
**`ParNMPC`** can utilize multiple CPU cores to solve the optimal control problem, and thus can be very fast (the computation time is usually in the range of us). 
The purpose of **`ParNMPC`** is to provide an easy-to-use environment for NMPC problem formulation, closed-loop simulation and deployment.

### Features
* Symbolic problem representation
* Automatic parallel C/C++ code generation with OpenMP
* Fast rate of convergence (up to be superlinear)
* Highly parallelizable (capable of using at most N cores, N is the # of discretization steps)
* High speedup ratio
* MATLAB & Simulink 


## Installation

1. Clone or download **`ParNMPC`**.
2. Extract the downloaded file.

## Requirements

* MATLAB 2016a or later
* MATLAB Coder
* MATLAB Optimization Toolbox
* MATLAB Parallel Computing Toolbox
* MATLAB Symbolic Math Toolbox
* C/C++ compiler supporting parallel code generation

## Getting Started 

This section shows how to do the closed-loop simulation in Simulink using MATLAB R2016a and Microsoft Visual C++ 2015 Professional as an example.

1. Run the following MATLAB command and select the Microsoft Visual C++ 2015 Professional (C) compiler:
``` Matlab
>> mex -setup
```

2. Navigate to the *Quadrotor/* folder.
``` Matlab
>> cd  Quadrotor/
```

3. Open `NMPC_Problem_Formulation.m` and run. By running this file, the following things are done:

	* The NMPC controller is defined and configured, and necessary files are automatically generated to the `./funcgen/` and `./codegen/` folders.
	* The very first OCP is solved and its solution is saved to `GEN_initData.mat`.
	* The controlled plant for simulation is defined and auto-generated.
	
4. Open `Simu_Simulink_Setup.m` and run. By doing this, the NMPC controller is generated into C codes and compilied into a DLL file.

5. Open `Simu_Simulink.slx` and run. `Simu_Simulink.slx` calls the generated NMPC controller function from the DLL file.

## Version
Version 1808-1
