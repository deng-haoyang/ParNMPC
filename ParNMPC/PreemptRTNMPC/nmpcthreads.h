#ifndef NMPC_THREADS_H_
#define NMPC_THREADS_H_

#include <pthread.h>

/* each thread's parameters */
struct s_ThreadPara;  
struct s_ParallelTask; 
struct s_RTTask;

typedef struct s_ThreadPara
{
    long index;
    int piority; 
    int affinity; 
    int schedMethod;  
    pthread_t threadHandle; 
    pthread_attr_t  attr; // priority, sched
    struct s_ParallelTask *parallelTask; // which parallel task it belongs to
    struct s_RTTask *rtTask; 
    volatile int isNowWaiting;
}ThreadPara; 

/* each task's parameters (each task has c_DOP threads) */
typedef struct s_ParallelTask
{
    int dop;
    ThreadPara *threadPara; 
    pthread_cond_t  *cond; // condition variable
    pthread_mutex_t *mut;  // with condition variable
    pthread_barrier_t barrier; // sync 
    pthread_spinlock_t *spin; // sync by spinlock 
    void (*parallel_func)(long* ); // function needed to be run in parallel
    void (*parallel_func_init)(long* ); // init function needed to be run in parallel
}ParallelTask; 

/* RT */
typedef struct s_RTTask
{
    ThreadPara threadPara; 
    pthread_cond_t  cond; // condition variable
    pthread_mutex_t mut;  // with condition variable
    pthread_barrier_t barrier; // sync 
    pthread_spinlock_t spin; // sync by spinlock 
    void (*rt_func)(long* ); // function needed to be run in parallel
}RTTask; 

void create_rt_task(RTTask* rtTask, void* rt_func, const int priority, const int affinity, const int schedMethod);

void create_parallel_task(ParallelTask* parallelTask, void* parallel_func, void* parallel_func_init, 
                          const int dop, const int *priority, const int *affinity, const int schedMethod);
void wakeup_parallel_task(ParallelTask* parallelTask);
void free_parallel_task(ParallelTask* parallelTask);
void run_rt_task(RTTask* rtTask, void* rt_func, const int priority, const int affinity, const int schedMethod);
#endif
