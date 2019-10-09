#include <time.h>
#include <sys/mman.h>
#include <string.h>
#include <stdio.h>

#include <unistd.h>

#include "nmpc.h" 
#include "initial_guess_func.h"  
#include "coarse_update_func.h" 
#include "forward_correction_parallel_func.h" 
#include "KKT_error_func.h" 

/* global variables */
// parallel computing parameters
const int c_affinity[c_DOP] = AFFINITY; 
const int c_priority[c_DOP] = PRIORITY; 
const int c_schedMethod     = SCHED_METHOD; 

// optimization variables
real_T g_lambda[c_N][c_lambdaDim];  
real_T g_mu[c_N][c_muDim];  
real_T g_u[c_N][c_uDim];  
real_T g_x[c_N][c_xDim];  
real_T g_z[c_N][c_zDim];
real_T g_LAMBDA[c_N][c_xDim][c_xDim];//lambda2F

// optimization parameters
real_T       g_x0[c_xDim];
real_T       g_p[c_N][c_pDim]; 
real_T       g_rho = c_RHO;

// outputs
real_T g_KKTxEq[c_N];
real_T g_KKTC[c_N];
real_T g_KKTHu[c_N];
real_T g_KKTlambdaEq[c_N];
real_T g_L[c_N];
real_T g_LB[c_N];
char g_exitFlag;
real_T g_iter;
real_T g_maxKKTxEq;
real_T g_maxKKTC;
real_T g_firstOrderOpt;

// backup for line search
static real_T g_lambdaBkup[c_N][c_lambdaDim];  
static real_T g_muBkup[c_N][c_muDim];  
static real_T g_uBkup[c_N][c_uDim];  
static real_T g_xBkup[c_N][c_xDim];  
static real_T g_zBkup[c_N][c_zDim];

static real_T g_xPrev[c_N][c_xDim];
static real_T g_lambdaNext[c_N][c_lambdaDim];
static real_T g_dx[c_N][c_xDim];
static real_T g_dlambda[c_N][c_lambdaDim];
static real_T g_stepSizeZ[c_N];
static real_T g_stepSizeG[c_N];

// sensitivities
static real_T g_muu2F[c_N][c_xDim][c_muDim+c_uDim]; 
static real_T g_muu2Lambda[c_N][c_xDim][c_muDim+c_uDim]; 
static real_T g_lambda2Lambda[c_N][c_lambdaDim][c_lambdaDim]; 
static real_T g_x2Lambda[c_N][c_lambdaDim][c_xDim]; 
static real_T g_x2F[c_N][c_xDim][c_xDim]; 
static const real_T LAMBDA_N[c_xDim][c_xDim] = {0};

// parallel tasks in search direction
static ParallelTask taskAllParallel;
static real_T tCoarseUpdate, tBackwardSerial, tBackwardParallel, tForwardSerial, tForwardParallel, tKKTError;


// spin locks
static volatile pthread_spinlock_t spinlockParallelStart[c_DOP-1];
static volatile pthread_spinlock_t spinlockParallelCoarse[c_DOP-1];
static volatile pthread_spinlock_t spinlockParallelBackward[c_DOP-1];
static volatile pthread_spinlock_t spinlockParallelForward[c_DOP-1];
static volatile pthread_spinlock_t spinlockParallelEnd[c_DOP-1];
static volatile pthread_spinlock_t spinlockParallelKKTError[c_DOP-1];
static volatile pthread_spinlock_t spinlockSerialBackward[c_DOP-1];
static volatile pthread_spinlock_t spinlockSerialForward[c_DOP-1];
static volatile pthread_spinlock_t spinlockSerialLineSearch[c_DOP-1];


/* function declarations */
static void search_direction_init(void); 
static void search_direction(void); 
static void search_direction_free(void); 
static void *coarse_update_parallel(long *iThread);
static void *backward_correction_parallel(long *iThread);
static void *forward_correction_parallel(long *iThread);
static void *KKT_error_parallel(long *iThread);
static void backward_correction_serial(void);
static void forward_correction_serial(void);
static void feasibility_search(void);

static void initial_guess(void);

static void MV_mulTNp(const int M, const int K,  const real_T *A,  const real_T *B, real_T *C);
static void MM_weightingadd(const int M, const int N, real_T alpha, real_T beta, real_T *A, real_T *B);
static void MV_muladdTNm(const int M, const int K, const  real_T *A, const  real_T *B, real_T *C);
static void VV_minus(const int M, real_T *A, real_T *B);


