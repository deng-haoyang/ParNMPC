/*
 * File: ParNMPC_rtwutil.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 01:36:29
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "ParNMPC.h"
#include "ParNMPC_rtwutil.h"
#include <stdio.h>
#include "omp.h"
#include "stdio.h"

/* Variable Definitions */
static ParNMPCTLS *ParNMPCTLSGlobal;

#pragma omp threadprivate (ParNMPCTLSGlobal)

/* Function Definitions */

/*
 * Arguments    : void
 * Return Type  : void
 */
void emlrtFreeThreadStackData(void)
{
  int i;

#pragma omp parallel for schedule(static)\
 num_threads(omp_get_max_threads())

  for (i = 1; i <= omp_get_max_threads(); i++) {
    free(ParNMPCTLSGlobal);
  }
}

/*
 * Arguments    : void
 * Return Type  : ParNMPCTLS *
 */
ParNMPCTLS *emlrtGetThreadStackData(void)
{
  return ParNMPCTLSGlobal;
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void emlrtInitThreadStackData(void)
{
  int i;

#pragma omp parallel for schedule(static)\
 num_threads(omp_get_max_threads())

  for (i = 1; i <= omp_get_max_threads(); i++) {
    ParNMPCTLSGlobal = (ParNMPCTLS *)malloc(1U * sizeof(ParNMPCTLS));
  }
}

/*
 * File trailer for ParNMPC_rtwutil.c
 *
 * [EOF]
 */
