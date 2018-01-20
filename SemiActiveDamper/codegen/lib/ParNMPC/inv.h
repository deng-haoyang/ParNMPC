/*
 * File: inv.h
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 01:45:16
 */

#ifndef INV_H
#define INV_H

/* Include Files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rtwtypes.h"
#include "omp.h"
#include "ParNMPC_types.h"

/* Function Declarations */
extern void b_inv(const double x[9], double y[9]);
extern void inv(const double x[4], double y[4]);

#endif

/*
 * File trailer for inv.h
 *
 * [EOF]
 */
