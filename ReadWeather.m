function [Tx, qsol, time] = ReadWeather(file, n, t, plt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ReadWeather
%
%  David Blum, Peter Lindahl
%  Last Update: 11/18/2015
%
%  This function takes a file containing weather information in the
%  format and units of the example file (June2014weatherdata.txt) and
%  averages the values appriopriately for use with the MILP optimization
%  routine.  Note that it begins from the first line of data.
%
%  Inputs:  (1)  file = full path of weather file
%           (2)  n    = planning horizon (s)
%           (3)  t    = timestep in planning horizon (s)
%           (4)  plt  = flag to print or not print data
%
%  Output:  (1)  Tx   = n/t+1 array of outside air temperatures
%           (2)  qsol = n/t+1 array of solar irradiation
%           (3)  time = n/t_1 array of file timestamp (s)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 4
    plt=1;
end

%  Read in data from file
M = csvread(file,32,0);
%  Convert from microseconds to seconds and normalize to beginning
M(:,1) = (M(:,1) - M(1,1))*10^-6;

%  Record averages
Tx = M(1,2);
qsol = M(1,3);
time = 0;
i = 1;
j = 2;
M_step = [];
while M(i,1) <= n+t
    if M(i,1) < (j-1)*t
        M_step = [M_step; M(i,:)];
    else 
        if isempty(M_step)
            Tx(j,1) = Tx(j-1,1);
            qsol(j,1) = qsol(j-1,1);
            time(j,1) = time(j-1,1);
        else
            Tx(j,1) = sum(M_step(:,1).*M_step(:,2))/sum(M_step(:,1));
            qsol(j,1) = sum(M_step(:,1).*M_step(:,3))/sum(M_step(:,1)); 
            time(j,1) = M_step(length(M_step(:,1)),1);
        end
        j = j+1;
        M_step = [];
    end
    i = i+1;
end

%%  Plot for verification if desired
if plt == 1
    figure(11)
    hold on
    plot(time/60, qsol, '-ob', 'markersize', 2, 'markerfacecolor', 'b');
    plot(M(1:i,1)/60, M(1:i,3), 'r');
    xlabel('Time (min)');
    ylabel('Solar Irradiation (W/m^2)')
    Figure_properties({11}, 3, 2.5);

    figure(12)
    hold on
    plot(time/60, Tx, '-ob','markersize', 2, 'markerfacecolor', 'b');
    plot(M(1:i,1)/60, M(1:i,2), 'r');
    xlabel('Time (min)');
    ylabel('Outside Air Temperature (^oF)')
    Figure_properties({12}, 3, 2.5);
end

end