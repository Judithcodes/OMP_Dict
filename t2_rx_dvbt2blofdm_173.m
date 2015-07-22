function DataOut = t2_rx_dvbt2blofdm(DVBT2, FidLogFile, DataIn, Fd)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 4,
  otherwise,
    error('t2_rx_dvbt2blofdm SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
MODE     = DVBT2.MODE;           % DVBT mode
C_LOC    = DVBT2.STANDARD.C_LOC; % Carriers location
NFFT     = DVBT2.STANDARD.NFFT;  % FFT number of points
TU         = DVBT2.STANDARD.TU;     % Length in s of the OFDM symbol data part
L_F         = DVBT2.STANDARD.L_F;       % Symbols per frame
SP_PATTLEN  = DVBT2.STANDARD.SP_PATTLEN; % Scattered pilots pattern length
SP_LOC      = DVBT2.STANDARD.SP_LOC;     % Scattared pilots locations
SP_FNAME   = DVBT2.RX.SP_FDO;      % SP file

SIM_DIR      = DVBT2.SIM.SIMDIR;          % Saving directory
MISO_ENABLED = DVBT2.MISO_ENABLED;
SNR           = DVBT2.CH.NOISE.SNR;     % Signal to noise ratio (dB)
GUARD_INT = 1/DVBT2.GI_FRACTION; % Guard interval 
nCP = fix(NFFT/GUARD_INT); % Number of samples of cyclic prefix
NFFT     = DVBT2.STANDARD.NFFT;  % FFT number of points
C_PS     = DVBT2.STANDARD.C_PS;
C_L = 0;%(NFFT - C_PS - 1)/2 + 1;

ts = TU/NFFT;
%p = sum(DataIn.*conj(DataIn))/length(DataIn);
snr = 10^(SNR/10);
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

fprintf(FidLogFile,'\t\tMode=%s\n', MODE);
if MISO_ENABLED
else
    misoGroup = 1;
end

dataAux = (sqrt(27*C_PS)/(5*NFFT))*fft(DataIn, NFFT, 2);
data_noncorrected = fftshift(dataAux, 2);
data = data_noncorrected(:, C_LOC);
y = DataIn;
x = DataIn;

% ----------------------------------------------------------------
      % Separate SP here and save them to file
      numSymb = size(data,1);
            
        for symbIdx = 1:numSymb   % for each symbol
            symbInFrame = mod(symbIdx-1, L_F);
            % Get scattered pilot locations
            spLoc = SP_LOC(mod(symbInFrame,SP_PATTLEN)+1, :);
            spLoc = spLoc(find(spLoc>0));
            % Assign pilot signals before marking them
            spLoc_rx_my = data(symbIdx,C_L+spLoc);
            if symbIdx==1
                spLoc_rx_m_array = zeros(numSymb,length(spLoc_rx_my));
                p_sp_rx_m_array = zeros(numSymb,length(data_noncorrected(1,:)));
            end
             spLoc_rx_m_array(symbIdx,1:length(spLoc_rx_my)) = spLoc_rx_my;
             p_data = zeros(1,length(C_LOC));
             p_data(spLoc) = spLoc_rx_my;
             p_sp_rx_m_array(symbIdx,C_LOC) = p_data;
        end

        % Write scattered pilot to file
        if ~strcmp(SP_FNAME, '')
         save(strcat(SIM_DIR, filesep, SP_FNAME),'spLoc_rx_m_array')
         fprintf(FidLogFile,'\t\tScattered pilot output  saved in file: %s\n',...
         SP_FNAME);
        end

% ----------------------------------------------------------------
        h = ifft(fftshift(p_sp_rx_m_array(1,:)));
        acf = autocorr(h, 100);
        lag = 0:1:100;
        fd = 0;
                bes = besselj(0,2*pi*0*lag);
        sum(acf - bes);
% ----------------------------------------------------------------
       %data_che_est = t2_rx_ompalg_full(DVBT2, FidLogFile);
       %data_che_est = t2_rx_bmpalg_full(DVBT2, FidLogFile);
       data_che_est = t2_rx_ompalg_173(DVBT2, FidLogFile);

      %F = dftmtx(NFFT);
      %F_H = conj(F);

     % Get the delay, atenuation, phase and doppler frequency
      load(strcat(SIM_DIR, filesep, 'sp_tx_do'), 'spLoc_tx_m_array'); % Load data
      chSeed = 1000*rand(1);
      ChParams = t2_ch_dvbtpscen_getch(DVBT2, chSeed, FidLogFile);
      ro  = ChParams.ro(:,misoGroup);
      tau = ChParams.tau(:,misoGroup);
      phi = ChParams.phi(:,misoGroup);
      fd  = ChParams.fd(:,misoGroup);
      cos_array = [cosd(90) cosd(0) cosd(15) cosd(30) cosd(45) cosd(60)];
      cos_array = [cosd(30) cosd(45) cosd(15) cosd(90) cosd(0) cosd(60)];
      fd = fd.*cos_array(1:length(tau))';
  
      fn = strcat('DVBT2_chan', num2str(SNR),'.mat');
      load(strcat(SIM_DIR, filesep, fn),'chan')
      [num len] = size(dataAux);
      %C_L = (NFFT - C_PS - 1)/2 + 1;
      
% ----------------------------------------------------------------
      for ii = 1:(num-1)
          f1 = find(chan.ro(ii,:)==-1);
          if length(f1)>0
              f1 = f1(1)-1;
          else
              f1 = length(chan.ro(ii,:));
          end
          ro1 = (chan.ro(ii,1:f1));
          f2 = find(chan.ro(ii+1,:)==-1);
          if length(f2)>0
              f2 = f2(1)-1;
          else
              f2 = length(chan.ro(ii+1,:));
          end
          ro2 = (chan.ro(ii+1,1:f2));
          f = min([f1 f2]);
      tau = (chan.tau(ii,1:f));
      tau2 = (chan.tau(ii+1,1:f));
      %}
      phi = zeros(1,length(tau));
      
      hT_DS = zeros(length(tau),NFFT);
      hT_DS2 = zeros(length(tau),NFFT);
      hTD = zeros(length(tau),NFFT);  
      hTD2 = zeros(length(tau),NFFT);  
      hF_DS = zeros(length(tau),NFFT);
      hF_DS2 = zeros(length(tau),NFFT);

        for k = 1:length(tau)
  freqIndx = 1:NFFT;
  freqIndx = freqIndx - (NFFT/2) - 1;
  carSpacing = 1/TU;
  freqIndx = 2 * pi * freqIndx * carSpacing;
  hF_DS(k,:) = hF_DS(k,:) + 1 * exp(1j*( phi(k) - freqIndx*tau(k)*1e-6));
  hT_DS(k,:) = fftshift(ifft(fftshift(hF_DS(k,:))));    
  hTD(k,:) = hT_DS(k,:);
  if ii == (num-1)
  hF_DS2(k,:) = hF_DS2(k,:) + 1 * exp(1j*( phi(k) - freqIndx*tau2(k)*1e-6));
  hT_DS2(k,:) = fftshift(ifft(fftshift(hF_DS2(k,:))));    
  hTD2(k,:) = hT_DS2(k,:);
  end
        end
  hT_DSS = (hTD(:,:));
  hT_DSS2 = (hTD2(:,:));
