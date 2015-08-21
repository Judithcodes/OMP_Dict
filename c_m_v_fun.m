%%%%% Generatating the J length vector c_m_v which is the doppler part of
%%%%% the channel on which the Basis optimization is carried out.

%%%%% Inputs %%%%
% NFFT
% N : % Symbol Duration  
% m : Delay part for CP OFDM this is zero
% Ts : Sampling Interval
% L : Number of transmitted Symbols
% J : Doppler
% v : The doppler frequency from the set D for which c_m_v needs to be calculated 


%%%%% Output %%%
% c_m_v : Doppler part of the channel for which basis optimization will be carried out


function c_m_v = c_m_v_fun(NFFT,N,m,Ts,L,J,v)

m = 0; %% for CP OFDM
Nr = N*L; %% Approximation
c_m_v = [];

for lemda = 0:J-1
    C_v = 0;
    for i = (-J/2):(J/2-1)
%         for q = 0:N-1
            q = 0:N-1;
            ind = i + (q*L);
            SI_v = si_v_fun(Ts,Nr,ind,v);

            ind = ind/Nr;
            A_rg =  cross_Ambfun(NFFT,N, m, ind);
            A_rg = conj(A_rg);

            ind = 1j*2*pi*lemda*i/J;
            c = SI_v .* A_rg .* exp(ind);
            C_v = C_v + sum(c);
%         end
    end
    c_m_v = [c_m_v; C_v];
end
% c_m_v = c_m_v.';
end