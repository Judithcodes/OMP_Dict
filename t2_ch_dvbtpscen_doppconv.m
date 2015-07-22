function DataOut = t2_ch_dvbtpscen_doppconv(DVBT2, DataIn, Ro, Tau, Phi, Fd, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
    case 6,
        FidLogFile = 1; % Standard output
    case 7,
    otherwise,
      error('t2_ch_dvbtpscen_dopconv SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
TU    = DVBT2.STANDARD.TU;    % Length in s of the OFDM symbol data part
NFFT  = DVBT2.STANDARD.NFFT;  % Number of points per OFDM symbol
CHSTR = DVBT2.CH.PSCEN.CHSTR; % Channel structure 
SIM_DIR      = DVBT2.SIM.SIMDIR;          % Saving directory
ts = TU/NFFT;
GUARD_INT = 1/DVBT2.GI_FRACTION; % Guard interval 
nCP = fix(NFFT/GUARD_INT); % Number of samples of cyclic prefix

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
% Avoid convolution for AWGN channel
chanType = CHSTR.TYPE;
chanType = upper(chanType);  

if strcmp(chanType,'DVBT-P')
    %{
  %cos_array = [cosd(0) cosd(90) cosd(15) cosd(30) cosd(45) cosd(60)];
  %cos_array = [cosd(30) cosd(0) cosd(15) cosd(90) cosd(45) cosd(60)];
  %cos_array = [cosd(30) cosd(45) cosd(15) cosd(90) cosd(0) cosd(60)];
  %cos_array = [cosd(0) cosd(0) cosd(0) cosd(0) cosd(0) cosd(0)];
  %cos_array = rand(1,6);
  %Fd = Fd.*cos_array(1:length(Tau))';

  hF_DS = zeros(length(Tau),NFFT);
  hT_DS = zeros(length(Tau),NFFT);
  hTD = zeros(length(Tau),NFFT);
  
  for k = 1:length(Tau)
  % Frequency vector
  freqIndx = 1:NFFT;
  freqIndx = freqIndx - (NFFT/2) - 1;
  carSpacing = 1/TU;
  freqIndx = 2 * pi * freqIndx * carSpacing;
  hF_DS(k,:) = hF_DS(k,:) + Ro(k) * exp(1j*( Phi(k) - freqIndx*Tau(k)*1e-6));
  hT_DS(k,:) = fftshift(ifft(fftshift(hF_DS(k,:))));    
  hTD(k,:) = hT_DS(k,:);
  end
  
  fprintf('\tChannel Doppler shift: %d\n', Fd);
  
  %conv_len = NFFT + length(DataIn) - NFFT/2 - 1;
  num = floor(length(DataIn)/(NFFT + nCP));
  lenDop = 1*(NFFT + nCP);
  dataAux_c = zeros(length(Tau),length(DataIn));
  dataNCh = zeros(1,length(DataIn));
  for k = 1:length(Tau)
  dataCon = conv(hTD(k,:), DataIn);
  doppIndx = Fd(k)*(0+0*NFFT:(lenDop+0*NFFT-1));
  doppIndx = 2 * pi * doppIndx * ts;
  indx_ds = exp(1j*doppIndx);
  indx_ds = repmat(indx_ds,1,num);
  dataCon = dataCon((NFFT/2+1):length(DataIn)+(NFFT/2)).';  
  dataAux_c(k,:) = indx_ds.*dataCon;
  dataNCh = dataNCh + dataAux_c(k,:);
  end
%}
  %dataAux = conv(hT_DSS, DataIn);
  %dataNCh = dataAux(((NFFT/2)+1):end).';
  %save(strcat(SIM_DIR, filesep, 'H_CIR'),'hT_DSS')
  %len = length(DataIn)/(nCP+NFFT);
  %dat = zeros(len,NFFT);
  %for i = 1:len
  %    dat(i,:) = DataIn(nCP*i+NFFT*(i-1)+1:(nCP+NFFT)*i);
  %end
  %save(strcat(SIM_DIR, filesep, 'dat'),'dat')

%------------------------------------------------------------------------------
%%{
Fd_norm = (1/ts)/NFFT;
chan = rayleighchan(1/(64e6/7), Fd_norm*0.2*0.00001, Tau' * 1e-6, mag2db(Ro)');
%chan = rayleighchan(1/(64e6/7), 0.0001, 1 * 1e-6, mag2db(1)');
%legacychannelsim(true)
%reset(chan,randi(100));
reset(chan);
chan.ResetBeforeFiltering = 1;                           
%%% Approximately Linear Doppler
dop_rounded = doppler.rounded([1.0 0 0]);
chan.DopplerSpectrum = dop_rounded;

chan.ResetBeforeFiltering = 1;
%chan.StoreHistory = 1;
%chan.StorePathGains = 1;
(chan.PathGains).'
dataAux_chan = filter(chan, DataIn);
dataNCh = dataAux_chan;
%dataNCh(3000:3010)
%}
%{
      Chan_Len = 64;
      h = zeros(length(DataIn),Chan_Len);
      ch_fil_delay = chan.ChannelFilterDelay;
      chan_discrete=[-1*ch_fil_delay:1:Chan_Len-ch_fil_delay-1]; %% must consider the channel filter delay
      for ch_index=1:1:length(chan.PathDelays)
           Samping_vec = sinc(chan.PathDelays(ch_index)./ts-chan_discrete);
           h=h+chan.PathGains(:,ch_index)*Samping_vec;
      end
      save(strcat(SIM_DIR, filesep, 'h'),'h')
%}
%{
%% WINNER II channel model parameters
NS = N*Nsym;      % number of samples
CF = f0;          % carrier frequency
SF = bandwidth;   % sampleing frequency
mV = 41.67;       % mobile velocity in m/s
CH = 15;          % WINNER II channel model No.
WIM_input = [];   % inialization
fdmax = mV/(3e8/f0);   %% maximum Doppler shift (Hz)   
theta_max = fdmax/(bandwidth/K);

      disp('Generate channel matrix!')
      
      h=zeros(NS,Chan_Len);
      [HT, convHT,Chan_Delay,out] = t2_ch_generate_WINII_CIR(DVBT2, FidLogFile,CF,SF,mV,NS,CH,WIM_input);
      WIM_input = out;  % for the next simulation round

      h(:,1:length(Chan_Delay))=HT;  % construct the virtual HT
      
      toc
      
      fadedSig = convHT*xT_send;
%}
else % If channel is AWGN    
  dataNCh = DataIn;
end

DataOut = dataNCh;