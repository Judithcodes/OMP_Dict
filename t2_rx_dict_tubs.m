function DataOut = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1, dataCP, SymbIndx, type, kk, ll)
%************ DICTIONARY ************
%* 
%------------------------------------------------------------------------------
TU    = DVBT2.STANDARD.TU;    % Length in s of the OFDM symbol data part
NFFT     = DVBT2.STANDARD.NFFT;  % FFT number of points
C_PS     = DVBT2.STANDARD.C_PS;
GUARD_INT = 1/DVBT2.GI_FRACTION; % Guard interval 
nCP = fix(NFFT/GUARD_INT); % Number of samples of cyclic prefix
C_L = (NFFT - C_PS - 1)/2 + 1;
ts = TU/NFFT;
len = NFFT + nCP;
%------------------------------------------------------------------------------
switch(nargin)
  case 8,
  otherwise,
    error('t2_rx_dvbt2blrotcondmap SYNTAX');
end

  % CHANNEL   
  Phi = 0;
  Fd = ll;
  Tau = kk;
  hF_DS = zeros(length(Tau),NFFT);
  hT_DS = zeros(length(Tau),NFFT);
  hTD = zeros(length(Tau),NFFT);
  
  for k = 1:length(Tau)
% Frequency vector
  Indx = 0:(NFFT-1);
  
  %%%%%%%%%%%%%%%%%%%%% DELAY ATOM%%%%%%%%%%%%%%%%%%%
  
  %%%Fourier Atoms
  freqIndx = 1:NFFT;
  freqIndx = freqIndx - (NFFT/2) - 1;
  carSpacing = 1/TU;
  freqIndx = 2 * pi * freqIndx * carSpacing;
  hF_DS(k,:) = hF_DS(k,:) + exp(1j*( Phi(k) - freqIndx*Tau(k)*1e-6));
  hT_DS(k,:) = fftshift(ifft(fftshift(hF_DS(k,:)))); 
  hTD(k,:) = hT_DS(k,:);

  
  
  %%% Sinc Atoms
%   h_sinc = fftshift(sinc(1*(Indx-(Tau(k)*1e-6)/ts)));
%   hTD(k,:) = h_sinc;


%%% Gabor Atom
%%% Dialation by ts and translation via Tau
%%%Not working
%     Index_new = (Indx*ts -(Tau(k)*1e-6)).^2;
%     Index_new = Index_new/((ts).^2);
%     dic_Ind = exp(-Index_new);
%     hTD(k,:) = hTD(k,:) + fftshift(dic_Ind);



%%% Wavelet(Shannon) Atoms
%%% Dialation by ts and translation via Tau
%     Index_new = Indx -(Tau(k)*1e-6)/ts;
%     dic_Ind = (2*sinc(2*Index_new) - sinc(Index_new))/sqrt(ts);
%     hTD(k,:) = fftshift(dic_Ind);

    
%%% Raised cosine Filter with Wavelet(Shannon) Atoms
%%% Dialation by ts and translation via Tau
%     rol = 0.025;
%     Index_new = Indx -(Tau(k)*1e-6)/ts;
%     dic_Ind = (2*sinc(2*Index_new) - sinc(Index_new))/sqrt(ts);
%     Filt = cos(rol.*pi.*Index_new)./(1-((2.*rol.*Index_new).^2));
%     hTD(k,:) = fftshift(dic_Ind.*Filt);
  
  

 %%% raised cosine filter with sinc Atoms
%   rol = 0.25; %0.025; % Old simulations
%   Indx_f = 1*(Indx-(Tau(k)*1e-6)/ts);
%   Filt = cos(rol.*pi.*Indx_f)./(1-((2.*rol.*Indx_f).^2));
%   h_sinc = fftshift(sinc(Indx_f).*Filt);
%   hTD(k,:) = h_sinc;


  %Raised Cosine filter with Fourier Atoms
  
