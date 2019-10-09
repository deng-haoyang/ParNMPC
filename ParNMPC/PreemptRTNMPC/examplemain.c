#include <stdio.h>
#include <string.h>
#include <time.h>
#include "nmpc.h"
#include "SIM_Plant_RK4.h"
#include "examplemain.h"

#define SIMU_LENGTH  1000

static RTTask taskClosedLoopSimu;

real_T recCpuTime[SIMU_LENGTH];
real_T recIter[SIMU_LENGTH];
real_T recExitFlag[SIMU_LENGTH];
real_T recX[SIMU_LENGTH][c_xDim];
real_T recU[SIMU_LENGTH][c_uDim];
real_T recKKTxEq[SIMU_LENGTH];
real_T recKKTC[SIMU_LENGTH];
real_T recFirstOrderOpt[SIMU_LENGTH];
real_T recCost[SIMU_LENGTH];

void *closed_loop_simu(void *iThrd)
{
    real_T x0[c_xDim] = c_x0INIT;
    real_T p[c_N][c_pDim] = c_pINIT;
    real_T samplingTimeTs = c_Ts;

    SolverOutput solverOutput;
    real_T x0NextStep[c_xDim];
    int i;

    nmpc_init(); 

    for(i = 0; i < SIMU_LENGTH; i++)
    {
        /* nmpc solver */
        nmpc_solve(x0,&p[0][0],&solverOutput);

        /* record data */
        recCpuTime[i]   = solverOutput.cpuTime;
        recIter[i]      = solverOutput.iterations;
        recExitFlag[i]  = solverOutput.exitFlag;
        memcpy(&recX[i][0],x0,sizeof(real_T)*c_xDim);
        memcpy(&recU[i][0],solverOutput.u,sizeof(real_T)*c_uDim);
        recKKTxEq[i]    = solverOutput.xEqViolation;
        recKKTC[i]      = solverOutput.CEqViolation;
        recFirstOrderOpt[i]  = solverOutput.firstOrderOpt;
        recCost[i]      = solverOutput.cost;

        /* simulation */
        SIM_Plant_RK4(solverOutput.u,x0,samplingTimeTs,x0NextStep);

        
        memcpy(x0,x0NextStep,sizeof(real_T)*c_xDim);
    }

    nmpc_exit();

    return NULL;
} 

int main(void)
{
    /* run simulation */ 
    run_rt_task(&taskClosedLoopSimu, closed_loop_simu, c_MAIN_PRIORITY, c_MAIN_AFFINITY, SCHED_METHOD);

    /* write to file */ 
    FILE *file;
    int i,j;
    file = fopen("output.txt","w");
    for(i=0;i<SIMU_LENGTH;i++) 
    {
        fprintf(file,"%f\t",recCpuTime[i]);
        fprintf(file,"%f\t",recIter[i]);
        for(j=0;j<c_xDim;j++) 
            fprintf(file,"%f\t",recX[i][j]);
        for(j=0;j<c_uDim;j++) 
            fprintf(file,"%f\t",recU[i][j]);
        fprintf(file,"%f\t",recKKTxEq[i]);
        fprintf(file,"%f\t",recKKTC[i]);
        fprintf(file,"%f\t",recFirstOrderOpt[i]);
        fprintf(file,"%f\t",recCost[i]);

        fprintf(file,"\n");
    }
    fclose(file);


    return 0;
}