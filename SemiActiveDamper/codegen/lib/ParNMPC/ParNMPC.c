/*
 * File: ParNMPC.c
 *
 * MATLAB Coder version            : 3.1
 * C/C++ source code generated on  : 21-Jan-2018 01:45:16
 */

/* Include Files */
#include "rt_nonfinite.h"
#include "ParNMPC.h"
#include "inv.h"
#include "GEN_Func_KKT.h"
#include "Func_Hxx_FD.h"
#include "GEN_Func_Hux.h"
#include "GEN_Func_dKKT23_mu_u.h"
#include "GEN_Func_fx_I.h"
#include "GEN_Func_fu.h"
#include "FuncPlantSim.h"
#include "norm.h"
#include "fprintf.h"
#include "fclose.h"
#include "fopen.h"
#include <stdio.h>
#include "omp.h"
#include "stdio.h"

/* Function Definitions */

/*
 * % Load and init parameters
 *  dimension variables
 * Arguments    : void
 * Return Type  : void
 */
void ParNMPC(void)
{
  double xCurrentState[2];
  int i0;
  double rec_x[4002];
  double rec_u[4000];
  signed char rec_numIter[2000];
  double rec_error[2000];
  double rec_cpuTime[2000];
  double currentEval[168];
  double currentIteration[168];
  double theta[96];
  static const double dv0[96] = { -11.952820910768395, -3.1628193665198476,
    -3.1628193665198476, -8.5144659773203735, -11.707454099712391,
    -2.5321630372793891, -2.5321630372793891, -5.9352585513369656,
    -11.340815902785456, -1.784617866142979, -1.784617866142979,
    -3.8580003344225626, -10.846326213704636, -0.99173025942989124,
    -0.99173025942989124, -2.2437807108378696, -11.582218590998963,
    -2.7263267219417249, -2.7263267219417249, -5.672231221789513,
    -11.339133639454005, -2.6706323887621166, -2.6706323887621166,
    -5.7867908957651952, -11.004837325916998, -2.4814653158307758,
    -2.4814653158307758, -5.6192709560238132, -10.628344416167788,
    -2.2710503580225891, -2.2710503580225891, -5.4138649259921481,
    -10.212970113497416, -2.0522357044659389, -2.0522357044659389,
    -5.1968322490948369, -9.7587516078910035, -1.8297675912122457,
    -1.8297675912122457, -4.9742515915463237, -9.2655174877350124,
    -1.6071448626722225, -1.6071448626722225, -4.7478958799947675,
    -8.73340374873551, -1.3876928194376095, -1.3876928194376095,
    -4.5178844045008955, -8.1630000810337737, -1.1747675464861891,
    -1.1747675464861891, -4.2832665787742821, -7.5554069303577807,
    -0.97175200209295443, -0.97175200209295443, -4.0421181848652443,
    -6.9122556293394366, -0.78197729328749077, -0.78197729328749077,
    -3.7914885759315373, -6.2357022372263495, -0.60860379806190312,
    -0.60860379806190312, -3.5272952896561378, -5.5283957787440325,
    -0.4544731908150374, -0.4544731908150374, -3.2442027014459813,
    -4.793418778172521, -0.32193623751167405, -0.32193623751167405,
    -2.9355060539193372, -4.0341972705050226, -0.21266027160429052,
    -0.21266027160429052, -2.5930427780792336, -3.2543776529090866,
    -0.12742183093450607, -0.12742183093450607, -2.2071665851258131,
    -2.4576686895494393, -0.065894381452086731, -0.065894381452086731,
    -1.7668590680319813, -1.6476492038838972, -0.026451609966813124,
    -0.026451609966813124, -1.2601614900396028, -0.82754699137837007,
    -0.0060297197337392788, -0.0060297197337392788, -0.67533077680020293, 0.0,
    0.0, 0.0, 0.0 };

  static const double dv1[168] = { 12.160142819057526, 3.6337031022197053,
    0.16141097166709642, -0.98361595988396877, 0.18027657491163404,
    0.9924923013316681, -0.090092384009880538, 11.635874493132784,
    2.3975874902378838, 0.22110478602167688, -0.99115867963253679,
    0.13268184423554494, 0.97691374426841038, -0.18694268474815839,
    11.021578663762257, 1.3856843821729925, 0.19832976133362656,
    -0.98905555623504482, 0.14754357553445613, 0.95272540422140573,
    -0.29026008055251656, 10.343114525425515, 0.59489299087189318,
    0.11745139157860832, -0.96952429813081287, 0.24499517410546176,
    0.91946463259232936, -0.39912925953700668, 9.6264684141712724,
    0.017510895914124427, 0.025290432332189812, -0.13814692070261883,
    0.99041174685133959, 0.87963676420827386, -0.47793442059661534,
    8.8948970186572414, -0.3866177111320902, 0.097549858811495319,
    0.95625309491002086, 0.29254062704920675, 0.83736261024431946,
    -0.50728984755545115, 8.1648767008593488, -0.73592628829210138,
    0.19222654492497721, 0.988363671952081, 0.15210934213532118,
    0.79321608016061984, -0.529758360992558, 7.4425361100345215,
    -1.0354809465851476, 0.27966176834511836, 0.99443115443642482,
    0.10538823030034804, 0.7476532699742221, -0.54675372222518437,
    6.7332016395072847, -1.2858737299928642, 0.35550728178205576,
    0.99653152751053509, 0.083216072229457247, 0.70108870926340738,
    -0.55877472851852983, 6.04180490428843, -1.4881127355476815,
    0.41735335633267512, 0.997474139015611, 0.071030570848290522,
    0.65390517040769847, -0.56620246625768655, 5.3728745343197666,
    -1.6434572531610598, 0.46384375204747841, 0.997950719196362,
    0.063987202280027938, 0.60645611561228285, -0.56938865753467693,
    4.7305396668795039, -1.7533803620555555, 0.49445239739104468,
    0.99819442071648423, 0.060065784360409824, 0.55906664560273778,
    -0.568673640104817, 4.1185357653726591, -1.8195485087746781,
    0.50934374140177874, 0.99829754580839769, 0.058326752296452705,
    0.5120340903401378, -0.56439066314213648, 3.54021164769139,
    -1.8438051708364185, 0.509252495355306, 0.99829694109186817,
    0.058337101464596461, 0.46562854623404326, -0.55686652926478919,
    2.99853742826006, -1.8281561222580323, 0.495371714746943,
    0.99820105526394076, 0.059955427366888622, 0.42009345146374133,
    -0.5464211372360499, 2.4961132085188411, -1.7747555744518064,
    0.469247652294926, 0.99799720151385607, 0.0632580885846737,
    0.37564622009714721, -0.53336677639236352, 2.0351783939003054,
    -1.6858927862242874, 0.43268197312613638, 0.99764816857740024,
    0.068542918927319244, 0.33247892198645568, -0.51800757732236724,
    1.6176215600596417, -1.5639786588302671, 0.38764249575785475,
    0.99707683633450783, 0.076405382310986078, 0.29075896465473539,
    -0.500639487975558, 1.2449908679449104, -1.4115314566257537,
    0.33618399787415409, 0.9961267360816507, 0.087929094526186122,
    0.25062967805454961, -0.48155143919798787, 0.91850518151404126,
    -1.2311598481866606, 0.28038166216711086, 0.99445929272229239,
    0.10512238162767515, 0.21221056100072339, -0.4610294046425,
    0.639066393331282, -1.0255389720987855, 0.22228348770566711,
    0.99125054844565, 0.13199375063569352, 0.17559649952155965,
    -0.43936873774734675, 0.40727439605514609, -0.79736772913243537,
    0.1639032616784199, 0.98409978758353833, 0.177616463422079,
    0.14085350331296648, -0.41691595450125246, 0.22344916586669653,
    -0.54926808445814468, 0.10735484076391114, 0.96369342799219071,
    0.26701119235908521, 0.10799898754575571, -0.39425418920535793,
    0.0876776692071093, -0.28345419420914342, 0.055854242919865779,
    0.87003994114305172, 0.49298123779304542, 0.076867783627676933,
    -0.37357444701639908 };

  double lambdaNextVal[48];
  double xPrevVal[48];
  static const double dv2[48] = { 11.635874493132784, 2.3975874902378838,
    11.021578663762257, 1.3856843821729925, 10.343114525425515,
    0.59489299087189318, 9.6264684141712724, 0.017510895914124427,
    8.8948970186572414, -0.3866177111320902, 8.1648767008593488,
    -0.73592628829210138, 7.4425361100345215, -1.0354809465851476,
    6.7332016395072847, -1.2858737299928642, 6.04180490428843,
    -1.4881127355476815, 5.3728745343197666, -1.6434572531610598,
    4.7305396668795039, -1.7533803620555555, 4.1185357653726591,
    -1.8195485087746781, 3.54021164769139, -1.8438051708364185, 2.99853742826006,
    -1.8281561222580323, 2.4961132085188411, -1.7747555744518064,
    2.0351783939003054, -1.6858927862242874, 1.6176215600596417,
    -1.5639786588302671, 1.2449908679449104, -1.4115314566257537,
    0.91850518151404126, -1.2311598481866606, 0.639066393331282,
    -1.0255389720987855, 0.40727439605514609, -0.79736772913243537,
    0.22344916586669653, -0.54926808445814468, 0.0876776692071093,
    -0.28345419420914342, 0.0, 0.0 };

  static const double dv3[48] = { 1.0, 0.0, 0.9924923013316681,
    -0.090092384009880538, 0.97691374426841038, -0.18694268474815839,
    0.95272540422140573, -0.29026008055251656, 0.91946463259232936,
    -0.39912925953700668, 0.87963676420827386, -0.47793442059661534,
    0.83736261024431946, -0.50728984755545115, 0.79321608016061984,
    -0.529758360992558, 0.7476532699742221, -0.54675372222518437,
    0.70108870926340738, -0.55877472851852983, 0.65390517040769847,
    -0.56620246625768655, 0.60645611561228285, -0.56938865753467693,
    0.55906664560273778, -0.568673640104817, 0.5120340903401378,
    -0.56439066314213648, 0.46562854623404326, -0.55686652926478919,
    0.42009345146374133, -0.5464211372360499, 0.37564622009714721,
    -0.53336677639236352, 0.33247892198645568, -0.51800757732236724,
    0.29075896465473539, -0.500639487975558, 0.25062967805454961,
    -0.48155143919798787, 0.21221056100072339, -0.4610294046425,
    0.17559649952155965, -0.43936873774734675, 0.14085350331296648,
    -0.41691595450125246, 0.10799898754575571, -0.39425418920535793 };

  double dmu_u[72];
  double RTITime;
  double error;
  double simTimeStart;
  int step;
  double simTimeEnd;
  double timerRTIStart;
  int iter;
  int b_iter;
  boolean_T exitg1;
  double fileID;
  double timerRTIEnd;
  double C_Val[24];
  int j;
  double MT_Val[96];
  double A_Val[48];
  char cv0[3];
  double b_xCurrentState[2];
  double P_Val[96];
  int i;
  double p_lambda_Lambda[96];
  char cv1[3];
  double p_x_Lambda[96];
  double p_x_F[96];
  double V_Val[24];
  double dx[48];
  double dlambda[48];
  double fu_Val[96];
  double fx_I_Val[96];
  double dKKT23_mu_u_Val[216];
  double Hux_Val[96];
  double Hxx_Val[96];
  double F_Val[48];
  double Hu_Val[48];
  double Lamda_Val[48];
  double Inv_fx_I_Val[96];
  double theta_uncrt[96];
  double Hux_Inv_fx_I_Val[96];
  double Cx_Inv_fx_I_Val[48];
  double fuT_Inv_fxT_I_Val[96];
  double c_fuT_theta_uncrt_m_Hux_Inv_fx_[96];
  double Inv_dKKT23_mu_u_Val[216];
  double p_lambda_muu[144];
  double p_x_muu[144];
  double p_muu_F[144];
  double p_muu_Lambda[144];
  double W_Val[48];
  int b_i;
  double d0;
  int i1;
  int i2;
  double b_dlambda[7];
  double b_theta[4];
  int i3;
  double b_Hxx_Val[4];
  double b_Inv_fx_I_Val[4];
  double b_Cx_Inv_fx_I_Val[2];
  int i4;
  double d1;
  double dv4[9];
  double dv5[6];
  double b_V_Val[3];
  double d2;
  double b_Hu_Val[2];

  /* % For closed-loop simulation and code generation */
  /*  Date: Jan 21, 2018 */
  /*  Author: Haoyang Deng */
  /*  some other mpc parameters */
  for (i0 = 0; i0 < 2; i0++) {
    xCurrentState[i0] = 1.0 - (double)i0;
  }

  /*  simulation variables */
  /*  Jacobian variables */
  /*  record variables */
  memset(&rec_x[0], 0, 4002U * sizeof(double));
  for (i0 = 0; i0 < 2; i0++) {
    rec_x[2001 * i0] = 1.0 - (double)i0;
  }

  memset(&rec_u[0], 0, 4000U * sizeof(double));
  memset(&rec_numIter[0], 0, 2000U * sizeof(signed char));
  memset(&rec_error[0], 0, 2000U * sizeof(double));
  memset(&rec_cpuTime[0], 0, 2000U * sizeof(double));

  /*  problem variables */
  for (i0 = 0; i0 < 168; i0++) {
    currentEval[i0] = 0.0;
    currentIteration[i0] = dv1[i0];
  }

  memcpy(&theta[0], &dv0[0], 96U * sizeof(double));
  memcpy(&lambdaNextVal[0], &dv2[0], 48U * sizeof(double));
  memcpy(&xPrevVal[0], &dv3[0], 48U * sizeof(double));
  memset(&dmu_u[0], 0, 72U * sizeof(double));

  /*  time variables */
  RTITime = 0.0;
  error = 0.0;

  /* % Set number of threads */
  /*  Code generation */
  simTimeStart = omp_get_wtime();

  /* % Simulation */
  for (step = 0; step < 2000; step++) {
    /* simulation steps */
    /*     %% Solve the optimal control problem */
    timerRTIStart = omp_get_wtime();
    iter = 1;
    b_iter = 0;
    exitg1 = false;
    while ((!exitg1) && (b_iter < 5)) {
      iter = b_iter + 1;

#pragma omp parallel for \
 num_threads(24 > omp_get_max_threads() ? omp_get_max_threads() : 24) \
 private(i2,i3,i4,d1,d2) \
 firstprivate(b_Hxx_Val,b_Inv_fx_I_Val,dv4,b_Cx_Inv_fx_I_Val,dv5,b_V_Val,b_Hu_Val,b_dlambda)

      for (b_i = 0; b_i < 24; b_i++) {
        /*         %% Step 1: Coarse Iteration */
        /*             %% Jacobian Evaluation */
        GEN_Func_fu(*(double (*)[7])&currentIteration[7 * b_i], *(double (*)[4])
                    &fu_Val[b_i << 2]);
        GEN_Func_fx_I(*(double (*)[7])&currentIteration[7 * b_i], *(double (*)[4])
                      &fx_I_Val[b_i << 2]);
        GEN_Func_dKKT23_mu_u(*(double (*)[7])&currentIteration[7 * b_i],
                             *(double (*)[9])&dKKT23_mu_u_Val[9 * b_i]);
        GEN_Func_Hux(*(double (*)[7])&currentIteration[7 * b_i], *(double (*)[4])
                     &Hux_Val[b_i << 2]);
        Func_Hxx_FD(*(double (*)[7])&currentIteration[7 * b_i], *(double (*)[4])
                    &Hxx_Val[b_i << 2]);

        /*             %% Function Evaluation */
        GEN_Func_KKT(*(double (*)[7])&currentIteration[7 * b_i], *(double (*)[2])
                     &xPrevVal[b_i << 1], *(double (*)[2])&lambdaNextVal[b_i <<
                     1], *(double (*)[7])&currentEval[7 * b_i]);
        C_Val[b_i] = currentEval[2 + 7 * b_i];

        /*             %% Intermediate Variables */
        inv(*(double (*)[4])&fx_I_Val[b_i << 2], *(double (*)[4])&
            Inv_fx_I_Val[b_i << 2]);
        for (i2 = 0; i2 < 2; i2++) {
          F_Val[i2 + (b_i << 1)] = currentEval[i2 + 7 * b_i];
          Hu_Val[i2 + (b_i << 1)] = currentEval[(i2 + 7 * b_i) + 3];
          Lamda_Val[i2 + (b_i << 1)] = currentEval[(i2 + 7 * b_i) + 5];
          for (i3 = 0; i3 < 2; i3++) {
            b_Hxx_Val[i3 + (i2 << 1)] = Hxx_Val[(i3 + (i2 << 1)) + (b_i << 2)] -
              theta[(i3 + (i2 << 1)) + (b_i << 2)];
          }
        }

        for (i2 = 0; i2 < 2; i2++) {
          for (i3 = 0; i3 < 2; i3++) {
            b_Inv_fx_I_Val[i2 + (i3 << 1)] = 0.0;
            for (i4 = 0; i4 < 2; i4++) {
              b_Inv_fx_I_Val[i2 + (i3 << 1)] += Inv_fx_I_Val[(i4 + (i2 << 1)) +
                (b_i << 2)] * b_Hxx_Val[i4 + (i3 << 1)];
            }
          }

          Cx_Inv_fx_I_Val[i2 + (b_i << 1)] = 0.0;
          for (i3 = 0; i3 < 2; i3++) {
            theta_uncrt[(i2 + (i3 << 1)) + (b_i << 2)] = 0.0;
            Hux_Inv_fx_I_Val[(i2 + (i3 << 1)) + (b_i << 2)] = 0.0;
            Cx_Inv_fx_I_Val[i2 + (b_i << 1)] += 0.0 * Inv_fx_I_Val[(i3 + (i2 <<
              1)) + (b_i << 2)];
            fuT_Inv_fxT_I_Val[(i2 + (i3 << 1)) + (b_i << 2)] = 0.0;
            for (i4 = 0; i4 < 2; i4++) {
              theta_uncrt[(i2 + (i3 << 1)) + (b_i << 2)] += b_Inv_fx_I_Val[i2 +
                (i4 << 1)] * Inv_fx_I_Val[(i4 + (i3 << 1)) + (b_i << 2)];
              Hux_Inv_fx_I_Val[(i2 + (i3 << 1)) + (b_i << 2)] += Hux_Val[(i2 +
                (i4 << 1)) + (b_i << 2)] * Inv_fx_I_Val[(i4 + (i3 << 1)) + (b_i <<
                2)];
              fuT_Inv_fxT_I_Val[(i2 + (i3 << 1)) + (b_i << 2)] += fu_Val[(i4 +
                (i2 << 1)) + (b_i << 2)] * Inv_fx_I_Val[(i3 + (i4 << 1)) + (b_i <<
                2)];
            }
          }
        }

        for (i2 = 0; i2 < 2; i2++) {
          for (i3 = 0; i3 < 2; i3++) {
            d1 = 0.0;
            for (i4 = 0; i4 < 2; i4++) {
              d1 += fu_Val[(i4 + (i2 << 1)) + (b_i << 2)] * theta_uncrt[(i4 +
                (i3 << 1)) + (b_i << 2)];
            }

            c_fuT_theta_uncrt_m_Hux_Inv_fx_[(i2 + (i3 << 1)) + (b_i << 2)] = d1
              - Hux_Inv_fx_I_Val[(i2 + (i3 << 1)) + (b_i << 2)];
            MT_Val[(i3 + (i2 << 1)) + (b_i << 2)] = 0.0;
          }
        }

        for (i2 = 0; i2 < 2; i2++) {
          for (i3 = 0; i3 < 2; i3++) {
            MT_Val[(i2 + (i3 << 1)) + (b_i << 2)] = 0.0;
            for (i4 = 0; i4 < 2; i4++) {
              MT_Val[(i2 + (i3 << 1)) + (b_i << 2)] += fu_Val[(i4 + (i2 << 1)) +
                (b_i << 2)] * Hux_Inv_fx_I_Val[(i3 + (i4 << 1)) + (b_i << 2)];
            }
          }

          A_Val[i2 + (b_i << 1)] = 0.0;
          b_Cx_Inv_fx_I_Val[i2] = -Cx_Inv_fx_I_Val[i2 + (b_i << 1)];
        }

        dv4[0] = 0.0;
        for (i2 = 0; i2 < 2; i2++) {
          A_Val[i2 + (b_i << 1)] = 0.0;
          for (i3 = 0; i3 < 2; i3++) {
            A_Val[i2 + (b_i << 1)] += b_Cx_Inv_fx_I_Val[i3] * fu_Val[(i3 + (i2 <<
              1)) + (b_i << 2)];
            d1 = 0.0;
            for (i4 = 0; i4 < 2; i4++) {
              d1 += c_fuT_theta_uncrt_m_Hux_Inv_fx_[(i2 + (i4 << 1)) + (b_i << 2)]
                * fu_Val[(i4 + (i3 << 1)) + (b_i << 2)];
            }

            P_Val[(i2 + (i3 << 1)) + (b_i << 2)] = d1 - MT_Val[(i2 + (i3 << 1))
              + (b_i << 2)];
          }

          dv4[3 * (i2 + 1)] = A_Val[i2 + (b_i << 1)];
          dv4[i2 + 1] = A_Val[i2 + (b_i << 1)];
        }

        for (i2 = 0; i2 < 2; i2++) {
          for (i3 = 0; i3 < 2; i3++) {
            dv4[(i3 + 3 * (i2 + 1)) + 1] = P_Val[(i3 + (i2 << 1)) + (b_i << 2)];
          }
        }

        for (i2 = 0; i2 < 3; i2++) {
          for (i3 = 0; i3 < 3; i3++) {
            dKKT23_mu_u_Val[(i3 + 3 * i2) + 9 * b_i] += dv4[i3 + 3 * i2];
          }
        }

        b_inv(*(double (*)[9])&dKKT23_mu_u_Val[9 * b_i], *(double (*)[9])&
              Inv_dKKT23_mu_u_Val[9 * b_i]);

        /*             %% Sensitivity */
        for (i2 = 0; i2 < 2; i2++) {
          p_lambda_muu[i2 + 6 * b_i] = -Cx_Inv_fx_I_Val[i2 + (b_i << 1)];
          p_x_muu[i2 + 6 * b_i] = 0.0;
          for (i3 = 0; i3 < 2; i3++) {
            p_lambda_muu[(i3 + ((i2 + 1) << 1)) + 6 * b_i] =
              c_fuT_theta_uncrt_m_Hux_Inv_fx_[(i2 + (i3 << 1)) + (b_i << 2)];
            p_x_muu[(i3 + ((i2 + 1) << 1)) + 6 * b_i] = -fuT_Inv_fxT_I_Val[(i2 +
              (i3 << 1)) + (b_i << 2)];
          }
        }

        for (i2 = 0; i2 < 3; i2++) {
          for (i3 = 0; i3 < 2; i3++) {
            p_muu_F[(i2 + 3 * i3) + 6 * b_i] = 0.0;
            for (i4 = 0; i4 < 3; i4++) {
              p_muu_F[(i2 + 3 * i3) + 6 * b_i] += Inv_dKKT23_mu_u_Val[(i2 + 3 *
                i4) + 9 * b_i] * p_lambda_muu[(i3 + (i4 << 1)) + 6 * b_i];
            }
          }
        }

        for (i2 = 0; i2 < 2; i2++) {
          dv5[3 * i2] = 0.0;
          for (i3 = 0; i3 < 2; i3++) {
            dv5[(i3 + 3 * i2) + 1] = -fuT_Inv_fxT_I_Val[(i3 + (i2 << 1)) + (b_i <<
              2)];
          }
        }

        for (i2 = 0; i2 < 3; i2++) {
          for (i3 = 0; i3 < 2; i3++) {
            p_muu_Lambda[(i2 + 3 * i3) + 6 * b_i] = 0.0;
            for (i4 = 0; i4 < 3; i4++) {
              p_muu_Lambda[(i2 + 3 * i3) + 6 * b_i] += Inv_dKKT23_mu_u_Val[(i2 +
                3 * i4) + 9 * b_i] * dv5[i4 + 3 * i3];
            }
          }
        }

        for (i2 = 0; i2 < 2; i2++) {
          for (i3 = 0; i3 < 2; i3++) {
            d1 = 0.0;
            for (i4 = 0; i4 < 3; i4++) {
              d1 += p_lambda_muu[(i2 + (i4 << 1)) + 6 * b_i] * p_muu_Lambda[(i4
                + 3 * i3) + 6 * b_i];
            }

            p_lambda_Lambda[(i2 + (i3 << 1)) + (b_i << 2)] = d1 + Inv_fx_I_Val
              [(i3 + (i2 << 1)) + (b_i << 2)];
            p_x_Lambda[(i3 + (i2 << 1)) + (b_i << 2)] = 0.0;
          }
        }

        /*             %% theta = p_lambda_F */
        /*             %% Coarse Iteration */
        d1 = 0.0;
        for (i2 = 0; i2 < 2; i2++) {
          for (i3 = 0; i3 < 2; i3++) {
            p_x_Lambda[(i2 + (i3 << 1)) + (b_i << 2)] = 0.0;
            d2 = 0.0;
            for (i4 = 0; i4 < 3; i4++) {
              p_x_Lambda[(i2 + (i3 << 1)) + (b_i << 2)] += p_x_muu[(i2 + (i4 <<
                1)) + 6 * b_i] * p_muu_Lambda[(i4 + 3 * i3) + 6 * b_i];
              d2 += p_x_muu[(i2 + (i4 << 1)) + 6 * b_i] * p_muu_F[(i4 + 3 * i3)
                + 6 * b_i];
            }

            p_x_F[(i2 + (i3 << 1)) + (b_i << 2)] = d2 + Inv_fx_I_Val[(i2 + (i3 <<
              1)) + (b_i << 2)];
            d2 = 0.0;
            for (i4 = 0; i4 < 3; i4++) {
              d2 += p_lambda_muu[(i2 + (i4 << 1)) + 6 * b_i] * p_muu_F[(i4 + 3 *
                i3) + 6 * b_i];
            }

            theta[(i2 + (i3 << 1)) + (b_i << 2)] = d2 - theta_uncrt[(i2 + (i3 <<
              1)) + (b_i << 2)];
          }

          d1 += Cx_Inv_fx_I_Val[i2 + (b_i << 1)] * F_Val[i2 + (b_i << 1)];
        }

        V_Val[b_i] = C_Val[b_i] - d1;
        b_V_Val[0] = V_Val[b_i];
        for (i2 = 0; i2 < 2; i2++) {
          d1 = 0.0;
          for (i3 = 0; i3 < 2; i3++) {
            d1 += fuT_Inv_fxT_I_Val[(i2 + (i3 << 1)) + (b_i << 2)] *
              Lamda_Val[i3 + (b_i << 1)];
          }

          b_Hu_Val[i2] = Hu_Val[i2 + (b_i << 1)] - d1;
          b_Cx_Inv_fx_I_Val[i2] = 0.0;
          for (i3 = 0; i3 < 2; i3++) {
            b_Cx_Inv_fx_I_Val[i2] += c_fuT_theta_uncrt_m_Hux_Inv_fx_[(i2 + (i3 <<
              1)) + (b_i << 2)] * F_Val[i3 + (b_i << 1)];
          }

          W_Val[i2 + (b_i << 1)] = b_Hu_Val[i2] + b_Cx_Inv_fx_I_Val[i2];
          b_V_Val[i2 + 1] = W_Val[i2 + (b_i << 1)];
        }

        for (i2 = 0; i2 < 3; i2++) {
          dmu_u[i2 + 3 * b_i] = 0.0;
          for (i3 = 0; i3 < 3; i3++) {
            dmu_u[i2 + 3 * b_i] += Inv_dKKT23_mu_u_Val[(i2 + 3 * i3) + 9 * b_i] *
              b_V_Val[i3];
          }
        }

        for (i2 = 0; i2 < 2; i2++) {
          b_Cx_Inv_fx_I_Val[i2] = 0.0;
          for (i3 = 0; i3 < 3; i3++) {
            b_Cx_Inv_fx_I_Val[i2] += p_x_muu[(i2 + (i3 << 1)) + 6 * b_i] *
              dmu_u[i3 + 3 * b_i];
          }

          b_Hu_Val[i2] = 0.0;
          for (i3 = 0; i3 < 2; i3++) {
            b_Hxx_Val[i3 + (i2 << 1)] = -theta_uncrt[(i3 + (i2 << 1)) + (b_i <<
              2)];
            b_Hu_Val[i2] += Inv_fx_I_Val[(i2 + (i3 << 1)) + (b_i << 2)] *
              F_Val[i3 + (b_i << 1)];
          }

          dx[i2 + (b_i << 1)] = b_Cx_Inv_fx_I_Val[i2] + b_Hu_Val[i2];
        }

        for (i2 = 0; i2 < 2; i2++) {
          b_Cx_Inv_fx_I_Val[i2] = 0.0;
          b_Hu_Val[i2] = 0.0;
          for (i3 = 0; i3 < 2; i3++) {
            b_Cx_Inv_fx_I_Val[i2] += b_Hxx_Val[i2 + (i3 << 1)] * F_Val[i3 + (b_i
              << 1)];
            b_Hu_Val[i2] += Inv_fx_I_Val[(i3 + (i2 << 1)) + (b_i << 2)] *
              Lamda_Val[i3 + (b_i << 1)];
          }

          d1 = 0.0;
          for (i3 = 0; i3 < 3; i3++) {
            d1 += p_lambda_muu[(i2 + (i3 << 1)) + 6 * b_i] * dmu_u[i3 + 3 * b_i];
          }

          dlambda[i2 + (b_i << 1)] = (b_Cx_Inv_fx_I_Val[i2] + b_Hu_Val[i2]) + d1;
          b_dlambda[i2] = dlambda[i2 + (b_i << 1)];
        }

        for (i2 = 0; i2 < 3; i2++) {
          b_dlambda[i2 + 2] = dmu_u[i2 + 3 * b_i];
        }

        for (i2 = 0; i2 < 2; i2++) {
          b_dlambda[i2 + 5] = dx[i2 + (b_i << 1)];
        }

        for (i2 = 0; i2 < 7; i2++) {
          currentIteration[i2 + 7 * b_i] -= b_dlambda[i2];
        }
      }

      /*         %% Step 2: Backward correction due to the approximation of lambda */
      for (i = 0; i < 23; i++) {
        for (i0 = 0; i0 < 2; i0++) {
          dlambda[i0 + ((22 - i) << 1)] = currentIteration[i0 + 7 * (23 - i)] -
            lambdaNextVal[i0 + ((22 - i) << 1)];
        }

        for (i0 = 0; i0 < 2; i0++) {
          d0 = 0.0;
          for (i1 = 0; i1 < 2; i1++) {
            d0 += p_lambda_Lambda[(i0 + (i1 << 1)) + ((22 - i) << 2)] *
              dlambda[i1 + ((22 - i) << 1)];
          }

          currentIteration[i0 + 7 * (22 - i)] -= d0;
        }
      }

#pragma omp parallel for \
 num_threads(24 > omp_get_max_threads() ? omp_get_max_threads() : 24) \
 private(i2,i3) \
 firstprivate(b_dlambda)

      for (b_i = 0; b_i < 23; b_i++) {
        for (i2 = 0; i2 < 3; i2++) {
          dmu_u[i2 + 3 * b_i] = 0.0;
          dmu_u[i2 + 3 * b_i] = 0.0;
          for (i3 = 0; i3 < 2; i3++) {
            dmu_u[i2 + 3 * b_i] += p_muu_Lambda[(i2 + 3 * i3) + 6 * b_i] *
              dlambda[i3 + (b_i << 1)];
          }
        }

        for (i2 = 0; i2 < 2; i2++) {
          dx[i2 + (b_i << 1)] = 0.0;
          dx[i2 + (b_i << 1)] = 0.0;
          for (i3 = 0; i3 < 2; i3++) {
            dx[i2 + (b_i << 1)] += p_x_Lambda[(i2 + (i3 << 1)) + (b_i << 2)] *
              dlambda[i3 + (b_i << 1)];
          }

          b_dlambda[i2] = 0.0;
        }

        for (i2 = 0; i2 < 3; i2++) {
          b_dlambda[i2 + 2] = dmu_u[i2 + 3 * b_i];
        }

        for (i2 = 0; i2 < 2; i2++) {
          b_dlambda[i2 + 5] = dx[i2 + (b_i << 1)];
        }

        for (i2 = 0; i2 < 7; i2++) {
          currentIteration[i2 + 7 * b_i] -= b_dlambda[i2];
        }
      }

      /*         %% Step 3: Forward correction due to the approximation of x */
      for (i = 0; i < 23; i++) {
        for (i0 = 0; i0 < 2; i0++) {
          dx[i0 + ((i + 1) << 1)] = currentIteration[(i0 + 7 * i) + 5] -
            xPrevVal[i0 + ((i + 1) << 1)];
        }

        for (i0 = 0; i0 < 2; i0++) {
          d0 = 0.0;
          for (i1 = 0; i1 < 2; i1++) {
            d0 += p_x_F[(i0 + (i1 << 1)) + ((i + 1) << 2)] * dx[i1 + ((i + 1) <<
              1)];
          }

          currentIteration[(i0 + 7 * (i + 1)) + 5] -= d0;
        }
      }

#pragma omp parallel for \
 num_threads(24 > omp_get_max_threads() ? omp_get_max_threads() : 24) \
 private(i2,i3) \
 firstprivate(b_dlambda)

      for (b_i = 0; b_i < 23; b_i++) {
        for (i2 = 0; i2 < 3; i2++) {
          dmu_u[i2 + 3 * (b_i + 1)] = 0.0;
        }

        for (i2 = 0; i2 < 3; i2++) {
          dmu_u[i2 + 3 * (b_i + 1)] = 0.0;
          for (i3 = 0; i3 < 2; i3++) {
            dmu_u[i2 + 3 * (b_i + 1)] += p_muu_F[(i2 + 3 * i3) + 6 * (b_i + 1)] *
              dx[i3 + ((b_i + 1) << 1)];
          }
        }

        for (i2 = 0; i2 < 2; i2++) {
          dlambda[i2 + ((b_i + 1) << 1)] = 0.0;
        }

        for (i2 = 0; i2 < 2; i2++) {
          dlambda[i2 + ((b_i + 1) << 1)] = 0.0;
          for (i3 = 0; i3 < 2; i3++) {
            dlambda[i2 + ((b_i + 1) << 1)] += theta[(i2 + (i3 << 1)) + ((b_i + 1)
              << 2)] * dx[i3 + ((b_i + 1) << 1)];
          }
        }

        for (i2 = 0; i2 < 2; i2++) {
          b_dlambda[i2] = dlambda[i2 + ((b_i + 1) << 1)];
        }

        for (i2 = 0; i2 < 3; i2++) {
          b_dlambda[i2 + 2] = dmu_u[i2 + 3 * (b_i + 1)];
        }

        for (i2 = 0; i2 < 2; i2++) {
          b_dlambda[i2 + 5] = 0.0;
        }

        for (i2 = 0; i2 < 7; i2++) {
          currentIteration[i2 + 7 * (b_i + 1)] -= b_dlambda[i2];
        }
      }

      /*         %% Update Coupling Variables */
      /*         %% Update theta */
      for (i = 0; i < 23; i++) {
        for (i0 = 0; i0 < 2; i0++) {
          xPrevVal[i0 + ((i + 1) << 1)] = currentIteration[(i0 + 7 * i) + 5];
          lambdaNextVal[i0 + (i << 1)] = currentIteration[i0 + 7 * (i + 1)];
          for (i1 = 0; i1 < 2; i1++) {
            b_theta[i1 + (i0 << 1)] = theta[(i1 + (i0 << 1)) + ((i + 1) << 2)];
          }
        }

        for (i0 = 0; i0 < 2; i0++) {
          for (i1 = 0; i1 < 2; i1++) {
            theta[(i1 + (i0 << 1)) + (i << 2)] = b_theta[i1 + (i0 << 1)];
          }
        }
      }

      for (i0 = 0; i0 < 2; i0++) {
        for (i1 = 0; i1 < 2; i1++) {
          theta[92 + (i1 + (i0 << 1))] = 0.0;
        }
      }

#pragma omp parallel for \
 num_threads(24 > omp_get_max_threads() ? omp_get_max_threads() : 24)

      for (b_i = 0; b_i < 24; b_i++) {
        /*         %% Check termination */
        GEN_Func_KKT(*(double (*)[7])&currentIteration[7 * b_i], *(double (*)[2])
                     &xPrevVal[b_i << 1], *(double (*)[2])&lambdaNextVal[b_i <<
                     1], *(double (*)[7])&currentEval[7 * b_i]);
      }

      error = norm(currentEval);
      if (error < 0.005) {
        exitg1 = true;
      } else {
        b_iter++;
      }
    }

    timerRTIEnd = omp_get_wtime();
    RTITime = (RTITime + timerRTIEnd) - timerRTIStart;

    /*     %% Obtain the first optimal control input */
    /*     %% System simulation by the 4th-order Explicit Runge-Kutta Method */
    for (i = 0; i < 2; i++) {
      b_xCurrentState[i] = xCurrentState[i];
    }

    FuncPlantSim(*(double (*)[2])&currentIteration[3], b_xCurrentState, 0.01,
                 xCurrentState);

    /*     %% Update parameters */
    /*  Update coupling variable */
    /* >>>>>>------------------FOR_USER---------------------------->>>>>> */
    /*  MPC parameters */
    /*  Simulation plant parameters */
    /* <<<<<<----------------END_FOR_USER--------------------------<<<<<< */
    /*     %% Record data */
    for (i0 = 0; i0 < 2; i0++) {
      xPrevVal[i0] = xCurrentState[i0];
      rec_x[(step + 2001 * i0) + 1] = xCurrentState[i0];
      rec_u[step + 2000 * i0] = currentIteration[3 + i0];
    }

    rec_error[step] = error;
    rec_cpuTime[step] = timerRTIEnd - timerRTIStart;
    rec_numIter[step] = (signed char)iter;
  }

  /*  end of simulation */
  simTimeEnd = omp_get_wtime();

  /* % Log to file */
  /*  Code generation */
  /*     %% show Time Elapsed for RTI */
  printf("Time Elapsed for RTI (Real Time Iteration): %f seconds\r\n", RTITime);
  printf("Time Elapsed for RTI+Simulation: %f seconds\r\n", simTimeEnd -
         simTimeStart);

  /*     %% Log to file */
  fileID = b_fopen();

  /*  printf header */
  for (j = 0; j < 2; j++) {
    cv0[0] = 'x';
    cv0[1] = (signed char)(j + 49);
    cv0[2] = '\x00';
    cfprintf(fileID, cv0);
  }

  for (j = 0; j < 2; j++) {
    cv1[0] = 'u';
    cv1[1] = (signed char)(j + 49);
    cv1[2] = '\x00';
    cfprintf(fileID, cv1);
  }

  b_cfprintf(fileID, "error");
  b_cfprintf(fileID, "numIter");
  c_cfprintf(fileID, "cpuTime");

  /*  printf data */
  for (i = 0; i < 2000; i++) {
    for (j = 0; j < 2; j++) {
      d_cfprintf(fileID, rec_x[i + 2001 * j]);
    }

    for (j = 0; j < 2; j++) {
      d_cfprintf(fileID, rec_u[i + 2000 * j]);
    }

    d_cfprintf(fileID, rec_error[i]);
    d_cfprintf(fileID, rec_numIter[i]);
    e_cfprintf(fileID, rec_cpuTime[i]);
  }

  b_fclose(fileID);

  /*  end of function */
  /* _END_OF_FILE_ */
}

/*
 * File trailer for ParNMPC.c
 *
 * [EOF]
 */
