/*
 * File: inv.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 02:06:04
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "ParNMPC.h"
#include "inv.h"
#include <stdio.h>
#include "omp.h"
#include "stdio.h"

/* Function Declarations */
static void b_invNxN(const double x[36], double y[36]);
static void invNxN(const double x[16], double y[16]);

/* Function Definitions */

/*
 * Arguments    : const double x[36]
 *                double y[36]
 * Return Type  : void
 */
static void b_invNxN(const double x[36], double y[36])
{
  double A[36];
  int i6;
  signed char ipiv[6];
  int j;
  signed char p[6];
  int c;
  int jBcol;
  int ix;
  int k;
  double smax;
  double s;
  int kAcol;
  int i;
  for (i6 = 0; i6 < 36; i6++) {
    y[i6] = 0.0;
    A[i6] = x[i6];
  }

  for (i6 = 0; i6 < 6; i6++) {
    ipiv[i6] = (signed char)(1 + i6);
  }

  for (j = 0; j < 5; j++) {
    c = j * 7;
    jBcol = 0;
    ix = c;
    smax = fabs(A[c]);
    for (k = 2; k <= 6 - j; k++) {
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
        for (k = 0; k < 6; k++) {
          smax = A[ix];
          A[ix] = A[jBcol];
          A[jBcol] = smax;
          ix += 6;
          jBcol += 6;
        }
      }

      i6 = (c - j) + 6;
      for (i = c + 1; i + 1 <= i6; i++) {
        A[i] /= A[c];
      }
    }

    jBcol = c;
    kAcol = c + 6;
    for (i = 1; i <= 5 - j; i++) {
      smax = A[kAcol];
      if (A[kAcol] != 0.0) {
        ix = c + 1;
        i6 = (jBcol - j) + 12;
        for (k = 7 + jBcol; k + 1 <= i6; k++) {
          A[k] += A[ix] * -smax;
          ix++;
        }
      }

      kAcol += 6;
      jBcol += 6;
    }
  }

  for (i6 = 0; i6 < 6; i6++) {
    p[i6] = (signed char)(1 + i6);
  }

  for (k = 0; k < 5; k++) {
    if (ipiv[k] > 1 + k) {
      jBcol = p[ipiv[k] - 1];
      p[ipiv[k] - 1] = p[k];
      p[k] = (signed char)jBcol;
    }
  }

  for (k = 0; k < 6; k++) {
    c = p[k] - 1;
    y[k + 6 * (p[k] - 1)] = 1.0;
    for (j = k; j + 1 < 7; j++) {
      if (y[j + 6 * c] != 0.0) {
        for (i = j + 1; i + 1 < 7; i++) {
          y[i + 6 * c] -= y[j + 6 * c] * A[i + 6 * j];
        }
      }
    }
  }

  for (j = 0; j < 6; j++) {
    jBcol = 6 * j;
    for (k = 5; k >= 0; k += -1) {
      kAcol = 6 * k;
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
 * Arguments    : const double x[16]
 *                double y[16]
 * Return Type  : void
 */
static void invNxN(const double x[16], double y[16])
{
  double A[16];
  int i5;
  signed char ipiv[4];
  int j;
  signed char p[4];
  int c;
  int jBcol;
  int ix;
  int k;
  double smax;
  double s;
  int kAcol;
  int i;
  for (i5 = 0; i5 < 16; i5++) {
    y[i5] = 0.0;
    A[i5] = x[i5];
  }

  for (i5 = 0; i5 < 4; i5++) {
    ipiv[i5] = (signed char)(1 + i5);
  }

  for (j = 0; j < 3; j++) {
    c = j * 5;
    jBcol = 0;
    ix = c;
    smax = fabs(A[c]);
    for (k = 2; k <= 4 - j; k++) {
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
        for (k = 0; k < 4; k++) {
          smax = A[ix];
          A[ix] = A[jBcol];
          A[jBcol] = smax;
          ix += 4;
          jBcol += 4;
        }
      }

      i5 = (c - j) + 4;
      for (i = c + 1; i + 1 <= i5; i++) {
        A[i] /= A[c];
      }
    }

    jBcol = c;
    kAcol = c + 4;
    for (i = 1; i <= 3 - j; i++) {
      smax = A[kAcol];
      if (A[kAcol] != 0.0) {
        ix = c + 1;
        i5 = (jBcol - j) + 8;
        for (k = 5 + jBcol; k + 1 <= i5; k++) {
          A[k] += A[ix] * -smax;
          ix++;
        }
      }

      kAcol += 4;
      jBcol += 4;
    }
  }

  for (i5 = 0; i5 < 4; i5++) {
    p[i5] = (signed char)(1 + i5);
  }

  for (k = 0; k < 3; k++) {
    if (ipiv[k] > 1 + k) {
      jBcol = p[ipiv[k] - 1];
      p[ipiv[k] - 1] = p[k];
      p[k] = (signed char)jBcol;
    }
  }

  for (k = 0; k < 4; k++) {
    c = p[k] - 1;
    y[k + ((p[k] - 1) << 2)] = 1.0;
    for (j = k; j + 1 < 5; j++) {
      if (y[j + (c << 2)] != 0.0) {
        for (i = j + 1; i + 1 < 5; i++) {
          y[i + (c << 2)] -= y[j + (c << 2)] * A[i + (j << 2)];
        }
      }
    }
  }

  for (j = 0; j < 4; j++) {
    jBcol = j << 2;
    for (k = 3; k >= 0; k += -1) {
      kAcol = k << 2;
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
 * Arguments    : const double x[36]
 *                double y[36]
 * Return Type  : void
 */
void b_inv(const double x[36], double y[36])
{
  b_invNxN(x, y);
}

/*
 * Arguments    : const double x[16]
 *                double y[16]
 * Return Type  : void
 */
void inv(const double x[16], double y[16])
{
  invNxN(x, y);
}

/*
 * File trailer for inv.c
 *
 * [EOF]
 */
