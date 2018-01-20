/*
 * File: FuncPlantSim.h
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 02:13:18
 */

#ifndef FUNCPLANTSIM_H
#define FUNCPLANTSIM_H

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
extern void FuncPlantSim(const double u[8], const double x[9], double Ts, double
  xNext[9]);

#endif

/*
 * File trailer for FuncPlantSim.h
 *
 * [EOF]
 */
