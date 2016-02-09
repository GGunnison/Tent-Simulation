function [A, B, C, D] = ss_variables(Z, Qz, kz, Rz, Cz)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ReadWeather
%
%  Grant Gunnison, Peter Lindahl
%  Last Update: 11/19/2015
%
%  This function takes in a number of parameters about our tent system and
%  generates the appropriate matricies for each state variable. These 
%  variables are created for the purpose of feeding them into the ss() 
%  function to model the system. 
%
%  Inputs:  (1)  Z    = Number of Tents
%           (2)  Qz   = Internal loads present in tents
%           (3)  Rz   = Resistance value for each tent
%           (4)  Cz   = Capacitance value for each tent
%
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
%  Output:  (1)  A    = Diagonal matrix of the negative time constant for
%                       each tent
%           (2)  B    = Matrix describing the inputs to the system for a
%                       variable number of tent inputs.
%           (3)  C    = Identity matrix of size Z
%           (4)  D    = Matrix of zeros, D is not in use. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

    A = -1/(Rz*Cz)*eye(Z);
    C = eye(Z);
    first = 1./(Rz*Cz);
    variables = [kz/Cz, 1/Cz, Qz/Cz];
    B= [];
    for i = 0:Z-1
        front = horzcat(first, zeros(1, i*3));
        middle = horzcat(front, variables);
        final = horzcat(middle, zeros(1, (Z-i-1)*3));
        B = [B;final];
    end
    D = zeros(size(B));

end

