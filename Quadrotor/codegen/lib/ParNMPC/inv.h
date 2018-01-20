/*
 * File: inv.h
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 02:13:18
 */

#ifndef INV_H
#define INV_H

/* Include Files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rt_nonfinite.h"
#include "rtwtypes.h"
#include "omp.h"
#include "ParNMPC_types.h"

/* Function Declarations */
extern void b_inv(const double x[144], double y[144]);
extern void inv(const double x[81], double y[81]);

#endif

/*
 * File trailer for inv.h
 *
 * [EOF]
 */
