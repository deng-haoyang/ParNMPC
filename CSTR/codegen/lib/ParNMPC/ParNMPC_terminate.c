/*
 * File: ParNMPC_terminate.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 02:06:04
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "ParNMPC.h"
#include "ParNMPC_terminate.h"
#include "ParNMPC_data.h"
#include <stdio.h>
#include "omp.h"
#include "stdio.h"

/* Function Definitions */

/*
 * Arguments    : void
 * Return Type  : void
 */
void ParNMPC_terminate(void)
{
  omp_destroy_nest_lock(&emlrtNestLockGlobal);
}

/*
 * File trailer for ParNMPC_terminate.c
 *
 * [EOF]
 */
