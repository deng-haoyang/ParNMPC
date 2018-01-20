/*
 * File: Func_Hxx_FD.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 02:06:04
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "ParNMPC.h"
#include "Func_Hxx_FD.h"
#include "GEN_Func_Hxdt.h"
#include <stdio.h>
#include "omp.h"
#include "stdio.h"

/* Function Definitions */

/*
 * Arguments    : const double in1[14]
 *                double Hxx[16]
 * Return Type  : void
 */
void Func_Hxx_FD(const double in1[14], double Hxx[16])
{
  double Hxdt[4];
  int i;
  signed char ei[14];
  int b_i;
  double b_in1[14];
  double dv7[4];
  GEN_Func_Hxdt(in1, Hxdt);
  for (i = 0; i < 4; i++) {
    for (b_i = 0; b_i < 14; b_i++) {
      ei[b_i] = 0;
    }

    ei[10 + i] = 1;
    for (b_i = 0; b_i < 14; b_i++) {
      b_in1[b_i] = in1[b_i] + (double)ei[b_i] * 0.0001;
    }

    GEN_Func_Hxdt(b_in1, dv7);
    for (b_i = 0; b_i < 4; b_i++) {
      Hxx[b_i + (i << 2)] = (dv7[b_i] - Hxdt[b_i]) / 0.0001;
    }
  }
}

/*
 * File trailer for Func_Hxx_FD.c
 *
 * [EOF]
 */
