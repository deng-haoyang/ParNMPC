# ParNMPC-Beta2.0
A parallel nonlinear model predictive control (NMPC) toolkit for C/C++ code generation and closed-loop simulation.

ParNMPC is an open-source MATLAB toolkit developed to carry out closed-loop simulation and parallel C/C++ code generation with OpenMP for NMPC. The aim of ParNMPC is to provide an easy-to-use environment for NMPC problem formulation, initialization, parallel code generation and deployment. In ParNMPC, the underlying optimal control problem (OCP) of NMPC is solved based on a highly parallelizable Newton-type method, which computes the optimal solution iteratively with at most N cores, where N is the number of discretization grids or sometimes called the prediction horizon.

The current version of ParNMPC does not contain any globalization strategies such as the line-search and trust-region methods. It is currently under developing and will be available in the future release.

See UserManual for more details.

Please feel free to contact me or submit issues if you have any questions.

email: deng.haoyang.23r@st.kyoto-u.ac.jp

wechat: ideadhy