%   rol = 0.25; %0.025; % Old simulations
%   Indx_f = 1*(Indx-(Tau(k)*1e-6)/ts);
%   Filt = cos(rol.*pi.*Indx_f)./(1-((2.*rol.*Indx_f).^2)); 
%   freqIndx = 1:NFFT;
%   freqIndx = freqIndx - (NFFT/2) - 1;
%   carSpacing = 1/TU;
%   freqIndx = 2 * pi * freqIndx * carSpacing;
%   hF_DS(k,:) = hF_DS(k,:) + exp(1j*( Phi(k) - freqIndx*Tau(k)*1e-6));
%   hT_DS(k,:) = fftshift(ifft(fftshift(hF_DS(k,:))).*Filt); 
%   hTD(k,:) = hT_DS(k,:);
 
  end

  num = floor(len/(NFFT + nCP));
  lenDop = 1*(NFFT + nCP);
  dataAux_c = zeros(length(Tau),len);
  dataNCh = zeros(1,len);
  for k = 1:length(Tau)
  dataCon = t2_rx_fconv(DVBT2, hTD(k,:), dataCP).';
  %dataCon = conv(hTD(k,:), dataCP).';

 %%%%%%%%%%%%%%%%%%%%% DOPPLER ATOM%%%%%%%%%%%%%%%%%%%  
  
%%% Fourier Dictionary
%   doppIndx = 1*Fd(k)*(0:(lenDop-1));
%   doppIndx = 2 * pi * doppIndx * ts;
%   indx_ds = exp(1j*doppIndx);


%%%% cosine dictionary
  doppIndx = 0:(lenDop-1);
  Fd_disc = Fd(k)*ts;
%   indx_ds = cos(2.*pi.*Fd_disc.* doppIndx); %DCT-I
%   
%   indx_ds = exp(indx_ds); % exponential DCT

  indx_ds = cos(pi.*(doppIndx +1/2).*Fd_disc); %DCT-II
  


  
%%%% gabor dictionary
%     Indx1 = 0:lenDop-1;
%     doppIndx = Indx1*ts - (Tau(k)*1e-6);
%     doppIndx = 2*pi*Fd(k)*doppIndx;
%     indx_ds = cos(doppIndx + Phi(k));


%%% Wavelet(Shannon) Atoms
%%% Dialation by (1/TU) and translation via Fd
%%% Not working
%   doppIndx = 1:lenDop;
%   doppIndx = doppIndx - (lenDop/2) -1;
%   carSpacing = 1/TU;
%   doppIndx = doppIndx -Fd(k)/(carSpacing);
%   dic_Ind = (2*sinc(2*doppIndx) - sinc(doppIndx))/sqrt(carSpacing);
%   indx_ds = fftshift(ifft(fftshift(dic_Ind))); 
  


%%% Wavelet(Morlet) Atom
%%% Dialation by (ts) and translation via Fd
%%% 
%   doppIndx = 0:(lenDop-1);
%   doppIndx = doppIndx*ts;% - (Tau(k)*1e-6);
%   dic_Ind = exp(1j*2*pi*Fd(k).*doppIndx).*exp(-(doppIndx.^2)/2)./(pi.^(1/4));
%   indx_ds= dic_Ind;

  
  
  %indx_ds_rev = exp(-1j*doppIndx);
  indx_ds = repmat(indx_ds,1,num);
  dataCon = dataCon((NFFT/2+1):len+(NFFT/2)).';  
  dataAux_c(k,:) = indx_ds.*dataCon;
  dataNCh = dataNCh + dataAux_c(k,:);
  end
  
dataNCh = dataNCh(nCP + (1:NFFT));
spLoc_rx_m_array = zeros(1, length(loc1));
dataAux = (sqrt(27*C_PS)/(5*NFFT))*fft(dataNCh, NFFT, 2);
dataAux = fftshift(dataAux, 2);

% separating Doppler shift part
%indx_ds_rev = indx_ds_rev(nCP+1:nCP+NFFT);
%pil1 = indx_ds_rev.*dataAux;
pil1 = dataAux;
spLoc_rx_m_array(1,1:length(loc1)) = pil1(C_L + loc1);

DataOut = spLoc_rx_m_array;
end
 
 