void nmpc_init()
{
        #ifdef LOCK_MEMORY_ALL
        if(mlockall(MCL_CURRENT|MCL_FUTURE) == -1) 
        {
                printf("mlockall failed\n");
                exit(-2);
        }
        #endif

        /* init optimization variables */
        initial_guess();

        /* init spin locks */
        search_direction_init();
}

void nmpc_solve(real_T *x0, real_T *p, SolverOutput* solverOutput)
{
        int i;
        real_T cpuTime;
        struct timespec tStart,tEnd;
        clock_gettime(CLOCK_MONOTONIC,&tStart);

        memcpy(&g_x0[0],        x0,       sizeof(real_T)*c_xDim); 
        memcpy(&g_p[0][0],      p,        sizeof(real_T)*c_N*c_pDim); 
        /* initialize variables */
        g_exitFlag = 2;
        g_iter = c_MAX_ITER;
        tCoarseUpdate = 0;
        tBackwardSerial = 0;
        tBackwardParallel = 0;
        tForwardSerial = 0;
        tForwardParallel = 0;
        tKKTError = 0;
        
        for(i = 0; i < c_MAX_ITER; i++)
        {
                search_direction();// lock_parallel_search_direction() inside

                g_maxKKTxEq = V_max(c_N,g_KKTxEq);
                g_maxKKTC   = V_max(c_N,g_KKTC);
                // TODO 
                g_firstOrderOpt = V_max(c_N,g_KKTHu) + V_max(c_N,g_KKTlambdaEq);
                if(g_maxKKTxEq<=c_XEQ_TOL && g_maxKKTC <= c_CEQ_TOL && g_firstOrderOpt <= c_OPT_TOL)
                {
                        g_iter =    i+1;
                        g_exitFlag = 1;
                        break;
                }
        }

        solverOutput->iterations   = g_iter;
        solverOutput->exitFlag     = g_exitFlag;
        solverOutput->cost         = V_sum(c_N,g_L);
        solverOutput->barrier      = V_sum(c_N,g_LB);

        solverOutput->xEqViolation = g_maxKKTxEq;
        solverOutput->CEqViolation = g_maxKKTC; 
        solverOutput->firstOrderOpt= g_firstOrderOpt;

        solverOutput->lambda = &g_lambda[0][0];
        solverOutput->mu     = &g_mu[0][0];
        solverOutput->u      = &g_u[0][0];
        solverOutput->x      = &g_x[0][0];
        solverOutput->z      = &g_z[0][0];
        solverOutput->LAMDA  = &g_LAMBDA[0][0][0];

        solverOutput->tCoarseUpdate = tCoarseUpdate;
        solverOutput->tBackwardSerial = tBackwardSerial;
        solverOutput->tBackwardParallel = tBackwardParallel;
        solverOutput->tForwardSerial = tForwardSerial;
        solverOutput->tForwardParallel = tForwardParallel;
        solverOutput->tKKTError = tKKTError;

        clock_gettime(CLOCK_MONOTONIC,&tEnd);
        cpuTime = (tEnd.tv_sec - tStart.tv_sec)*1000000 + (tEnd.tv_nsec - tStart.tv_nsec) / 1000.0;
        solverOutput->cpuTime = cpuTime;
}

void nmpc_exit(void)
{
        search_direction_free();
}

static void initial_guess(void)
{
        #if(c_zDim == 0)
                #if(c_muDim == 0)
                        initial_guess_func(&g_lambda[0][0], &g_u[0][0], &g_x[0][0], &g_LAMBDA[0][0][0]);
                #else
                        initial_guess_func(&g_lambda[0][0], &g_mu[0][0], &g_u[0][0], &g_x[0][0],  &g_LAMBDA[0][0][0]);
                #endif
        #else
                #if(c_muDim == 0)
                        initial_guess_func(&g_lambda[0][0], &g_u[0][0], &g_x[0][0], &g_z[0][0], &g_LAMBDA[0][0][0]);
                #else
                        initial_guess_func(&g_lambda[0][0], &g_mu[0][0], &g_u[0][0], &g_x[0][0], &g_z[0][0],  &g_LAMBDA[0][0][0]);
                #endif
        #endif
}

