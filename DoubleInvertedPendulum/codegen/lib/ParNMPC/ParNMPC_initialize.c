/*
 * File: ParNMPC_initialize.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 01:36:29
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "ParNMPC.h"
#include "ParNMPC_initialize.h"
#include "ParNMPC_rtwutil.h"
#include "fileManager.h"
#include "ParNMPC_data.h"
#include <stdio.h>
#include "omp.h"
#include "stdio.h"

/* Function Definitions */

/*
 * Arguments    : void
 * Return Type  : void
 */
void ParNMPC_initialize(void)
{
  rt_InitInfAndNaN(8U);
  omp_init_nest_lock(&emlrtNestLockGlobal);
  filedata_init();
  emlrtInitThreadStackData();
}

/*
 * File trailer for ParNMPC_initialize.c
 *
 * [EOF]
 */
