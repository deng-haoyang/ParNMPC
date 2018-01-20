/*
 * File: ParNMPC_rtwutil.h
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 01:36:29
 */

#ifndef PARNMPC_RTWUTIL_H
#define PARNMPC_RTWUTIL_H

/* Include Files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rtwtypes.h"
#include "omp.h"
#include "ParNMPC_types.h"

/* Function Declarations */
extern void emlrtFreeThreadStackData(void);
extern ParNMPCTLS *emlrtGetThreadStackData(void);
extern void emlrtInitThreadStackData(void);

#endif

/*
 * File trailer for ParNMPC_rtwutil.h
 *
 * [EOF]
 */
