/*
 * File: fprintf.h
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 01:45:16
 */

#ifndef FPRINTF_H
#define FPRINTF_H

/* Include Files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rtwtypes.h"
#include "omp.h"
#include "ParNMPC_types.h"

/* Function Declarations */
extern int b_cfprintf(double fileID, const char * varargin_1);
extern int c_cfprintf(double fileID, const char * varargin_1);
extern int cfprintf(double fileID, const char varargin_1[3]);
extern int d_cfprintf(double fileID, double varargin_1);
extern int e_cfprintf(double fileID, double varargin_1);

#endif

/*
 * File trailer for fprintf.h
 *
 * [EOF]
 */
