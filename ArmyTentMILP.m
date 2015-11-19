%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ArmyTentMILP
%
%  David Blum
%  Last Update: 11/3/2015
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all
tic
%% Inputs
%  Parameters
Z = 3;                         %  Number of tents (1 heater per tent)  (-)
G = 2;                          %  Number of generators                 (-)
n = 5*3600;                     %  Planning horizon                     (s)
t = 10*60;                      %  Time interval of planning horizon    (s)
I = n/t+1;                      %  Number of time intervals             (-)
Qz = 10.0e3*ones(1,Z);          %  Heating output of heater z           (W)
Efan = 1.5e3*ones(1,Z);         %  Power consumption of supply fan z    (W)
etaz = 1*ones(1,Z);             %  Power-Heat efficiency of heater z    (Wth/We)
Pg = 60.0e3*ones(1,G);          %  Power output of generator g          (W)
Fg = 1*ones(1,G);               %  Fuel consumption of generator g      (Gal/s)
Rz = 0.00182*ones(1,Z);         %  Resistance value of tent z           (K/W)
Cz = 1.47e6*ones(1,Z);          %  Capacitance value of tent z          (J/K)
kz = 2.38*ones(1,Z);            %  Solar absorptance coefficient z      (m^2)
Tll = (20+273.15)*ones(I,Z);    %  Lower temperature limit of tent z    (K)
Tul = (25+273.15)*ones(I,Z);    %  Upper temperature limit of tent z    (K)
T_o = (22+273.15)*ones(1,Z);    %  Initial temperature of tent z        (K)
rho_temp = 0.5*Pg(1);           %  Penalty for temperature violation    (W/K);

weafil = 'June2014weatherdata.txt';
% weadir = '/Users/lindahl/Documents/Research/Projects/Devens Temperature Experiment/Forward Simulation/Version 1.2/';
weadir = '/Users/GrantGunnison/Dropbox/6.UAR/Tent Simulation/';
%  Exogenous data
plt = 0;
[Tx, qsol] = ReadWeather([weadir weafil], n, 2*60, plt);
Tx = ((Tx-32)*5/9 + 273.15)-15; % (Convert F to C) and adjust so need heating
qint    = 1000*ones(I,Z);
qload   = zeros(I,Z);
for z = 1:Z
    for i = 1:I
        qload(i,z) = kz(z)*qsol(i) + qint(i,z);
    end
end
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
cvx_solver gurobi
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
uz
%  Plot
figure(1)
ug_total = sum(ug,2);
display(sprintf('The Max number of generators required is %i.\n', int16(max(ug_total))));
plot(time, ug_total, '-ok', 'markersize', 2);
ylim([0 int16(max(ug_total))+1]);
set(gca, 'ytick', [0:1:int16(max(ug_total))+1]);
ylabel('Number of Generators');
xlabel('Time (min)');
Figure_properties({1}, 3, 2.5);
Figure_print(1, 'jpeg', 3,2.5,300, 'Number of Generators');

figure(2)
hold on;
plot(repmat(time,1,Z), T-273.15, '-o', 'markersize', 2);
for z = 1:Z
    plot(time, Tul(:,z)-273.15, ':k');
    plot(time, Tll(:,z)-273.15, ':k');
end
plot(time, Tx - 273.15, '-ok', 'markersize', 2);
ylabel('Temperature (^oC)');
xlabel('Time (min)');
Figure_properties({2}, 3, 2.5);
Figure_print(2, 'jpeg', 3,2.5,300, 'Tent Temperature');

figure(3)
hold on;
plot(repmat(time,1,Z), uz, '-o', 'markersize', 2);
set(gca, 'ytick', [0:1:1]);
ylim([0 1]);
ylabel('Tent Heater Status');
xlabel('Time (min)');
Figure_properties({3}, 3, 2.5);
Figure_print(3, 'jpeg', 3,2.5,300, 'Tent Heater Status');
