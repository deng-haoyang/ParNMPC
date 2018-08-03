%% SETUP_HELI_3D_CONFIGURATION
%
% SETUP_HELI_3D_CONFIGURATION sets and returns the model parameters 
% of the Quanser 3-DOF Helicopter plant.
%
% Copyright (C) 2007 Quanser Consulting Inc.
% Quanser Consulting Inc.
%
%%
function [ Kf, m_h, m_w, m_f, m_b, Lh, La, Lw, g, K_EC_T, K_EC_P, K_EC_E ] = setup_heli_3d_configuration()
    %
    % Propeller force-thrust constant found experimentally (N/V)
    Kf = 0.1188;
    % Mass of the helicopter body (kg)
    m_h = 1.15;
    % Mass of counter-weight (kg)
    m_w = 1.87;
    % Mass of front propeller assembly = motor + shield + propeller + body (kg)
    m_f = m_h / 2;
    % Mass of back propeller assembly = motor + shield + propeller + body (kg)
    m_b = m_h / 2;
    % Distance between pitch pivot and each motor (m)
    Lh = 7.0 * 0.0254;
    % Distance between elevation pivot to helicopter body (m)
    La = 26.0 * 0.0254;
    % Distance between elevation pivot to counter-weight (m)
    Lw = 18.5 * 0.0254;
    % Gravitational Constant (m/s^2)
    g = 9.81;    
    % Travel, Pitch, and Elevation Encoder Resolution (rad/count)
    K_EC_T = 2 * pi / ( 8 * 1024 );
    K_EC_P = 2 * pi / ( 4 * 1024 );
    K_EC_E = - 2 * pi / ( 4 * 1024 );
    % Motor Armature Resistance (Ohm)
    Rm = 0.83;
    % Motor Current-Torque Constant (N.m/A)
    Kt = 0.0182;
    % Motor Rotor Moment of Inertia (kg.m^2)
    Jm = 1.91e-6;

end
%
% end of setup_heli_3d_configuration()