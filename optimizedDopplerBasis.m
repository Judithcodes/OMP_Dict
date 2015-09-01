function B_m = optimizedDopplerBasis(DVBT2,L)


%%%%%%%% GENERATING THE REQUIRED VARIABLE FOR OPTIMIZATION %%%%%%%

%%%% Required parameters for optimization
NFFT = DVBT2.STANDARD.NFFT;  % FFT number of points 
TU = DVBT2.STANDARD.TU;     % Length in s of the OFDM symbol data part
GI = DVBT2.GI_FRACTION; % Guard Interval
SIM_DIR = DVBT2.SIM.SIMDIR;

%%%%%% Check if optimized basis for these parameters already present

param_new = [L; NFFT; TU; GI];

if(exist(strcat(SIM_DIR, filesep, 'OptimBasis.mat'),'file'))
    load(strcat(SIM_DIR, filesep, 'OptimBasis.mat'));
    paramCheck = param_new - param;
    if(isempty(find(paramCheck)))
        B_m = Dop_Basis;        
        return;
    end
end



%%%% Initial variables Basis for optimization
Ts = TU/NFFT; % Sampling Interval
nCP = NFFT*GI; % Cyclic prefic length
N = NFFT + nCP; % Symbol Duration
% L = 16;  %% Number of symbols Assumed value
J = L; %%% Assumütion where as J<=L
v_max = 0.25/TU;  %% maximum doppler shift
m = 0; %% for CP OFDM
rou = 1; %% The optimization constraint.
thresh = 1e-6;  %% Threshold on the optimization constraint
itr_limit = 100; %% Limit on the number of iterations for optimization
Nr = N*L; %% Approximation

B_m = dftmtx(J); %% Initial Basis for optimization

%%%%%% Generating the set of dopplers for optimization
v_d = 1/(2*Ts*Nr);
d_max = ceil(v_max / v_d);
d = (-d_max):d_max;
D = d * v_d;
Dop_num = length(D);

%%%% Generatating the J length vector c_m_v
c_m_v_mat = zeros(J,Dop_num);
for i = 1:Dop_num
    v = D(i);
    c_m_v = c_m_v_fun(NFFT,N,m,Ts,L,J,v);
    c_m_v_mat(:,i) = c_m_v;
end


%%%%% Optimization Using CVX
Aold = zeros(J,J);
Aupd_diff = [];
for loop = 1:itr_limit
    A = optim_basis_update(J,rou,B_m,c_m_v_mat);
    Aupd_diff = [Aupd_diff; sum(find(Aold - A))];
    Aold = A;
    
    %%% Just to check if the constraints on A are actually met or not
    if ( sum(sum(A ~= A')) || (norm(A,Inf) > rou))
        A = 0
    end
    basis_new_sum = 0;
    basis_old_sum = 0;

    for i = 1:Dop_num,
        basis_new =expm(1j*A)*B_m*c_m_v_mat(:,i);
        basis_new = norm(basis_new,1);
        basis_new_sum = basis_new_sum +basis_new;

        basis_old = B_m*c_m_v_mat(:,i);
        basis_old = norm(basis_old,1);
        basis_old_sum = basis_old_sum + basis_old;
    end

    if basis_new_sum < basis_old_sum
        B_m = expm(1j*A)*B_m;
    else
        rou = rou/2;
    end
    if rou < thresh
        break;
    end
end

param = param_new;
Dop_Basis = B_m;
save(strcat(SIM_DIR, filesep, 'OptimBasis'),'Dop_Basis','J','param');
end