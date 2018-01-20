/*
 * File: FuncPlantSim.h
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 01:45:16
 */

#ifndef FUNCPLANTSIM_H
#define FUNCPLANTSIM_H

/* Include Files */
#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>
#include "rtwtypes.h"
#include "omp.h"
#include "ParNMPC_types.h"

/* Function Declarations */
extern void FuncPlantSim(const double u[2], const double x[2], double Ts, double
  xNext[2]);

#endif

/*
 * File trailer for FuncPlantSim.h
 *
 * [EOF]
 */
