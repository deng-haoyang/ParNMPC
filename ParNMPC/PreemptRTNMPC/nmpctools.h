#ifndef NMPCTOOLS_H_
#define NMPCTOOLS_H_

#include "nmpc.h"

void print_matrix(const int M, const int N, real_T * A);
void V_write(const char *fileName, const int M, real_T *A);
real_T V_max(const int M, real_T *A);
real_T V_sum(const int M, real_T *A);

#endif // NMPCTOOLS_H_