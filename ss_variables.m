function [A, B, C, D] = ss_variables(Z, Qz, kz, Rz, Cz)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    A = -1/(Cz*Rz)*eye(Z);
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

