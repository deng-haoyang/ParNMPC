#include "nmpctools.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

void V_write(const char *fileName, const int M, real_T *A)
{
     FILE *fp;
     int i;

     fp=fopen(fileName,"w");
     
     for(i=0;i<M;i++) 
     {
        fprintf(fp,"%f\n",A[i]);
     }
     fclose(fp);
}

void print_matrix(const int M, const int N, real_T *A)
{
    int m,n;
    for(m=0;m<M;m++)
    {
        for(n=0;n<N;n++)
        {
            printf("%f ",A[m*N+n]);
        }
        printf("\n");
    }
    printf("\n");
}

real_T V_max(const int M, real_T *A)
{
    int m;
    real_T maxA = A[0];
    for(m=0;m<M;m++)
    {
        maxA = (maxA>A[m]) ? maxA : A[m];
    }
    return maxA;
}

real_T V_sum(const int M, real_T *A)
{
    int m;
    real_T sumA = 0;
    for(m=0;m<M;m++)
    {
        sumA += A[m];
    }
    return sumA;
}
