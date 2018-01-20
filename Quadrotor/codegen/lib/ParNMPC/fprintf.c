/*
 * File: fprintf.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 02:13:18
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "ParNMPC.h"
#include "fprintf.h"
#include "fileManager.h"
#include <stdio.h>
#include "omp.h"
#include "stdio.h"

/* Function Definitions */

/*
 * Arguments    : double fileID
 *                const char * varargin_1
 * Return Type  : int
 */
int b_cfprintf(double fileID, const char * varargin_1)
{
  int nbytesint;
  FILE * filestar;
  boolean_T autoflush;
  static const char cfmt[4] = { '%', 's', '	', '\x00' };

  nbytesint = 0;
  b_fileManager(fileID, &filestar, &autoflush);
  if (filestar == NULL) {
  } else {
    nbytesint = fprintf(filestar, cfmt, varargin_1);
    if (autoflush) {
      fflush(filestar);
    }
  }

  return nbytesint;
}

/*
 * Arguments    : double fileID
 *                const char * varargin_1
 * Return Type  : int
 */
int c_cfprintf(double fileID, const char * varargin_1)
{
  int nbytesint;
  FILE * filestar;
  boolean_T autoflush;
  static const char cfmt[4] = { '%', 's', '\x0a', '\x00' };

  nbytesint = 0;
  b_fileManager(fileID, &filestar, &autoflush);
  if (filestar == NULL) {
  } else {
    nbytesint = fprintf(filestar, cfmt, varargin_1);
    if (autoflush) {
      fflush(filestar);
    }
  }

  return nbytesint;
}

/*
 * Arguments    : double fileID
 *                const char varargin_1[3]
 * Return Type  : int
 */
int cfprintf(double fileID, const char varargin_1[3])
{
  int nbytesint;
  FILE * filestar;
  boolean_T autoflush;
  char b_varargin_1[3];
  int i8;
  static const char cfmt[4] = { '%', 's', '	', '\x00' };

  nbytesint = 0;
  b_fileManager(fileID, &filestar, &autoflush);
  if (filestar == NULL) {
  } else {
    for (i8 = 0; i8 < 3; i8++) {
      b_varargin_1[i8] = varargin_1[i8];
    }

    nbytesint = fprintf(filestar, cfmt, b_varargin_1);
    if (autoflush) {
      fflush(filestar);
    }
  }

  return nbytesint;
}

/*
 * Arguments    : double fileID
 *                double varargin_1
 * Return Type  : int
 */
int d_cfprintf(double fileID, double varargin_1)
{
  int nbytesint;
  FILE * filestar;
  boolean_T autoflush;
  static const char cfmt[4] = { '%', 'f', '	', '\x00' };

  nbytesint = 0;
  b_fileManager(fileID, &filestar, &autoflush);
  if (filestar == NULL) {
  } else {
    nbytesint = fprintf(filestar, cfmt, varargin_1);
    if (autoflush) {
      fflush(filestar);
    }
  }

  return nbytesint;
}

/*
 * Arguments    : double fileID
 *                double varargin_1
 * Return Type  : int
 */
int e_cfprintf(double fileID, double varargin_1)
{
  int nbytesint;
  FILE * filestar;
  boolean_T autoflush;
  static const char cfmt[4] = { '%', 'f', '\x0a', '\x00' };

  nbytesint = 0;
  b_fileManager(fileID, &filestar, &autoflush);
  if (filestar == NULL) {
  } else {
    nbytesint = fprintf(filestar, cfmt, varargin_1);
    if (autoflush) {
      fflush(filestar);
    }
  }

  return nbytesint;
}

/*
 * File trailer for fprintf.c
 *
 * [EOF]
 */