static void *all_parallel_tasks_init(long *iThread)
{
        int iTrd = *iThread;
        
        pthread_spin_init(&spinlockSerialBackward[iTrd],  PTHREAD_PROCESS_SHARED);
        pthread_spin_init(&spinlockSerialForward[iTrd],   PTHREAD_PROCESS_SHARED);
        pthread_spin_init(&spinlockSerialLineSearch[iTrd],PTHREAD_PROCESS_SHARED);
        pthread_spin_init(&spinlockParallelEnd[iTrd],     PTHREAD_PROCESS_SHARED);

        pthread_spin_lock(&spinlockSerialBackward[iTrd]);
        pthread_spin_lock(&spinlockSerialForward[iTrd]);
        pthread_spin_lock(&spinlockSerialLineSearch[iTrd]);
        return NULL;
}


static void *all_parallel_tasks(long *iThread)
{

        long iTrd = *iThread;

        pthread_spin_lock(&spinlockParallelStart[iTrd]);
        pthread_spin_unlock(&spinlockParallelStart[iTrd]);

        pthread_spin_lock(&spinlockParallelEnd[iTrd]);

        /* coarse update */
        pthread_spin_lock(&spinlockParallelCoarse[iTrd]);
        pthread_spin_unlock(&spinlockParallelCoarse[iTrd]);
        coarse_update_parallel(iThread);

        // ready to run backward_correction_serial
        pthread_spin_unlock(&spinlockSerialBackward[iTrd]);


        /* backward */
        pthread_spin_lock(&spinlockParallelBackward[iTrd]);
        pthread_spin_unlock(&spinlockParallelBackward[iTrd]);
        backward_correction_parallel(iThread);

        // ready to run forward_correction_serial
        pthread_spin_unlock(&spinlockSerialForward[iTrd]);

        /* forward */
        pthread_spin_lock(&spinlockParallelForward[iTrd]);
        pthread_spin_unlock(&spinlockParallelForward[iTrd]);
        forward_correction_parallel(iThread);

        // ready to run feasibility_search
        pthread_spin_unlock(&spinlockSerialLineSearch[iTrd]);
        
        // printf("%ld Debug 225235\n",iTrd);
        pthread_spin_lock(&spinlockParallelKKTError[iTrd]);
        pthread_spin_unlock(&spinlockParallelKKTError[iTrd]);
        #ifdef CHECK_KKT_ERROR_AFTER_ITERATION
        /* KKT error */
        KKT_error_parallel(iThread);
        #endif

        // recyle serial
        pthread_spin_lock(&spinlockSerialLineSearch[iTrd]);
        pthread_spin_lock(&spinlockSerialBackward[iTrd]);
        pthread_spin_lock(&spinlockSerialForward[iTrd]);

        pthread_spin_unlock(&spinlockParallelEnd[iTrd]);

        return NULL;
}


