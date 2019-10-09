#define _GNU_SOURCE

#include <limits.h>
#include <stdio.h>
#include <malloc.h>
#include <time.h>
#include <stdlib.h>
#include "nmpcthreads.h"
#include <unistd.h>

static void init_parallel_task(ParallelTask* parallelTask, const int dop, const int *priority, const int *affinity, const int schedMethod);
static void *loop_parallel_func(void* threadPara);
static void set_threadAttr(pthread_attr_t* attr_t, int priority, int schedMethod);
static void stick_this_thread_to_core(int coreID);
static void init_rt_task(RTTask* rtTask, const int priority, const int affinity, const int schedMethod);
static void *one_rt_func(void* threadPara);

void run_rt_task(RTTask* rtTask, void* rt_func, const int priority, const int affinity, const int schedMethod)
{
    int ret;
    init_rt_task(rtTask, priority, affinity, schedMethod);
    rtTask->rt_func = (void*) (rt_func); 

    ret = pthread_create( &(rtTask->threadPara.threadHandle),
                        &(rtTask->threadPara.attr),
                        one_rt_func,
                        (void*) (&(rtTask->threadPara)));
    
    if (ret)
    {
        printf("create threads failed\n");
        exit(-2);
    }
    // waits for the thread 
    ret = pthread_join(rtTask->threadPara.threadHandle, NULL);

    if (ret)
    {
        printf("join pthread failed\n");
        exit(-2);
    }
}

void create_parallel_task(ParallelTask* parallelTask, void* parallel_func, void* parallel_func_init, 
                          const int dop, const int *priority, const int *affinity, const int schedMethod)
{
    long i;
    int ret;
    init_parallel_task(parallelTask, dop, priority, affinity, schedMethod);
    parallelTask->parallel_func_init = (void*) (parallel_func_init); 
    parallelTask->parallel_func = (void*) (parallel_func); 
    for (i = 0; i < dop; i++)
    {
        ret = pthread_create( &(parallelTask->threadPara[i].threadHandle),
                            &(parallelTask->threadPara[i].attr),
                            loop_parallel_func,
                            (void*) (&(parallelTask->threadPara[i])));
        if (ret) 
        {
            printf("create threads failed, try to run with sudo\n");
            exit(-2);
        }
    }
}


void wakeup_parallel_task(ParallelTask* parallelTask)
{
        int i = 0;
        for (i=0; i<parallelTask->dop; i++)
        {
                while(parallelTask->threadPara[i].isNowWaiting == 0);
                pthread_mutex_lock(&(parallelTask->mut[i]));
                parallelTask->threadPara[i].isNowWaiting = 0;
                pthread_cond_signal(&(parallelTask->cond[i]));
                pthread_mutex_unlock(&(parallelTask->mut[i]));
        }
}

void free_parallel_task(ParallelTask* parallelTask)
{
    free(parallelTask->threadPara);
    free(parallelTask->cond);
    free(parallelTask->mut);
}

void set_threadAttr(pthread_attr_t* attr_t, int priority, int schedMethod)
{
        struct sched_param param;
        int ret;
        /* Initialize pthread attributes (default values) */
        ret = pthread_attr_init(attr_t);
        if (ret) 
        {
                printf("init pthread attributes failed\n");
                goto out;
        }
        /* Set a specific stack size  */
        // default is 8192 KB (8 MB)
        // pthread_attr_setstacksize(attr_t, PTHREAD_STACK_MIN);

        /* Set scheduler policy and priority of pthread */
        ret = pthread_attr_setschedpolicy(attr_t, schedMethod);
        if (ret) 
        {
                printf("pthread setschedpolicy failed\n");
                goto out;
        }
        param.sched_priority = priority;
        ret = pthread_attr_setschedparam(attr_t, &param);
        if (ret) 
        {
                printf("pthread setschedparam failed\n");
                goto out;
        }

        /* Use scheduling parameters of attr */
        ret = pthread_attr_setinheritsched(attr_t, PTHREAD_EXPLICIT_SCHED);
        if (ret)
        {
                printf("pthread setinheritsched failed\n");
                goto out;
        }
        out:
            if(ret)
                exit(-2);
}


static void *one_rt_func(void* threadPara)
{
    ThreadPara* trdPara = (ThreadPara*) threadPara;

    long i = (long)(trdPara->index); 

    stick_this_thread_to_core(trdPara->affinity);
    
    trdPara->rtTask->rt_func(&i);

    return NULL;
}

static void init_rt_task(RTTask* rtTask, const int priority, const int affinity, const int schedMethod)
{
    set_threadAttr(&(rtTask->threadPara.attr),priority, schedMethod);
    pthread_cond_init(&(rtTask->cond), NULL); 
    pthread_mutex_init(&(rtTask->mut),NULL); 

    rtTask->threadPara.affinity     = affinity;
    rtTask->threadPara.rtTask       = rtTask;
    rtTask->threadPara.isNowWaiting = 0;
}

static void stick_this_thread_to_core(int coreID) 
{
    int ret;    
    cpu_set_t cpuSet;
    CPU_ZERO(&cpuSet);
    CPU_SET(coreID, &cpuSet);

    pthread_t currentThread = pthread_self();
    ret = pthread_setaffinity_np(currentThread, sizeof(cpu_set_t), &cpuSet);
    if(ret)
    {
        printf("set cpu affinity failed\n");
        exit(-2);
    }
}

static void* loop_parallel_func(void* threadPara)
{
    ThreadPara* trdPara = (ThreadPara*) threadPara;
    long i = (long)(trdPara->index); 

    stick_this_thread_to_core(trdPara->affinity);
    
    trdPara->parallelTask->parallel_func_init(&i);

    // pthread_mutex_lock(&(trdPara->parallelTask->mut[i]));
    // trdPara->isNowWaiting = 1;
    // pthread_mutex_unlock(&(trdPara->parallelTask->mut[i])); 
    // pthread_cond_wait(&(trdPara->parallelTask->cond[i]), &(trdPara->parallelTask->mut[i]));

    while (1)
    {
            // printf("%ld-th thread waiting\n",i);
            trdPara->parallelTask->parallel_func(&i);
    }
    return NULL;
}

static void init_parallel_task(ParallelTask* parallelTask,  const int dop, const int *priority, const int *affinity, const int schedMethod)
{
    int i;
    parallelTask->dop = dop;
    parallelTask->threadPara = (ThreadPara *)malloc(dop * sizeof(ThreadPara));
    parallelTask->cond       = (pthread_cond_t *)malloc(dop * sizeof(pthread_cond_t));
    parallelTask->mut        = (pthread_mutex_t *)malloc(dop * sizeof(pthread_mutex_t));
    parallelTask->spin       = (pthread_spinlock_t *)malloc(dop * sizeof(pthread_spinlock_t));
    for (i=0;i<dop;i++)
    {
        set_threadAttr(&(parallelTask->threadPara[i].attr),priority[i], schedMethod);
        pthread_cond_init(&(parallelTask->cond[i]), NULL); 
        pthread_mutex_init(&(parallelTask->mut[i]),NULL); 
        pthread_spin_init(&(parallelTask->spin[i]),PTHREAD_PROCESS_SHARED); 

        parallelTask->threadPara[i].affinity     = affinity[i];
        parallelTask->threadPara[i].index        = i;
        parallelTask->threadPara[i].parallelTask = parallelTask;
        parallelTask->threadPara[i].isNowWaiting = 0;
    }
}