% ----------------------------------------------------------------
for t = 1:length(tau)
hT_DSS(t,:) = fftshift(hT_DSS(t,:));
hT_DSS2(t,:) = fftshift(hT_DSS2(t,:));
end

          G = 2;
          A = zeros(G, G);
          for i = 0:(G-1)
              for v = 0:(G-1)
                  summ = 0;
                  for n = 0:(NFFT-1)
                      summ = summ + (i*(NFFT + nCP)+n)^v;
                  end
                  A(i+1,v+1) = summ/NFFT;
              end
          end

          Doppler_coef = zeros(f,NFFT);
          Doppler_coef2 = zeros(f,NFFT);
          for p = 1:f
          h_l = zeros(G,1);
          h_l(1,1) = ro1(p);
          h_l(2,1) = ro2(p);
          c_l = inv(A)*h_l;
          for dop = 1:NFFT
              summ = 0;
              summ2 = 0;
              for v = 0:(G-1)
                  summ = summ + c_l(v+1)*(0*(NFFT+nCP)+dop)^v;
                  summ2 = summ2 + c_l(v+1)*(1*(NFFT+nCP)+dop)^v;
              end
          Doppler_coef(p,dop) = summ;
          Doppler_coef2(p,dop) = summ2;
          end
          end
          
          BEM_Cf = [hT_DSS];
          BEM_Cf2 = [hT_DSS2];
          BEM_seq = [Doppler_coef(:,1:NFFT)];
          BEM_seq2 = [Doppler_coef2(:,1:NFFT)];
          x(ii,:) = (t2_rx_ChanEq_FFT_LSQR((y(ii,:)), 1:NFFT, BEM_Cf, BEM_seq, 30));
      end
          x(ii+1,:) = (t2_rx_ChanEq_FFT_LSQR((y(ii+1,:)), 1:NFFT, BEM_Cf2, BEM_seq2, 30));

% ----------------------------------------------------------------

% ----------------------------------------------------------------
% Iterative    
% ----------------------------------------------------------------
%dataAux_lmmse = (sqrt(27*C_PS)/(5*NFFT))*fft(x, NFFT, 2);
dataAux_lsqr = (sqrt(27*C_PS)/(5*NFFT))*(fft(x, NFFT, 2));

% ----------------------------------------------------------------

% FFT shift
%dataAux = fftshift(dataAux, 2);
%dataAux = fftshift(DataEqualized, 2);
%dataAux = fftshift(dataAux_lmmse, 2);
dataAux = fftshift(dataAux_lsqr, 2);

%dataAux.'

hEstCh = data_noncorrected./dataAux;
save(strcat(SIM_DIR, filesep, 'hEstCh'),'hEstCh')

% Get only the useful carriers 
DataOut = dataAux(:, C_LOC);