static void search_direction(void)
{
        struct timespec t0,t1;
        real_T elapsed;
        
        int i = 0;
        long int mainTrd = c_DOP-1;

        /* init */
        // xPrev, lambdaNext, LAMBDA
        memcpy(&g_xPrev[0][0],g_x0,sizeof(real_T)*c_xDim);
        for (i=1; i<c_DOP; i++)
        {
                memcpy(&g_xPrev[i*c_SEG_SIZE][0],        &g_x[i*c_SEG_SIZE-1][0],       sizeof(real_T)*c_xDim); 
                memcpy(&g_lambdaNext[i*c_SEG_SIZE-1][0], &g_lambda[i*c_SEG_SIZE][0],    sizeof(real_T)*c_lambdaDim); 
                memcpy(&g_LAMBDA[i*c_SEG_SIZE-1][0][0],  &g_LAMBDA[i*c_SEG_SIZE][0][0], sizeof(real_T)*c_xDim*c_xDim);
        }
        // clear LAMBDA terminal
        memcpy(&g_LAMBDA[c_N-1][0][0],  &LAMBDA_N[0][0], sizeof(real_T)*c_xDim*c_xDim);

        // backup variables
        memcpy(&g_lambdaBkup[0][0],&g_lambda[0][0],sizeof(real_T)*c_N*c_lambdaDim);
        memcpy(&g_muBkup[0][0],&g_mu[0][0],sizeof(real_T)*c_N*c_muDim);
        memcpy(&g_uBkup[0][0],&g_u[0][0],sizeof(real_T)*c_N*c_uDim);
        memcpy(&g_xBkup[0][0],&g_x[0][0],sizeof(real_T)*c_N*c_xDim);
        memcpy(&g_zBkup[0][0],&g_z[0][0],sizeof(real_T)*c_N*c_zDim);
        
        // ready to start parallel tasks
        for (i=0; i<c_DOP-1; i++)
        {
                pthread_spin_unlock(&spinlockParallelStart[i]);
        }

        clock_gettime(CLOCK_MONOTONIC,&t0);
        // ready to run coarse update parallel
        for (i=0; i<c_DOP-1; i++)
        {
                pthread_spin_unlock(&spinlockParallelCoarse[i]);
        }
        /* coarse update */
        coarse_update_parallel(&mainTrd);
        
        /* backward correction serial */
        for (i=0; i<c_DOP-1; i++)
        {
                pthread_spin_lock(&spinlockSerialBackward[i]);
        }
        clock_gettime(CLOCK_MONOTONIC,&t1);
        elapsed = (t1.tv_sec - t0.tv_sec)*1000000 + (t1.tv_nsec - t0.tv_nsec) / 1000.0;
        tCoarseUpdate +=  elapsed;

        backward_correction_serial();

        clock_gettime(CLOCK_MONOTONIC,&t0);
        elapsed = (t0.tv_sec - t1.tv_sec)*1000000 + (t0.tv_nsec - t1.tv_nsec) / 1000.0;
        tBackwardSerial +=  elapsed;

        for (i=0; i<c_DOP-1; i++)
        {
                pthread_spin_unlock(&spinlockSerialBackward[i]);
                pthread_spin_lock(&spinlockParallelStart[i]);   // lock start
        }

        // ready to run backward_correction parallel
        for (i=0; i<c_DOP-1; i++)
        {
                pthread_spin_unlock(&spinlockParallelBackward[i]);
        }
        /* backward correction parallel */
        backward_correction_parallel(&mainTrd);

        /* forward correction serial */
        for (i=0; i<c_DOP-1; i++)
                pthread_spin_lock(&spinlockSerialForward[i]);

        clock_gettime(CLOCK_MONOTONIC,&t1);
        elapsed = (t1.tv_sec - t0.tv_sec)*1000000 + (t1.tv_nsec - t0.tv_nsec) / 1000.0;
        tBackwardParallel += elapsed;

        forward_correction_serial();

        clock_gettime(CLOCK_MONOTONIC,&t0);
        elapsed = (t0.tv_sec - t1.tv_sec)*1000000 + (t0.tv_nsec - t1.tv_nsec) / 1000.0;
        tForwardSerial += elapsed;

        for (i=0; i<c_DOP-1; i++)
                pthread_spin_unlock(&spinlockSerialForward[i]);

        // ready to run forward_correction parallel
        for (i=0; i<c_DOP-1; i++)
                pthread_spin_unlock(&spinlockParallelForward[i]);

        /* forward correction parallel */
        forward_correction_parallel(&mainTrd);

        /* line search */
        for (i=0; i<c_DOP-1; i++)
        {
                pthread_spin_lock(&spinlockSerialLineSearch[i]);
                pthread_spin_unlock(&spinlockSerialLineSearch[i]);
        }

        clock_gettime(CLOCK_MONOTONIC,&t1);
        elapsed = (t1.tv_sec - t0.tv_sec)*1000000 + (t1.tv_nsec - t0.tv_nsec) / 1000.0;
        tForwardParallel += elapsed;

        feasibility_search();

        // ready to run KKT error
        for (i=0; i<c_DOP-1; i++)
                pthread_spin_unlock(&spinlockParallelKKTError[i]);
        #ifdef CHECK_KKT_ERROR_AFTER_ITERATION
        // xPrev, lambdaNext
        memcpy(&g_xPrev[0][0],g_x0,sizeof(real_T)*c_xDim);
        for (i=1; i<c_DOP; i++)
        {
                memcpy(&g_xPrev[i*c_SEG_SIZE][0],        &g_x[i*c_SEG_SIZE-1][0],       sizeof(real_T)*c_xDim); 
                memcpy(&g_lambdaNext[i*c_SEG_SIZE-1][0], &g_lambda[i*c_SEG_SIZE][0],    sizeof(real_T)*c_lambdaDim); 
        }
        /* KKT error */
        KKT_error_parallel(&mainTrd);
        #endif // CHECK_KKT_ERROR_AFTER_ITERATION

        // recyle parallel 
        for (i=0; i<c_DOP-1; i++)
        {
                pthread_spin_lock(&spinlockParallelEnd[i]);
                pthread_spin_unlock(&spinlockParallelEnd[i]);
        }
        clock_gettime(CLOCK_MONOTONIC,&t0);
        elapsed = (t0.tv_sec - t1.tv_sec)*1000000 + (t0.tv_nsec - t1.tv_nsec) / 1000.0;
        tKKTError += elapsed;

        for (i=0; i<c_DOP-1; i++)
        {
                pthread_spin_lock(&spinlockParallelCoarse[i]);
                pthread_spin_lock(&spinlockParallelBackward[i]);
                pthread_spin_lock(&spinlockParallelForward[i]);
                pthread_spin_lock(&spinlockParallelKKTError[i]);
        }
}

