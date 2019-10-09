cmake_minimum_required(VERSION 3.0.0)
project(NMPC VERSION 0.1.0)
set(CPACK_PROJECT_NAME    ${PROJECT_NAME})
set(CPACK_PROJECT_VERSION ${PROJECT_VERSION})
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -O3 -march=native")

set(RT_PATH                 ../ParNMPC/PreemptRTNMPC/)
set(CODEGEN_PATH            ./codegen/)
set(COARSE_UPDATE_PATH      ${CODEGEN_PATH}/lib/coarse_update_func)
set(FORWARD_CORRECTION_PATH ${CODEGEN_PATH}/lib/forward_correction_parallel_func)
set(INITIAL_GUESS_PATH      ${CODEGEN_PATH}/lib/initial_guess_func)
set(KKT_ERROR_PATH          ${CODEGEN_PATH}/lib/KKT_error_func)
set(SIM_PLANT_PATH          ${CODEGEN_PATH}/lib/SIM_Plant_RK4)

include_directories(${RT_PATH})
include_directories(${CODEGEN_PATH})
include_directories(${COARSE_UPDATE_PATH})
include_directories(${FORWARD_CORRECTION_PATH})
include_directories(${INITIAL_GUESS_PATH})
include_directories(${KKT_ERROR_PATH})
include_directories(${SIM_PLANT_PATH})

add_executable(NMPC ${RT_PATH}/examplemain.c 
                    ${RT_PATH}/nmpc.c 
                    ${RT_PATH}/nmpcthreads.c 
                    ${RT_PATH}/nmpctools.c 
                    ${COARSE_UPDATE_PATH}/coarse_update_func.c 
                    ${FORWARD_CORRECTION_PATH}/forward_correction_parallel_func.c 
                    ${INITIAL_GUESS_PATH}/initial_guess_func.c
                    ${KKT_ERROR_PATH}/KKT_error_func.c
                    ${SIM_PLANT_PATH}/SIM_Plant_RK4.c)
# pthread
find_package (Threads)
target_link_libraries (NMPC ${CMAKE_THREAD_LIBS_INIT} m)
