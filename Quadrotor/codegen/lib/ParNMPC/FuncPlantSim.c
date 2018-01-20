/*
 * File: FuncPlantSim.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 02:13:18
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
 * Arguments    : const double u[8]
 *                const double x[9]
 *                double Ts
 *                double xNext[9]
 * Return Type  : void
 */
void FuncPlantSim(const double u[8], const double x[9], double Ts, double xNext
                  [9])
{
  double b_u[17];
  int i;
  double c_u[17];
  double k2[9];
  double d_u[17];
  double k3[9];
  double e_u[17];
  double dv8[9];
  memcpy(&b_u[0], &u[0], sizeof(double) << 3);
  memcpy(&b_u[8], &x[0], 9U * sizeof(double));
  GEN_Func_fSim(b_u, xNext);
  for (i = 0; i < 9; i++) {
    xNext[i] *= Ts;
  }

  memcpy(&c_u[0], &u[0], sizeof(double) << 3);
  for (i = 0; i < 9; i++) {
    c_u[i + 8] = x[i] + xNext[i] / 2.0;
  }

  GEN_Func_fSim(c_u, k2);
  for (i = 0; i < 9; i++) {
    k2[i] *= Ts;
  }

  memcpy(&d_u[0], &u[0], sizeof(double) << 3);
  for (i = 0; i < 9; i++) {
    d_u[i + 8] = x[i] + k2[i] / 2.0;
  }

  GEN_Func_fSim(d_u, k3);
  for (i = 0; i < 9; i++) {
    k3[i] *= Ts;
  }

  /*  update current state */
  memcpy(&e_u[0], &u[0], sizeof(double) << 3);
  for (i = 0; i < 9; i++) {
    e_u[i + 8] = x[i] + k3[i];
  }

  GEN_Func_fSim(e_u, dv8);
  for (i = 0; i < 9; i++) {
    xNext[i] = x[i] + (((xNext[i] + 2.0 * k2[i]) + 2.0 * k3[i]) + Ts * dv8[i]) /
      6.0;
  }
}

/*
 * File trailer for FuncPlantSim.c
 *
 * [EOF]
 */
