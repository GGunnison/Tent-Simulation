%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ArmyTent Forward Sim
%
%  Peter Lindahl, Grant Gunnison
%  Last Update: 11/18/2015
%
%  This program performs the forward simulation of the army forward
%  operating base under predictive model control.  
%
%               *** work in progress ***
%
%  Base Model:
%
%       Single tent model:
%       dTi/dt = -Ti/(R*C) + Te/(R*C) + k/C*qs + 1/C*ql + 1/C*qh
%
%       Multi-tent State-space model:
%       dx/dt   = Ax + Bu
%       y       = Cx + Du
%
%       x - state vector containing internal tent temperatures, i.e.
%           [Ti1; Ti2; ...; Tiz] where i indicates internal and z is number
%           of tents
%       u - exogenous input vector with form:
%           [Te; qs1; ql1; qh1; qs2; ql2; qh2;...; qsz; qlz; qhz] where s
%           indicates solar irradiation(qs in W/m^2), l indicates internal
%           heat loads (ql in W), h indicates heater on or off (1 or 0); 
%           and z is number of tents
%       A is state matrix, diagonal matrix with 1/tau1, ... 1/tauz on main 
%       diagonal, where tau = R * C
%       B is input matrix relating dx/dt to input contributions
%       C is the output matrix (and confusingly different than heat 
%       capacity C) and is an identity matrix size z by z as temperature is 
%       directly observable
%       D is feedthrough matrix as inputs don't directly affect
%       measurements
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;

% set weather data files to use for simulation
weafil = 'June2014weatherdata.txt';
weadir = '/Users/GrantGunnison/Dropbox/6.UAR/Tent Simulation/';

cd(weadir);

%% Set Parameters
% Parameters (pulled these from David's code, not all used currently)
Z = 3;                          %  Number of tents (1 heater per tent)      (-)
G = 2;                          %  Number of generators                     (-)
n = 5*3600;                     %  Planning horizon                         (s)
tp = 10*60;                     %  Time interval of planning horizon        (s)
I = n/tp +1;                    %  MILP time intervals
ts = 2*60;                      %  Simulation interval (make fractional)    (s)
Ns = n/ts+1;                    %  Number of time intervals                 (-)
Qz = 10.0e3;                    %  Nominal Heating output of heater z       (W)
Qlz = 1000;                     %  Nominal internal loads in each tent      (W)
etaz = 1;                       %  Nom. Power-Heat efficiency of heater z   (Wth/We)
Pg = 60.0e3;                    %  Nominal Power output of generator g      (W)
Fg = 1;                         %  Nom. Fuel consumption of generator g     (Gal/s)
Rz = 0.00182;                   %  Nominal Resistance value of tent z       (K/W)
Cz = 1.47e6;                    %  NominalCapacitance value of tent z       (J/K)
kz = 2.38;                      %  Nominal Solar absorptance coefficient z  (m^2)
rho_temp = 0.5*Pg;              %  Penalty for temperature violation    (W)
Efan = 1.5e3;                   %  Power consumption of supply fan z    (W)
Tll = 20;                       %  Lower temperature limit of tent z    (C)
Tul = 25;                       %  Upper temperature limit of tent z    (C)
To = 22;                        %  Initial temperature of tent z        (C)
plt = 1;                        %  Plot graphs of the results.
%% Create simulation system

% function generates the nominal multi-tent base model
[A, B, C, D] = ss_variables(Z, Qz, kz, Rz, Cz);

% manually adjust SS-matrices here if desired for simulation:
A = A;
B = B;
C = C;
D = D;

% create state space system
sys = ss(A,B,C,D); 

% create nominal initial state vector
x0 = To*ones(Z,1);
% manually adjust the initial state vector here:
x0 = x0;

%% Set internal load profile

Ql = Qlz*ones(Ns,1);

%% Load environmental inputs

plt = 0;    % if plt = 1 then plot weather data.  if plt = 0 don't plot.
[TxF, qsol] = ReadWeather(weafil, n, ts, plt);
qsol = qsol*kz; % Convert from W/m^2 to W

Tx = ((TxF-32)*5/9) -15; % (Convert F to C)

%% Run Initial MILP Optimization Code for Initial Heater Operation


[uz, ug] = MILP(Z, G, n, tp, I, Qz, Efan, etaz, Pg, Fg, Rz, Cz, kz, Tll, Tul, To, rho_temp, 0);

% For now, I am just using a uz found for the parameter values: Z = 3; 
% G = 2; n = 5*3600; tp = 10*60; ts = 2*60.
% uz_set = ...
%     [0 0 0;...
%     0 0 0;...
%     1 1 1;...
%     0 0 1;...
%     1 1 0;...
%     0 0 1;...
%     1 0 0;...
%     0 1 1;...
%     1 1 0;...
%     0 0 0;...
%     0 0 1;...
%     1 0 0;...
%     0 1 0;...
%     0 0 0;...
%     0 1 1;...
%     1 0 0;...
%     0 1 0;...
%     1 0 1;...
%     0 1 0;...
%     0 0 0;...
%     1 0 1;...
%     0 1 0;...
%     1 0 1;...
%     0 1 0;...
%     0 0 0;...
%     0 0 0;...
%     1 0 1;...
%     0 1 0;...
%     0 0 0;...
%     1 0 0;...
%     0 0 1];

% Adjust uz size to be in compliance with the simulation rate by repeating
% rows of uz an appropriate amount of times.
[aa, bb] = size(uz);
uz_sim = zeros((aa-1)*round(tp/ts)+1,bb);
for xx = 1:(length(uz)-1)
uz_sim(((xx-1)*round(tp/ts)+1):(xx*round(tp/ts)),:) = repmat(uz(xx,:),round(tp/ts),1);
end
uz_sim(end,:) = uz(end,:);

%% Run simulation
% This will allow the inputs to change based on optimization / control
% updates at intervals

% create time vector
time = ts*(0:(Ns-1))';

% create inputs.  will want to use real data and results of optimization
U = ss_inputs(Z, Tx, qsol, Ql, uz_sim);

x =x0;
 for m = 1:(Ns-1)
    sim = lsim(sys,U(:,m:m+1),time(m:m+1), x(:,m));
    x = [x,sim(2,:)']; % time-matrix of state vectors
end

%% figures
figure(1);
plot(repmat(time,1,Z)/60,x');
xlabel('Time (min)');
ylabel('Tent Temperatures (C)');
hold on;
grid on;
tents = {};
for num = 1:Z
     s = [' Tent ', num2str(num), ''];
     tents = [tents, s];
end
legend(tents);
    