static void search_direction_free()
{
        int i;
        initial_guess_func_terminate();
        coarse_update_func_terminate();
        forward_correction_parallel_func_terminate();
        KKT_error_func_terminate();
        free_parallel_task(&taskAllParallel);

        for(i=0; i<c_DOP-1; i++)
        {
                pthread_spin_destroy(&spinlockParallelStart[i]);
                pthread_spin_destroy(&spinlockParallelCoarse[i]);
                pthread_spin_destroy(&spinlockParallelBackward[i]);
                pthread_spin_destroy(&spinlockParallelForward[i]);
                pthread_spin_destroy(&spinlockParallelKKTError[i]);
                pthread_spin_destroy(&spinlockSerialBackward[i]);
                pthread_spin_destroy(&spinlockSerialForward[i]);
                pthread_spin_destroy(&spinlockSerialLineSearch[i]);
        }
}

static void search_direction_init()
{
        // struct timespec delay;
        int i;
        for(i=0; i<c_DOP-1; i++)
        {
                pthread_spin_init(&spinlockParallelStart[i],PTHREAD_PROCESS_SHARED);
                pthread_spin_init(&spinlockParallelCoarse[i],PTHREAD_PROCESS_SHARED);
                pthread_spin_init(&spinlockParallelBackward[i],PTHREAD_PROCESS_SHARED);
                pthread_spin_init(&spinlockParallelForward[i],PTHREAD_PROCESS_SHARED);
                pthread_spin_init(&spinlockParallelKKTError[i],PTHREAD_PROCESS_SHARED);
        }
        // lock all
        for (i=0; i<c_DOP-1; i++)
        {
                pthread_spin_lock(&spinlockParallelStart[i]);
                pthread_spin_lock(&spinlockParallelCoarse[i]);
                pthread_spin_lock(&spinlockParallelBackward[i]);
                pthread_spin_lock(&spinlockParallelForward[i]);
                pthread_spin_lock(&spinlockParallelKKTError[i]);          
        }
        create_parallel_task(&taskAllParallel,  all_parallel_tasks, all_parallel_tasks_init, c_DOP-1, c_priority, c_affinity, c_schedMethod);
        // 
        initial_guess_func_initialize();
        coarse_update_func_initialize();
        forward_correction_parallel_func_initialize();
        KKT_error_func_initialize();

        /* delay for 0.2 s */
        usleep(200000);
}

static void feasibility_search(void)
{
        int i; 
        real_T stepSizeGMin,stepSizeZMin;
        if(c_zDim > 0)
        {
                stepSizeGMin = g_stepSizeG[0];
                stepSizeZMin = g_stepSizeZ[0];
                for(i=0;i<c_N;i++)
                {
                        stepSizeGMin = (stepSizeGMin > g_stepSizeG[i])?
                                        g_stepSizeG[i]:stepSizeGMin;
                        stepSizeZMin = (stepSizeZMin > g_stepSizeZ[i])?
                                        g_stepSizeZ[i]:stepSizeZMin;
                }
                if(stepSizeGMin!=1)
                {
                        MM_weightingadd(c_N,c_lambdaDim,(1-stepSizeGMin),stepSizeGMin,&g_lambdaBkup[0][0],&g_lambda[0][0]);
                        MM_weightingadd(c_N,c_muDim,(1-stepSizeGMin),stepSizeGMin,&g_muBkup[0][0],&g_mu[0][0]);
                        MM_weightingadd(c_N,c_uDim,(1-stepSizeGMin),stepSizeGMin,&g_uBkup[0][0],&g_u[0][0]);
                        MM_weightingadd(c_N,c_xDim,(1-stepSizeGMin),stepSizeGMin,&g_xBkup[0][0],&g_x[0][0]);
                }
                if(stepSizeZMin!=1)
                {
                        MM_weightingadd(c_N,c_zDim,(1-stepSizeZMin),stepSizeZMin,&g_zBkup[0][0],&g_z[0][0]);
                }
        }
}

