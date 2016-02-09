function [time, uz, ug] = MILP(par, T_o, forecast, q_int, constraints, plt)
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   David, Grant Gunnison, Pete Lindahl
%
%  This program solves the optimization of a number of army tent heaters 
%  drawing power from a number of generators.  The heaters are on-off
%  control and the tent temperature dynamics are modeled using a single RC
%  model.
%
%  Important assumptions:
%  1) Heaters are on-off control
%  2) Tent temperature dynamics represented by single RC model
%  3) Solar gains input directly to air temperature node
%  4) Internal gains are assumed all convective
%  5) Temperature constraints are soft
%
%  Inputs:
%
%   Parameters - par
%       (1) - Number of tents (1 heater per tent)      (-)
%       (2) - Number of generators                     (-)
%       (3) - Simulation starting time (Unix)          (s)
%       (4) - Planning horizon                         (s)
%       (5) - Time interval of planning horizon        (s)
%       (6) - MILP time intervals                      (s)
%       (7) - Nominal Heating output of heater z       (W)
%       (8) - Power consumption of supply fan z        (W)
%       (9) - Nom. Power-Heat efficiency of heater z   (Wth/We)
%       (10)- Nominal Power output of generator g      (W)
%       (11)- Nom. Fuel consumption of generator g     (Gal/s)
%       (12)- Nominal Resistance value of tent z       (K/W)
%       (13)- Nominal Capacitance value of tent z      (J/K)
%       (14)- Nominal Solar absorptance coefficient z  (m^2)
%       (15)- Penalty for temperature violation        (W)
%
%   T_o - initial temperature of tents                 (K)
%
%   forecast - contains the weather and load forecast for the MILP
%   optimization period.
%   Structure [2 x N]:
%       [T_ext, Sol_ext, Q_int] where:
%           T_ext - external temperature               (K)
%           Sol_ext - Solarirradiance                  (W/m^2)
%
%   q_int - internal heat load matrix for tents (Z x N)(W)
%
%   constraints - contains the upper and lower limits for the tents
%   Structure [2 x N]:
%       [Tll, Tul] where:
%           Tll - lower temperature limit              (K)
%           Tul - upper temperature limit              (K)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all
tic
%% Inputs

%  Unpack parameters
Z = par(1);
G = par(2);
st = par(3);
n = par(4);
t = par(5);
I = par(6);
Qz = par(7);
Efan = par(8);
etaz = par(9);
Pg = par(10);
Fg = par(11);
Rz = par(12);
Cz = par(13);
kz = par(14);
rho_temp = par(15);

% Create parameter streams
Qz   = Qz*ones(1,Z);            %  Heating output of heater z           (W)
Efan = Efan*ones(1,Z);          %  Power consumption of supply fan z    (W)
etaz = etaz*ones(1,Z);          %  Power-Heat efficiency of heater z    (Wth/We)
Pg   = Pg*ones(1,G);            %  Power output of generator g          (W)
Fg   = Fg*ones(1,G);            %  Fuel consumption of generator g      (Gal/s)
Rz   = Rz*ones(1,Z);            %  Resistance value of tent z           (K/W)
Cz   = Cz*ones(1,Z);            %  Capacitance value of tent z          (J/K)
kz   = kz*ones(1,Z);            %  Solar absorptance coefficient z      (m^2)

%  Exogenous data
Tx = forecast(:,1);
qsol = forecast(:,2);

% combine load data (solar and internal for purposes of MILP)
qload   = zeros(I,Z);
for z = 1:Z
    for i = 1:I
        qload(i,z) = kz(z)*qsol(i) + q_int(i,z);
    end
end

% Constraint streams
Tll = constraints(:,1:2:end);
Tul = constraints(:,2:2:end);

%%  Building Optimization Matrices
%  State variables
x = zeros(Z*I,1);
x_bin = zeros(Z*I + G*I, 1);

%  Build A_eq matrix
A_eq = zeros(Z*I, length(x));
a = 0;
for z = 1:Z
    for i = 1:I
        a = a + 1;
        if i == 1;
            A_eq(a,(z-1)*I+i) = 1;
        else
            A_eq(a,(z-1)*I+i) = 1;
            A_eq(a,(z-1)*I+i-1) = -1*exp(-t/(Rz(z)*Cz(z)));
        end
    end
