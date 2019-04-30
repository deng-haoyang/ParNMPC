#ifndef IIWA14_H_INCLUDED
#define IIWA14_H_INCLUDED

#include "pinocchio/multibody/model.hpp"
#include "pinocchio/parsers/urdf.hpp"
#include "pinocchio/algorithm/aba.hpp"
#include "pinocchio/algorithm/aba-derivatives.hpp"

// init function
void iiwa14_init();

// calculate qdd for f
void qdd_cal(double *q, double *qd, double *qdd, double *tau, int parIdx);

// calculate derivatives for fu and fx
void derivatives_cal(double *q, double *qd, double *tau, double *dq, double *dqd, double *dtau, int parIdx);

// simulation model
void sim_qdd_cal(double *q, double *qd, double *qdd, double *tau);

#endif // IIWA14_H_INCLUDED
