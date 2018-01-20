/*
 * File: Func_Hxx_FD.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 01:36:29
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
 * Arguments    : const double in1[15]
 *                const double in2[8]
 *                double Hxx[36]
 * Return Type  : void
 */
void Func_Hxx_FD(const double in1[15], const double in2[8], double Hxx[36])
{
  double Hxdt[6];
  int i;
  signed char ei[15];
  int b_i;
  double b_in1[15];
  double dv7[6];
  GEN_Func_Hxdt(in1, in2, Hxdt);
  for (i = 0; i < 6; i++) {
    for (b_i = 0; b_i < 15; b_i++) {
      ei[b_i] = 0;
    }

    ei[9 + i] = 1;
    for (b_i = 0; b_i < 15; b_i++) {
      b_in1[b_i] = in1[b_i] + (double)ei[b_i] * 0.0001;
    }

    GEN_Func_Hxdt(b_in1, in2, dv7);
    for (b_i = 0; b_i < 6; b_i++) {
      Hxx[b_i + 6 * i] = (dv7[b_i] - Hxdt[b_i]) / 0.0001;
    }
  }
}

/*
 * File trailer for Func_Hxx_FD.c
 *
 * [EOF]
 */
