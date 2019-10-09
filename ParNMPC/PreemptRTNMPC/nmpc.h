#ifndef NMPC_H_
#define NMPC_H_

#include "nmpcconstants.h"
#include "nmpcthreads.h" 
#include "nmpctools.h"

typedef struct s_solverOutput
{
    /* number of iterations */
    int iterations; 
    
    char exitFlag;

    /* cost */
    real_T cost;

    /* cost of the barrier function*/
    real_T barrier;

    /* total computation time */
    real_T cpuTime;

    /* KKT error */
    real_T xEqViolation; 
    real_T CEqViolation; 
    real_T firstOrderOpt; 

    /* optimization variables */
    real_T *lambda;
    real_T *mu;
    real_T *u; 
    real_T *x;
    real_T *z; 
    real_T *LAMDA;

    /* for debugging */ 
    real_T tCoarseUpdate, tBackwardSerial, tBackwardParallel, tForwardSerial, tForwardParallel, tKKTError;

}SolverOutput; 

void  nmpc_init(void);
void  nmpc_exit(void);
void  nmpc_solve(real_T *x0, real_T *p, SolverOutput *solverOutput);

#endif // NMPC_H_
