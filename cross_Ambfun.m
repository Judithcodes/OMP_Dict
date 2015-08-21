%%%%%%%%%%%%%%%%Generating the Cross Ambiguiy function
%%%%% Inputs %%%%
% NFFT : FFT number of points 
% N : Symbol Duration in samples
% m : Delay part for CP OFDM m = 0
% xi : The doppler part

%%%%% Outputs %%%
% A : Cross Ambiguity value


function Amat = cross_Ambfun(NFFT,N, m, xi)

%%% Generating the approriate pulses
% Transmit pulse
n = m:(N-1+m);
g = zeros(1,N+m);
g(n+1) = 1;

% Receive pulse
n = (N-NFFT):(N-1);
r = zeros(1,N+m); 
r(n+1) = 1;


%%% Generating the Cross Ambiguity function
%%% Only generate for m =0 
n = 0:(N-1+m);
Amat = xi*0;
for i = 1:length(xi)
    val_expo = exp(-1j*2*pi*xi(i)*n);
    g_st = conj(g);

    A = r.* g_st .* val_expo;
    A = sum(A);  %% Might or might not need to normalize has some effect on the optimization. However mathematically it should have a maximum value of 1
    Amat(i) = A;
end

end