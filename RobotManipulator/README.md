# Joint angle control of the 7 DOF robot manipulator KUKA LBR iiwa 14

![image]( https://github.com/ideaDeng/Gifs/blob/master/lbr8s.gif)

## Description

This example demonstrates how to use ParNMPC to control a 7 DOF robot manipulator using user-defined dynamics and derivatives. 
The robot manipulator's dynamics and derivatives are computed using Pinocchio (https://stack-of-tasks.github.io/pinocchio/), which is a very efficient C++ library for rigid multi-body dynamics computations. Since Pinocchio currently only supports Mac and Linux, we here demonstrate how to do the simulation on Ubuntu 18.04. 

The task is to control the manipulator to its desired reference under the constraints of the input torques and velocities.

## How to generate code?

1. Open `NMPC_Problem_Formulation.m` and run.
2. Open `Simu_Matlab_Codegen.m` and run.

The closed-loop simulation C++ files will be generated to `./codegen/lib/Simu_Matlab`. 

The Pinocchio interface is in `./kuka_iiwa14_pinocchio` (very simple). 

The urdf file of the manipulator is in `./kuka_iiwa14_pinocchio` (from MATLAB).

## How to run the generated C++ code?

1. Install Pinocchio on Ubuntu.
2. Follow the Pinocchio document, compile, and run. 

Compiler options:

- -DPINOCCHIO_URDFDOM_TYPEDEF_SHARED_PTR 
- -DPINOCCHIO_URDFDOM_USE_STD_SHARED_PTR
- -DPINOCCHIO_WITH_URDFDOM  
- -fopenmp

Linker options:

- -lboost_system 
- -lurdfdom_model 
- -lgomp
- -lpthread

## Computation time
In our setup (T = 1 s, N = 18, DOP = 6, i7-8950HK@2.9 GHz), the computation time is about 170 us/iteration. 
A sampling rate of 1 KHz can be achieved in real time. 




