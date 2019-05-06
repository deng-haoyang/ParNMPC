
#include "iiwa14.h"

#define DoP 4 // degree of parallelism 

pinocchio::Model model;

// initialize your own size 
// data for the NMPC controller
pinocchio::Data data[DoP] = {pinocchio::Data(model),pinocchio::Data(model),pinocchio::Data(model),pinocchio::Data(model)};

// data for the simulation model
pinocchio::Data sim_data(model);

void iiwa14_init()
{
    std::string filename = "../iiwa_description/iiwa14.urdf";
    pinocchio::urdf::buildModel(filename,model);
    model.gravity.setZero();
    // init for NMPC
    for(int i=0;i<DoP;i++)
    {
        data[i] = pinocchio::Data(model);
    }
    // init for Simulation
    sim_data = pinocchio::Data(model);

}

void qdd_cal(double *q, double *qd, double *qdd, double *tau, int parIdx)
{
    Eigen::VectorXd q_Eigen   = Eigen::Map<Eigen::VectorXd>(q, model.nv);
    Eigen::VectorXd qd_Eigen  = Eigen::Map<Eigen::VectorXd>(qd,model.nv);
    Eigen::VectorXd qdd_Eigen = Eigen::VectorXd::Zero(model.nv);
    Eigen::VectorXd tau_Eigen = Eigen::Map<Eigen::VectorXd>(tau,model.nv);
    
    qdd_Eigen = pinocchio::aba(model,data[parIdx-1],q_Eigen,qd_Eigen,tau_Eigen);
    
    // to double
    Eigen::Map<Eigen::VectorXd>(qdd,model.nv) = qdd_Eigen;

//    std::cout << "qdd = " << qdd_Eigen << std::endl;
}

void sim_qdd_cal(double *q, double *qd, double *qdd, double *tau)
{
    Eigen::VectorXd q_Eigen   = Eigen::Map<Eigen::VectorXd>(q, model.nv);
    Eigen::VectorXd qd_Eigen  = Eigen::Map<Eigen::VectorXd>(qd,model.nv);
    Eigen::VectorXd qdd_Eigen = Eigen::VectorXd::Zero(model.nv);
    Eigen::VectorXd tau_Eigen = Eigen::Map<Eigen::VectorXd>(tau,model.nv);
    
    qdd_Eigen = pinocchio::aba(model,sim_data,q_Eigen,qd_Eigen,tau_Eigen);
    // to double
    Eigen::Map<Eigen::VectorXd>(qdd,model.nv) = qdd_Eigen;

//    std::cout << "qdd = " << qdd_Eigen << std::endl;
}

void derivatives_cal(double *q, double *qd, double *tau, double *dq, double *dqd, double *dtau, int parIdx)
{
    // to eigen
    Eigen::VectorXd q_Eigen   = Eigen::Map<Eigen::VectorXd>(q, model.nv);
    Eigen::VectorXd qd_Eigen  = Eigen::Map<Eigen::VectorXd>(qd,model.nv);
    Eigen::VectorXd tau_Eigen = Eigen::Map<Eigen::VectorXd>(tau,model.nv);

    Eigen::MatrixXd dq_Eigen(model.nv,model.nv);
    Eigen::MatrixXd dqd_Eigen(model.nv,model.nv);
    Eigen::MatrixXd dtau_Eigen(model.nv,model.nv);
    
    computeABADerivatives(model, data[parIdx-1], q_Eigen, qd_Eigen, tau_Eigen, dq_Eigen, dqd_Eigen, dtau_Eigen);
    
    // to double
    Eigen::Map<Eigen::MatrixXd>(dq,  model.nv,model.nv)   = dq_Eigen;
    Eigen::Map<Eigen::MatrixXd>(dqd, model.nv,model.nv)   = dqd_Eigen;
    Eigen::Map<Eigen::MatrixXd>(dtau,model.nv,model.nv)   = dtau_Eigen;

//    std::cout << "dq = " << dq_Eigen << std::endl;
//    std::cout << "dqd = " << dqd_Eigen << std::endl;
//    std::cout << "dtau = " << dtau_Eigen << std::endl;
}
