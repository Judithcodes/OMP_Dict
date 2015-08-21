function A = optim_basis_update(J,rou,B_m,c_m_v_mat)

X_arg = [];
I_j = eye(J);
Dop_num = size(c_m_v_mat,2);
cvx_begin
    variable A(J,J) hermitian
%     norm(A,Inf) <= rou;  %% This also works but the subject to looks better
    for i = 1:Dop_num,
        X_arg_temp= (I_j + 1j*A)*B_m*c_m_v_mat(:,i);
        X_arg_temp = norm(X_arg_temp,1);
        X_arg = [X_arg  X_arg_temp];
    end
    X_arg = sum(X_arg);
    minimize(X_arg);
    subject to
        norm(A,Inf) <= rou;
cvx_end
X_arg
end