static void forward_correction_serial(void)
{
        int i;
        for (i = 1; i < c_N; i++)
        {
                // dx(:,j,i) = x_prev-xPrev(:,j,i);
                memcpy(&g_dx[i][0],&g_x[i-1][0],sizeof(real_T)*c_xDim);
                VV_minus(c_xDim,&g_xPrev[i][0],&g_dx[i][0]);
                
                // x(:,j,i)  = x(:,j,i)  - p_x_F(:,:,j,i) * dx(:,j,i);
                MV_muladdTNm(c_xDim,c_xDim,&g_x2F[i][0][0],&g_dx[i][0],&g_x[i][0]);
        }
}

static void *forward_correction_parallel(long *iThread)
{
        long iTrd = *iThread;
        long startIdx = iTrd*c_SEG_SIZE;

        double *lambda_i, *u_i, *x_i, *p_i;
        double *dx_i, *u_k_i, *x_k_i, *z_k_i;
        double *p_muu_F_i, *LAMBDA_i;
        double *stepSizeMaxZ_i, *stepSizeMaxG_i;

        #if(c_zDim != 0)
        double *z_i;
        z_i = &g_z[startIdx][0];
        #endif

        #if(c_muDim != 0)
        double *mu_i;
        mu_i     = &g_mu[startIdx][0];
        #endif


        lambda_i = &g_lambda[startIdx][0];
        u_i = &g_u[startIdx][0];
        x_i = &g_x[startIdx][0];
        p_i = &g_p[startIdx][0];

        dx_i = &g_dx[startIdx][0];
        u_k_i = &g_uBkup[startIdx][0];
        x_k_i = &g_xBkup[startIdx][0];
        z_k_i = &g_zBkup[startIdx][0];

        LAMBDA_i     = &g_LAMBDA[startIdx][0][0];
        p_muu_F_i    = &g_muu2F[startIdx][0][0];

        stepSizeMaxZ_i = &g_stepSizeZ[startIdx];
        stepSizeMaxG_i = &g_stepSizeG[startIdx];
        
        #if(c_zDim == 0)
                #if(c_muDim == 0)
                        forward_correction_parallel_func(lambda_i, u_i, x_i, p_i, dx_i, u_k_i, x_k_i, z_k_i,
                                                        p_muu_F_i, LAMBDA_i, g_rho, stepSizeMaxZ_i, stepSizeMaxG_i);
                #else
                        forward_correction_parallel_func(lambda_i, mu_i, u_i, x_i, p_i, dx_i, u_k_i, x_k_i, z_k_i,
                                                        p_muu_F_i, LAMBDA_i, g_rho, stepSizeMaxZ_i, stepSizeMaxG_i);
                #endif
        #else
                #if(c_muDim == 0)
                        forward_correction_parallel_func(lambda_i, u_i, x_i, z_i, p_i, dx_i, u_k_i, x_k_i, z_k_i,
                                                        p_muu_F_i, LAMBDA_i, g_rho, stepSizeMaxZ_i, stepSizeMaxG_i);
                #else
                        forward_correction_parallel_func(lambda_i, mu_i, u_i, x_i, z_i, p_i, dx_i, u_k_i, x_k_i, z_k_i,
                                                        p_muu_F_i, LAMBDA_i, g_rho, stepSizeMaxZ_i, stepSizeMaxG_i);
                #endif
        #endif

        return NULL;
}

static void *backward_correction_parallel(long *iThread)
{
        // counters
        long i = *iThread;
        int j;
        long iTrdj; // i-th thread's j-th component

        real_T dmuuij[c_muDim+c_uDim], dmuij[c_muDim],duij[c_uDim];

        for (j = c_SEG_SIZE - 1; j >= 0; j--)
        {
                iTrdj = i * c_SEG_SIZE + j;
                
                // dmu_u_j_i = p_muu_Lambda_i(:,:,j)* dlambda_i(:,j);
                // MM_mul('T','N','+',c_muDim+c_uDim,1,c_lambdaDim,
                //         &g_muu2Lambda[iTrdj][0][0],&g_dlambda[iTrdj][0],dmuuij);
                MV_mulTNp(c_muDim+c_uDim,c_lambdaDim,&g_muu2Lambda[iTrdj][0][0],&g_dlambda[iTrdj][0],dmuuij);

                // x_i(:,j)  = x_i(:,j) - p_x_Lambda_i(:,:,j)  * dlambda_i(:,j);
                MV_muladdTNm(c_xDim,c_lambdaDim,&g_x2Lambda[iTrdj][0][0],&g_dlambda[iTrdj][0],&g_x[iTrdj][0]);

                // mu_u_new  =  [mu_i(:,j);u_i(:,j)] - dmu_u_j_i;
                memcpy(dmuij,dmuuij,sizeof(real_T)*c_muDim);
                memcpy(duij,&dmuuij[c_muDim],sizeof(real_T)*c_uDim);

                // mu_i(:,j) = mu_u_new(1:muDim,1);
                VV_minus(c_muDim,dmuij,&g_mu[iTrdj][0]);

                // u_i(:,j)  = mu_u_new(muDim+1:end,1);
                VV_minus(c_uDim,duij,&g_u[iTrdj][0]);
        }

        // // // printf("%ld-th thread running for backward \n", i);
        return NULL;
}

