%%%%% Inputs %%%%
% Ts : Sampling Interval
% Nr = N*L [N:  Symbol Duration and  L : Number of transmitted Symbols
% i : The input value for which SI_v needs to be calculated (doppler frequency)
% v1 : The doppler frequency from the set D for which SI_v needs to be calculated 

%%%%% Output %%%
% SI_v


function SI_v = si_v_fun(Ts,Nr,i,v1)
y = i - (v1*Ts*Nr);
si = sin(pi*y)./ (Nr*sin(pi*y/Nr));
if find(y == 0)
    si(find(y == 0)) = 1;
end
ind = (v1*Ts) - (i/Nr);
ind = 1j*pi*ind;
ind = ind*(Nr-1);

SI_v = exp(ind) .* si;
end