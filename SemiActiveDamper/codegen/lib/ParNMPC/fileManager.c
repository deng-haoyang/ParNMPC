/*
 * File: fileManager.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 01:45:16
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "ParNMPC.h"
#include "fileManager.h"
#include <stdio.h>
#include "omp.h"
#include "stdio.h"

/* Variable Definitions */
static FILE * eml_openfiles[20];
static boolean_T eml_autoflush[20];

/* Function Declarations */
static FILE * d_fileManager(signed char varargin_1);
static signed char filedata(void);
static double rt_roundd_snf(double u);

/* Function Definitions */

/*
 * Arguments    : signed char varargin_1
 * Return Type  : FILE *
 */
static FILE * d_fileManager(signed char varargin_1)
{
  FILE * f;
  signed char fileid;
  fileid = varargin_1;
  if ((varargin_1 > 22) || (varargin_1 < 0)) {
    fileid = -1;
  }

  if (fileid >= 3) {
    f = eml_openfiles[fileid - 3];
  } else if (fileid == 0) {
    f = stdin;
  } else if (fileid == 1) {
    f = stdout;
  } else if (fileid == 2) {
    f = stderr;
  } else {
    f = NULL;
  }

  return f;
}

/*
 * Arguments    : void
 * Return Type  : signed char
 */
static signed char filedata(void)
{
  signed char f;
  signed char k;
  boolean_T exitg1;
  f = 0;
  k = 1;
  exitg1 = false;
  while ((!exitg1) && (k < 21)) {
    if (eml_openfiles[k - 1] == NULL) {
      f = k;
      exitg1 = true;
    } else {
      k++;
    }
  }

  return f;
}

/*
 * Arguments    : double u
 * Return Type  : double
 */
static double rt_roundd_snf(double u)
{
  double y;
  if (fabs(u) < 4.503599627370496E+15) {
    if (u >= 0.5) {
      y = floor(u + 0.5);
    } else if (u > -0.5) {
      y = u * 0.0;
    } else {
      y = ceil(u - 0.5);
    }
  } else {
    y = u;
  }

  return y;
}

/*
 * Arguments    : double varargin_1
 *                FILE * *f
 *                boolean_T *a
 * Return Type  : void
 */
void b_fileManager(double varargin_1, FILE * *f, boolean_T *a)
{
  signed char fileid;
  fileid = (signed char)rt_roundd_snf(varargin_1);
  if ((fileid > 22) || (fileid < 0) || (varargin_1 != fileid)) {
    fileid = -1;
  }

  if (fileid >= 3) {
    fileid = (signed char)(fileid - 2);
    *f = eml_openfiles[fileid - 1];
    *a = eml_autoflush[fileid - 1];
  } else if (fileid == 0) {
    *f = stdin;
    *a = true;
  } else if (fileid == 1) {
    *f = stdout;
    *a = true;
  } else if (fileid == 2) {
    *f = stderr;
    *a = true;
  } else {
    *f = NULL;
    *a = true;
  }
}

/*
 * Arguments    : double varargin_1
 * Return Type  : int
 */
int c_fileManager(double varargin_1)
{
  int f;
  signed char fileid;
  FILE * filestar;
  int cst;
  f = -1;
  fileid = (signed char)rt_roundd_snf(varargin_1);
  if ((fileid > 22) || (fileid < 0) || (varargin_1 != fileid)) {
    fileid = -1;
  }

  filestar = d_fileManager(fileid);
  if ((filestar == NULL) || (fileid < 3)) {
  } else {
    cst = fclose(filestar);
    if (cst == 0) {
      f = 0;
      fileid = (signed char)(fileid - 2);
      eml_openfiles[fileid - 1] = NULL;
      eml_autoflush[fileid - 1] = true;
    }
  }

  return f;
}

/*
 * Arguments    : void
 * Return Type  : signed char
 */
signed char fileManager(void)
{
  signed char f;
  signed char j;
  char cv2[16];
  int i5;
  char cv3[3];
  static const char cv4[16] = { 'G', 'E', 'N', '_', 'l', 'o', 'g', '_', 'r', 'e',
    'c', '.', 't', 'x', 't', '\x00' };

  FILE * filestar;
  static const char cv5[3] = { 'w', 'b', '\x00' };

  f = -1;
  j = filedata();
  if (j < 1) {
  } else {
    for (i5 = 0; i5 < 16; i5++) {
      cv2[i5] = cv4[i5];
    }

    for (i5 = 0; i5 < 3; i5++) {
      cv3[i5] = cv5[i5];
    }

    filestar = fopen(cv2, cv3);
    if (filestar != NULL) {
      eml_openfiles[j - 1] = filestar;
      eml_autoflush[j - 1] = true;
      f = (signed char)(j + 2);
    }
  }

  return f;
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void filedata_init(void)
{
  FILE * a;
  int i;
  a = NULL;
  for (i = 0; i < 20; i++) {
    eml_autoflush[i] = false;
    eml_openfiles[i] = a;
  }
}

/*
 * File trailer for fileManager.c
 *
 * [EOF]
 */
