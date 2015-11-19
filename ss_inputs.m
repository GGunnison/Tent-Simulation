function U = ss_inputs(Z, Tx, qsol, Ql, uz)

% Function creates nominal input matrix.

U = zeros(length(Tx),1+Z*3);    % prealocate U matrix
U(:,1) = Tx;    % insert external temperature

% loop through for number of tents and fill in nominal input vectors
for xx = 1:Z
    U(:,3*(xx-1)+2) = qsol;
    U(:,3*(xx-1)+3) = Ql;
    U(:,3*(xx-1)+4) = uz(:,xx); 
    
end

U = U';
end
