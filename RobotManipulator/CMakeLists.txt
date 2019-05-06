cmake_minimum_required(VERSION 2.8.3)
project(iiwa14_NMPC)
# --- set compiler flags for pinocchio ---
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x -DPINOCCHIO_URDFDOM_TYPEDEF_SHARED_PTR -DPINOCCHIO_URDFDOM_USE_STD_SHARED_PTR -DPINOCCHIO_WITH_URDFDOM -fopenmp -O3")
# --- add definitions for vrep ---
# add_definitions(-DNON_MATLAB_PARSING -DMAX_EXT_API_CONNECTIONS=255 -DDO_NOT_USE_SHARED_MEMORY)
# --- set the directory where the generated executables are placed ---
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_SOURCE_DIR}/bin)
# --- set the directory where the generated libraries are placed ---
set(LIBRARY_OUTPUT_PATH ${CMAKE_SOURCE_DIR}/lib)

# --- find eigens ---
find_package(Eigen3 REQUIRED)
include_directories(${EIGEN3_INCLUDE_DIR})
add_definitions(${EIGEN_DEFINITIONS})
# --- find boost_system ---
find_package(Boost REQUIRED COMPONENTS system)
# --- add pinocchio header files directory ---
include_directories(/usr/local/include/pinocchio)

# --- set gen_code_directory ---
set(GEN_CODE_DIR ${CMAKE_SOURCE_DIR}/codegen/lib/Simu_Matlab)
# --- set iiwa14 dynamics source files directory ---
set(IIWA14_DYNAMICS_DIR ${CMAKE_SOURCE_DIR}/iiwa_pinocchio)
# --- set matlab directory ---
# set(MATLAB_DIR /opt/MATLAB/R2018a)
# --- add gen header files directory ---
include_directories(${GEN_CODE_DIR} ${GEN_CODE_DIR}/examples)#${CMAKE_SOURCE_DIR}/Simu_Matlab/interface
# --- add vrep header file directory ---
# include_directories(${CMAKE_SOURCE_DIR}/include/vrep/include ${CMAKE_SOURCE_DIR}/include/vrep/remoteApi)
# --- add matlab header file directory ---
# include_directories(${MATLAB_DIR}/extern/include)
# --- add iiwa14 header file directory ---
include_directories(${IIWA14_DYNAMICS_DIR})
# --- add library directory ---
link_directories(${CMAKE_SOURCE_DIR}/lib)
# --- collect vrep source files ---
# file(GLOB VREP_SRC_FILES "${CMAKE_SOURCE_DIR}/src/vrep/*.c*")

# --- collect source files ---
# file(GLOB SRC_FILES "${CMAKE_SOURCE_DIR}/src/*.c*")

# --- generate iiwa14 dynamics library ---
add_library(iiwa14_dynamics SHARED ${IIWA14_DYNAMICS_DIR}/iiwa.cpp) 
target_link_libraries(iiwa14_dynamics urdfdom_model)
# --- generate executable ---
add_executable(${PROJECT_NAME} ${GEN_CODE_DIR}/Simu_Matlab.cpp ${GEN_CODE_DIR}/examples/main.cpp)#${VREP_SRC_FILES} 
target_link_libraries(${PROJECT_NAME} boost_system gomp pthread iiwa14_dynamics) #remoteApi 

