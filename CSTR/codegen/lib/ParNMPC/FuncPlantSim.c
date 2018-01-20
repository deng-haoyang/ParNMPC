/*
 * File: FuncPlantSim.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 02:06:04
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "ParNMPC.h"
#include "FuncPlantSim.h"
#include "GEN_Func_fSim.h"
#include <stdio.h>
#include "omp.h"
#include "stdio.h"

/* Function Definitions */

/*
 * Arguments    : const double u[4]
 *                const double x[4]
 *                double Ts
 *                double xNext[4]
 * Return Type  : void
 */
void FuncPlantSim(const double u[4], const double x[4], double Ts, double xNext
                  [4])
{
  double b_u[8];
  int i;
  double k2[4];
  double b_xNext;
  double k3[4];
  double b_k2;
  double dv8[4];
  double b_k3;
  for (i = 0; i < 4; i++) {
    b_u[i] = u[i];
    b_u[i + 4] = x[i];
  }

  GEN_Func_fSim(b_u, xNext);
  for (i = 0; i < 4; i++) {
    b_xNext = Ts * xNext[i];
    b_u[i] = u[i];
    b_u[i + 4] = x[i] + b_xNext / 2.0;
    xNext[i] = b_xNext;
  }

  GEN_Func_fSim(b_u, k2);
  for (i = 0; i < 4; i++) {
    b_k2 = Ts * k2[i];
    b_u[i] = u[i];
    b_u[i + 4] = x[i] + b_k2 / 2.0;
    k2[i] = b_k2;
  }

  GEN_Func_fSim(b_u, k3);

  /*  update current state */
  for (i = 0; i < 4; i++) {
    b_k3 = Ts * k3[i];
    b_u[i] = u[i];
    b_u[i + 4] = x[i] + b_k3;
    k3[i] = b_k3;
  }

  GEN_Func_fSim(b_u, dv8);
  for (i = 0; i < 4; i++) {
    xNext[i] = x[i] + (((xNext[i] + 2.0 * k2[i]) + 2.0 * k3[i]) + Ts * dv8[i]) /
      6.0;
  }
}

/*
 * File trailer for FuncPlantSim.c
 *
 * [EOF]
 */
