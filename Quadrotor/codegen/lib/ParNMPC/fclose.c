/*
 * File: fclose.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 02:13:18
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "ParNMPC.h"
#include "fclose.h"
#include "fileManager.h"
#include <stdio.h>
#include "omp.h"
#include "stdio.h"

/* Function Definitions */

/*
 * Arguments    : double fileID
 * Return Type  : void
 */
void b_fclose(double fileID)
{
  c_fileManager(fileID);
}

/*
 * File trailer for fclose.c
 *
 * [EOF]
 */
