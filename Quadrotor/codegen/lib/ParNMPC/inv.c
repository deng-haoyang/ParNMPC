/*
 * File: inv.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 02:13:18
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "ParNMPC.h"
#include "inv.h"
#include <stdio.h>
#include "omp.h"
#include "stdio.h"

/* Function Declarations */
static void b_invNxN(const double x[144], double y[144]);
static void invNxN(const double x[81], double y[81]);

/* Function Definitions */

/*
 * Arguments    : const double x[144]
 *                double y[144]
 * Return Type  : void
 */
static void b_invNxN(const double x[144], double y[144])
{
  double A[144];
  int i6;
  signed char ipiv[12];
  int j;
  signed char p[12];
  int c;
  int jBcol;
  int ix;
  int k;
  double smax;
  double s;
  int kAcol;
  int i;
  for (i6 = 0; i6 < 144; i6++) {
    y[i6] = 0.0;
    A[i6] = x[i6];
  }

  for (i6 = 0; i6 < 12; i6++) {
    ipiv[i6] = (signed char)(1 + i6);
  }

  for (j = 0; j < 11; j++) {
    c = j * 13;
    jBcol = 0;
    ix = c;
    smax = fabs(A[c]);
    for (k = 2; k <= 12 - j; k++) {
      ix++;
      s = fabs(A[ix]);
      if (s > smax) {
        jBcol = k - 1;
        smax = s;
      }
    }

    if (A[c + jBcol] != 0.0) {
      if (jBcol != 0) {
        ipiv[j] = (signed char)((j + jBcol) + 1);
        ix = j;
        jBcol += j;
        for (k = 0; k < 12; k++) {
          smax = A[ix];
          A[ix] = A[jBcol];
          A[jBcol] = smax;
          ix += 12;
          jBcol += 12;
        }
      }

      i6 = (c - j) + 12;
      for (i = c + 1; i + 1 <= i6; i++) {
        A[i] /= A[c];
      }
    }

    jBcol = c;
    kAcol = c + 12;
    for (i = 1; i <= 11 - j; i++) {
      smax = A[kAcol];
      if (A[kAcol] != 0.0) {
        ix = c + 1;
        i6 = (jBcol - j) + 24;
        for (k = 13 + jBcol; k + 1 <= i6; k++) {
          A[k] += A[ix] * -smax;
          ix++;
        }
      }

      kAcol += 12;
      jBcol += 12;
    }
  }

  for (i6 = 0; i6 < 12; i6++) {
    p[i6] = (signed char)(1 + i6);
  }

  for (k = 0; k < 11; k++) {
    if (ipiv[k] > 1 + k) {
      jBcol = p[ipiv[k] - 1];
      p[ipiv[k] - 1] = p[k];
      p[k] = (signed char)jBcol;
    }
  }

  for (k = 0; k < 12; k++) {
    c = p[k] - 1;
    y[k + 12 * (p[k] - 1)] = 1.0;
    for (j = k; j + 1 < 13; j++) {
      if (y[j + 12 * c] != 0.0) {
        for (i = j + 1; i + 1 < 13; i++) {
          y[i + 12 * c] -= y[j + 12 * c] * A[i + 12 * j];
        }
      }
    }
  }

  for (j = 0; j < 12; j++) {
    jBcol = 12 * j;
    for (k = 11; k >= 0; k += -1) {
      kAcol = 12 * k;
      if (y[k + jBcol] != 0.0) {
        y[k + jBcol] /= A[k + kAcol];
        for (i = 0; i + 1 <= k; i++) {
          y[i + jBcol] -= y[k + jBcol] * A[i + kAcol];
        }
      }
    }
  }
}

/*
 * Arguments    : const double x[81]
 *                double y[81]
 * Return Type  : void
 */
static void invNxN(const double x[81], double y[81])
{
  double A[81];
  int i5;
  signed char ipiv[9];
  int j;
  signed char p[9];
  int c;
  int jBcol;
  int ix;
  int k;
  double smax;
  double s;
  int kAcol;
  int i;
  for (i5 = 0; i5 < 81; i5++) {
    y[i5] = 0.0;
    A[i5] = x[i5];
  }

  for (i5 = 0; i5 < 9; i5++) {
    ipiv[i5] = (signed char)(1 + i5);
  }

  for (j = 0; j < 8; j++) {
    c = j * 10;
    jBcol = 0;
    ix = c;
    smax = fabs(A[c]);
    for (k = 2; k <= 9 - j; k++) {
      ix++;
      s = fabs(A[ix]);
      if (s > smax) {
        jBcol = k - 1;
        smax = s;
      }
    }

    if (A[c + jBcol] != 0.0) {
      if (jBcol != 0) {
        ipiv[j] = (signed char)((j + jBcol) + 1);
        ix = j;
        jBcol += j;
        for (k = 0; k < 9; k++) {
          smax = A[ix];
          A[ix] = A[jBcol];
          A[jBcol] = smax;
          ix += 9;
          jBcol += 9;
        }
      }

      i5 = (c - j) + 9;
      for (i = c + 1; i + 1 <= i5; i++) {
        A[i] /= A[c];
      }
    }

    jBcol = c;
    kAcol = c + 9;
    for (i = 1; i <= 8 - j; i++) {
      smax = A[kAcol];
      if (A[kAcol] != 0.0) {
        ix = c + 1;
        i5 = (jBcol - j) + 18;
        for (k = 10 + jBcol; k + 1 <= i5; k++) {
          A[k] += A[ix] * -smax;
          ix++;
        }
      }

      kAcol += 9;
      jBcol += 9;
    }
  }

  for (i5 = 0; i5 < 9; i5++) {
    p[i5] = (signed char)(1 + i5);
  }

  for (k = 0; k < 8; k++) {
    if (ipiv[k] > 1 + k) {
      jBcol = p[ipiv[k] - 1];
      p[ipiv[k] - 1] = p[k];
      p[k] = (signed char)jBcol;
    }
  }

  for (k = 0; k < 9; k++) {
    c = p[k] - 1;
    y[k + 9 * (p[k] - 1)] = 1.0;
    for (j = k; j + 1 < 10; j++) {
      if (y[j + 9 * c] != 0.0) {
        for (i = j + 1; i + 1 < 10; i++) {
          y[i + 9 * c] -= y[j + 9 * c] * A[i + 9 * j];
        }
      }
    }
  }

  for (j = 0; j < 9; j++) {
    jBcol = 9 * j;
    for (k = 8; k >= 0; k += -1) {
      kAcol = 9 * k;
      if (y[k + jBcol] != 0.0) {
        y[k + jBcol] /= A[k + kAcol];
        for (i = 0; i + 1 <= k; i++) {
          y[i + jBcol] -= y[k + jBcol] * A[i + kAcol];
        }
      }
    }
  }
}

/*
 * Arguments    : const double x[144]
 *                double y[144]
 * Return Type  : void
 */
void b_inv(const double x[144], double y[144])
{
  b_invNxN(x, y);
}

/*
 * Arguments    : const double x[81]
 *                double y[81]
 * Return Type  : void
 */
void inv(const double x[81], double y[81])
{
  invNxN(x, y);
}

/*
 * File trailer for inv.c
 *
 * [EOF]
 */