end
%  Build A_eq_bin matrix
A_eq_bin = zeros(length(A_eq(:,1)), length(x_bin));
a = 0;
for z = 1:Z
    for i = 1:I
        a = a + 1;
        if i == 1;
            A_eq_bin(a, (z-1)*I+i) = 0;
        else
            A_eq_bin(a, (z-1)*I+i) = -Qz(z)*Rz(z)*(1-exp(-t/(Rz(z)*Cz(z))));
        end
    end
end
%  Build b_eq matrix
b_eq = zeros(length(A_eq),1);
b = 0;
for z = 1:Z
    for i = 1:I
        b = b + 1;
        if i == 1
            b_eq(b) = T_o(z);
        else
            b_eq(b) = (Tx(i) + qload(i,z)*Rz(z))*(1-exp(-t/(Rz(z)*Cz(z))));
        end
    end
end

%  Build A_ineq_bin matrix
A_ineq_bin = zeros(I, length(x_bin));
a = 0;
for i = 1:I
    a = a + 1;
    for z = 1:Z
        A_ineq_bin(a,(z-1)*I+i) = Qz(z)/etaz(z);
    end
    for g = 1:G
        A_ineq_bin(a,Z*I+(g-1)*I+i) = -Pg(g);
    end
end

%  Build b_ineq_bin matrix
b_ineq_bin = zeros(length(A_ineq_bin(:,1)), 1);
b = 0;
for i = 1:I
    b = b + 1;
    b_ineq_bin(b) = 0;
end

%  Build c for objective function
c = zeros(I*Z,1);
for g = 1:G
    c = [c; Fg(g)*t*ones(I,1)];
end
%%  Solve Mixed Integer Linear Programming (MILP) Problem
Tll_opt = [];
Tul_opt = [];
for z = 1:Z
    Tll_opt = [Tll_opt; Tll(:,z)];
    Tul_opt = [Tul_opt; Tul(:,z)];
end
cvx_begin quiet
    variable x_var(Z*I);
    variable x_var_bin(Z*I + G*I) binary;
    minimize(c'*x_var_bin + sum(rho_temp*(max(Tll_opt-x_var, 0) + max(x_var-Tul_opt,0))));
    subject to
        A_eq*x_var + A_eq_bin*x_var_bin == b_eq;
        A_ineq_bin*x_var_bin + sum(Efan) <= b_ineq_bin;
cvx_end
display(sprintf('\nMILP solved in %i seconds.', int16(toc)));
display(sprintf('Optimal fuel use over planning period = %.2d Gallons.', c'*x_var_bin));
%%  Post Process
%  Split out state variables
T = zeros(I,Z);
uz = zeros(I,Z);
ug = zeros(I,G);
time = zeros(I,1);
a = 0;

for z = 1:Z
    for i = 1:I
        a = a+1;
        T(i,z) = x_var(a);
        uz(i,z) = x_var_bin(a);
        if i == 1
            time(i) = 0;
        else
            time(i) = time(i-1) + t/60;
        end
    end
end
a = 0;
for g = 1:G
    for i = 1:I
        a = a+1;
        ug(i,g) = x_var_bin(Z*I+a);
    end
end

%  Plot
% figure(1)
% ug_total = sum(ug,2);
% display(sprintf('The Max number of generators required is %i.\n', int16(max(ug_total))));
% plot(time, ug_total, '-ok', 'markersize', 2);
% ylim([0 int16(max(ug_total))+1]);
% set(gca, 'ytick', [0:1:int16(max(ug_total))+1]);
% ylabel('Number of Generators');
% xlabel('Time (min)');
% Figure_properties({1}, 3, 2.5);
% Figure_print(1, 'jpeg', 3,2.5,300, 'Number of Generators');
% 

if plt == 1
    figure;
    hold on;
    grid on;
    plot(repmat(time,1,Z), T-273.15, '-o', 'markersize', 2);
    for z = 1:Z
        plot(time, Tul(:,z)-273.15, ':k');
        plot(time, Tll(:,z)-273.15, ':k');
    end
    plot(time, Tx - 273.15, '-ok', 'markersize', 2);
    ylabel('Temperature (^oC)');
    xlabel('Time (min)');
    % Figure_properties({1}, 3, 2.5);
    %Figure_print(1, 'jpeg', 3,2.5,300, 'Tent Temperature');

    figure;
    hold on;
    grid on;
    plot(repmat(time,1,Z), uz, '-o', 'markersize', 2);
    set(gca, 'ytick', [0:1:1]);
    ylim([0 1]);
    ylabel('Tent Heater Status');
    xlabel('Time (min)');
    % Figure_properties({2}, 3, 2.5);
    %Figure_print(2, 'jpeg', 3,2.5,300, 'Tent Heater Status');
end