static void backward_correction_serial(void)
{
        int i;
        for (i = c_N - c_SEG_SIZE - 1; i >= 0; i--)
        {
                // dlambda(:,j,i) = lambda_next-lambdaNext(:,j,i);
                memcpy(&g_dlambda[i][0],&g_lambda[i+1][0],sizeof(real_T)*c_lambdaDim);
                VV_minus(c_lambdaDim,&g_lambdaNext[i][0],&g_dlambda[i][0]);
                
                // lambda(:,j,i)  = lambda(:,j,i)  - p_lambda_Lambda(:,:,j,i) * dlambda(:,j,i);
                MV_muladdTNm(c_lambdaDim,c_lambdaDim,&g_lambda2Lambda[i][0][0],&g_dlambda[i][0],&g_lambda[i][0]);
        }
}

/* coarse update */
static void *coarse_update_parallel(long *iThread)
{
        long iTrd = *iThread;
        long startIdx = iTrd*c_SEG_SIZE;

        double *lambda_i, *u_i, *x_i, *p_i;
        double *xPrev_i, *lambdaNext_i, *LAMBDA_i;
        double *p_muu_F_i, *p_muu_Lambda_i, *p_lambda_Lambda_i, *p_x_Lambda_i, *p_x_F_i;
        double *KKTxEquation_i, *KKTC_i, *KKTHu_i, *KKTlambdaEquation_i, *L_i, *LB_i;


        #if(c_zDim != 0)
        double *z_i;
        z_i = &g_z[startIdx][0];
        #endif

        #if(c_muDim != 0)
        double *mu_i;
        mu_i     = &g_mu[startIdx][0];
        #endif

        lambda_i = &g_lambda[startIdx][0];
        u_i = &g_u[startIdx][0];
        x_i = &g_x[startIdx][0];
        p_i = &g_p[startIdx][0];

        xPrev_i      = &g_xPrev[startIdx][0];
        lambdaNext_i = &g_lambdaNext[startIdx][0];
        LAMBDA_i     = &g_LAMBDA[startIdx][0][0];
        p_muu_F_i         = &g_muu2F[startIdx][0][0];
        p_muu_Lambda_i    = &g_muu2Lambda[startIdx][0][0];
        p_lambda_Lambda_i = &g_lambda2Lambda[startIdx][0][0];
        p_x_Lambda_i      = &g_x2Lambda[startIdx][0][0];
        p_x_F_i           = &g_x2F[startIdx][0][0];

        KKTxEquation_i      = &g_KKTxEq[startIdx];
        KKTC_i              = &g_KKTC[startIdx];
        KKTHu_i             = &g_KKTHu[startIdx];
        KKTlambdaEquation_i = &g_KKTlambdaEq[startIdx];
        L_i                 = &g_L[startIdx];
        LB_i                = &g_LB[startIdx];


        #if(c_zDim == 0)
                #if(c_muDim == 0)
                        coarse_update_func(lambda_i,u_i,x_i,p_i,
                                        xPrev_i,lambdaNext_i,LAMBDA_i,g_rho,iTrd,
                                        p_muu_F_i,p_muu_Lambda_i,p_lambda_Lambda_i,p_x_Lambda_i,p_x_F_i,
                                        KKTxEquation_i,KKTC_i,KKTHu_i,KKTlambdaEquation_i,L_i,LB_i);
                #else
                        coarse_update_func(lambda_i,mu_i,u_i,x_i,p_i,
                                        xPrev_i,lambdaNext_i,LAMBDA_i,g_rho,iTrd,
                                        p_muu_F_i,p_muu_Lambda_i,p_lambda_Lambda_i,p_x_Lambda_i,p_x_F_i,
                                        KKTxEquation_i,KKTC_i,KKTHu_i,KKTlambdaEquation_i,L_i,LB_i);
                #endif
        #else
                #if(c_muDim == 0)
                        coarse_update_func(lambda_i,u_i,x_i,z_i,p_i,
                                        xPrev_i,lambdaNext_i,LAMBDA_i,g_rho,iTrd,
                                        p_muu_F_i,p_muu_Lambda_i,p_lambda_Lambda_i,p_x_Lambda_i,p_x_F_i,
                                        KKTxEquation_i,KKTC_i,KKTHu_i,KKTlambdaEquation_i,L_i,LB_i);
                #else
                        coarse_update_func(lambda_i,mu_i,u_i,x_i,z_i,p_i,
                                        xPrev_i,lambdaNext_i,LAMBDA_i,g_rho,iTrd,
                                        p_muu_F_i,p_muu_Lambda_i,p_lambda_Lambda_i,p_x_Lambda_i,p_x_F_i,
                                        KKTxEquation_i,KKTC_i,KKTHu_i,KKTlambdaEquation_i,L_i,LB_i);
                #endif
        #endif

        return NULL;
}

