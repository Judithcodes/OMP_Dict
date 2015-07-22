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
  %freqIndx = 1:NFFT;
  %freqIndx = freqIndx - (NFFT/2) - 1;
  %carSpacing = 1/TU;
  %freqIndx = 2 * pi * freqIndx * carSpacing;
  %hF_DS(k,:) = hF_DS(k,:) + exp(1j*( Phi(k) - freqIndx*Tau(k)*1e-6));
  %hT_DS(k,:) = fftshift(ifft(fftshift(hF_DS(k,:))));    
  h_sinc = fftshift(sinc(1*(Indx-(Tau(k)*1e-6)/ts)));
  hTD(k,:) = h_sinc;
  %hTD(k,:) = hT_DS(k,:);
  end

  num = floor(len/(NFFT + nCP));
  lenDop = 1*(NFFT + nCP);
  dataAux_c = zeros(length(Tau),len);
  dataNCh = zeros(1,len);
  for k = 1:length(Tau)
  dataCon = t2_rx_fconv(DVBT2, hTD(k,:), dataCP).';
  %dataCon = conv(hTD(k,:), dataCP).';
  doppIndx = 1*Fd(k)*(0:(lenDop-1));
  doppIndx = 2 * pi * doppIndx * ts;
  indx_ds = exp(1j*doppIndx);
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
 
 