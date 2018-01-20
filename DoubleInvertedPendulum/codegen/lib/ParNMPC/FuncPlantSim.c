/*
 * File: FuncPlantSim.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 01:36:29
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
 * Arguments    : const double u[2]
 *                const double x[6]
 *                double Ts
 *                double xNext[6]
 * Return Type  : void
 */
void FuncPlantSim(const double u[2], const double x[6], double Ts, double xNext
                  [6])
{
  double b_u[8];
  int i;
  double k2[6];
  double k3[6];
  double dv8[6];
  for (i = 0; i < 2; i++) {
    b_u[i] = u[i];
  }

  for (i = 0; i < 6; i++) {
    b_u[i + 2] = x[i];
  }

  GEN_Func_fSim(b_u, xNext);
  for (i = 0; i < 6; i++) {
    xNext[i] *= Ts;
  }

  for (i = 0; i < 2; i++) {
    b_u[i] = u[i];
  }

  for (i = 0; i < 6; i++) {
    b_u[i + 2] = x[i] + xNext[i] / 2.0;
  }

  GEN_Func_fSim(b_u, k2);
  for (i = 0; i < 6; i++) {
    k2[i] *= Ts;
  }

  for (i = 0; i < 2; i++) {
    b_u[i] = u[i];
  }

  for (i = 0; i < 6; i++) {
    b_u[i + 2] = x[i] + k2[i] / 2.0;
  }

  GEN_Func_fSim(b_u, k3);
  for (i = 0; i < 6; i++) {
    k3[i] *= Ts;
  }

  /*  update current state */
  for (i = 0; i < 2; i++) {
    b_u[i] = u[i];
  }

  for (i = 0; i < 6; i++) {
    b_u[i + 2] = x[i] + k3[i];
  }

  GEN_Func_fSim(b_u, dv8);
  for (i = 0; i < 6; i++) {
    xNext[i] = x[i] + (((xNext[i] + 2.0 * k2[i]) + 2.0 * k3[i]) + Ts * dv8[i]) /
      6.0;
  }
}

/*
 * File trailer for FuncPlantSim.c
 *
 * [EOF]
 */