static void *KKT_error_parallel(long *iThread)
{
        long iTrd = *iThread;
        long startIdx = iTrd*c_SEG_SIZE;

        double *lambda_i, *u_i, *x_i, *p_i;
        double *xPrev_i, *lambdaNext_i;
        double *KKTxEquation_i, *KKTC_i, *KKTHu_i, *KKTlambdaEquation_i, *L_i, *LB_i;

        #if(c_muDim != 0)
        double *mu_i;
        mu_i     = &g_mu[startIdx][0];
        #endif

        lambda_i = &g_lambda[startIdx][0];
        u_i = &g_u[startIdx][0];
        x_i = &g_x[startIdx][0];
        p_i = &g_p[startIdx][0];

        xPrev_i      = &g_xPrev[startIdx][0];
        lambdaNext_i = &g_lambdaNext[startIdx][0];

        KKTxEquation_i      = &g_KKTxEq[startIdx];
        KKTC_i              = &g_KKTC[startIdx];
        KKTHu_i             = &g_KKTHu[startIdx];
        KKTlambdaEquation_i = &g_KKTlambdaEq[startIdx];
        L_i                 = &g_L[startIdx];
        LB_i                = &g_LB[startIdx];
        #if(c_muDim == 0)
                KKT_error_func((const double *) lambda_i,(const double *)u_i,(const double *)x_i,(const double *)p_i,xPrev_i,lambdaNext_i,g_rho,iTrd,
                        KKTxEquation_i,KKTC_i,KKTHu_i,KKTlambdaEquation_i,L_i,LB_i);
        #else
                KKT_error_func(lambda_i,mu_i,u_i,x_i,p_i,xPrev_i,lambdaNext_i,g_rho,iTrd,
                        KKTxEquation_i,KKTC_i,KKTHu_i,KKTlambdaEquation_i,L_i,LB_i);
        #endif
        // // // printf("check running\n");
        return NULL;

}

// C[MxN] = trans(A)*(B)
static void MV_mulTNp(const int M, const int K,  const real_T *A,  const real_T *B, real_T *C)
{
        int m,k; 
        for (m = 0; m < M; m++)
        {
                C[m] = 0;
                for (k = 0; k < K; k++) 
                        C[m] += A[k*M + m] * B[k];
        }

}
// B = beta*B + alpha*A 
static void MM_weightingadd(const int M, const int N, real_T alpha, real_T beta, real_T *A, real_T *B)
{
    int m,n;
    for (m = 0; m < M; m++)
    {
        for (n = 0; n < N; n++) 
        {
            B[m*N+n] =  alpha*A[m*N+n] + beta*B[m*N+n];
        }
    }
}
// C[MxN] = C + trans(A)*(B)
static void MV_muladdTNm(const int M, const int K, const  real_T *A, const  real_T *B, real_T *C)
{
        int m,k; 
        for (m = 0; m < M; m++)
                for (k = 0; k < K; k++) 
                        C[m] -= A[k*M + m] * B[k];

}
// B =  B - A
static void VV_minus(const int M, real_T *A, real_T *B)
{
    int m;
    for (m = 0; m < M; m++) 
            B[m] -=  A[m];
}
