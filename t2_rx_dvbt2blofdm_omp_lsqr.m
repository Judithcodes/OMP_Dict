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
% ----------------------------------------------------------------

for ii = 1:num
%{
    ii
% BEM channel estimation
% ----------------------------------------------------------------
%H_c = t2_rx_BEM_full(DVBT2, FidLogFile, data_noncorrected(ii,:).',ii);
  Y = data_noncorrected(ii,:).';
  D = 2;
  I = 2;
  Type = 'LP'; % data symbol
  K = length(Y);
  numSymb = length(find(abs(spLoc_tx_m_array(ii,:))>0));
  if mod(numSymb,2)
      numSymb = numSymb - 1;
  end
        % Get scattered pilot locations
        symbInFrame = mod(ii-1, L_F);
        spLoc = SP_LOC(mod(symbInFrame,SP_PATTLEN)+1, :);
        spLoc = spLoc(find(spLoc>0));
        P0 = C_L+1;
        Ps = spLoc_tx_m_array(ii,1:numSymb);
        [T BEM_seq] = t2_rx_construct_OP_Matrix(DVBT2, FidLogFile, D,I,K,Type);
        BEM_Cf = t2_rx_BEM_ChanEst_OP(DVBT2, FidLogFile, Y,Ps,P0,D,numSymb,I,T,spLoc(1:numSymb));
        %CS_eval = BEM_Cf.'*BEM_seq;
        
%CIR = (BEM_Cf.'*BEM_seq).';
%[hLoc, hO] = t2_rx_init_TDChan_matrix(DVBT2, FidLogFile, K, numSymb);
%H_c = t2_rx_build_TDFChan_matrix(DVBT2, FidLogFile,CIR,hO,hLoc,K,numSymb);
x(ii,:) = (t2_rx_ChanEq_FFT_LSQR((y(ii,:)), 1:NFFT, BEM_Cf, BEM_seq, 20));
%}
% ----------------------------------------------------------------
%%{
      f = find(chan.ro(ii,:)==-1);
      if length(f)>0
          f = f(1)-1;
      else
          f = length(chan.ro(ii,:));
      end
       
      ro = (chan.ro(ii,1:f));
      tau = (chan.tau(ii,1:f));
      fd = (chan.fd(ii,1:f));
      %}
      phi = zeros(1,length(tau));
      
      hT_DS = zeros(length(tau),NFFT);
      hTD = zeros(length(tau),NFFT);  
      hF_DS = zeros(length(tau),NFFT);

        for k = 1:length(tau)
  freqIndx = 1:NFFT;
  freqIndx = freqIndx - (NFFT/2) - 1;
  carSpacing = 1/TU;
  freqIndx = 2 * pi * freqIndx * carSpacing;
  hF_DS(k,:) = hF_DS(k,:) + ro(k) * exp(1j*( phi(k) - freqIndx*tau(k)*1e-6));
  hT_DS(k,:) = fftshift(ifft(fftshift(hF_DS(k,:))));    
  hTD(k,:) = hT_DS(k,:);
        end

  hT_DSS = (hTD(:,:));
% ----------------------------------------------------------------
h_m = zeros(length(tau),NFFT);
lenDop = 1*(NFFT + nCP);
indx_ds = zeros(length(tau),NFFT);
for t = 1:length(tau)
hT_DSS(t,:) = fftshift(hT_DSS(t,:));
doppIndx = fd(t)*(0:(lenDop-1));
doppIndx = 2 * pi * doppIndx * ts;
doppIndx = exp(1j*doppIndx);
indx_ds(t,:) = doppIndx(nCP+1:nCP+NFFT);
end
for t = 1:length(tau)
    for r = 1:NFFT
        %h_m(t,r) = hT_DSS(t,NFFT-r+1);
    end
end
%H_c = zeros(NFFT,NFFT);
for c = 1:NFFT
    %row = zeros(1,NFFT);
    for t = 1:length(tau)
        %row = row + indx_ds(t, c)*circshift(h_m(t,:), [1 c]);
    end
%H_c(c,1:NFFT) = row;
end
BEM_Cf = hT_DSS;
BEM_seq = indx_ds(:,1:NFFT);
%CIR = (BEM_Cf.'*BEM_seq).';
x(ii,:) = (t2_rx_ChanEq_FFT_LSQR((y(ii,:)), 1:NFFT, BEM_Cf, BEM_seq, 30));
%{
CIR = (BEM_Cf.'*BEM_seq);
[hLoc, hO] = t2_rx_init_TDChan_matrix(DVBT2, FidLogFile, NFFT, NFFT);
H_c = t2_rx_build_TDFChan_matrix(DVBT2, FidLogFile,CIR,hO,hLoc,NFFT,numSymb);
%}
%x(ii,:) = conj(H_c)*inv(H_c*conj(H_c) + eye(NFFT)/snr)*y(ii,:).';
%x(ii,:) = conj(H_c)*pinv(H_c*conj(H_c) + eye(NFFT)/snr)*y(ii,:).';
%A = (H_c*conj(H_c) + eye(NFFT)/snr);
%x(ii,:) = conj(H_c)*(A\(y(ii,:).'));
%clear A;
%clear H_c;
end
%A = F*H_c*F_H;
%A_inv = NFFT*inv(A);

%DataEqualized = dataAux;
for n = 1:num
%DataEqualized(n,:) = A_inv*DataEqualized(n,:).';
end







% ----------------------------------------------------------------
% Iterative
for it = 1:6
%{
DataIn = x;
dataAux = (sqrt(27*C_PS)/(5*NFFT))*fft(DataIn, NFFT, 2);
data_noncorrected = fftshift(dataAux, 2);
data = data_noncorrected(:, C_LOC);
x = DataIn;
y = DataIn;

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
            end
             spLoc_rx_m_array(symbIdx,1:length(spLoc_rx_my)) = spLoc_rx_my;
        end
          
        % Write scattered pilot to file
        if ~strcmp(SP_FNAME, '')
         save(strcat(SIM_DIR, filesep, SP_FNAME),'spLoc_rx_m_array')
         fprintf(FidLogFile,'\t\tScattered pilot output  saved in file: %s\n',...
         SP_FNAME);
        end
        
       data_che_est = t2_rx_ompalg_full(DVBT2, FidLogFile);
       
      fn = strcat('DVBT2_chan', num2str(SNR),'.mat');
      load(strcat(SIM_DIR, filesep, fn),'chan')
      [num len] = size(dataAux);
      
for ii = 1:num
% BEM channel estimation
% ----------------------------------------------------------------
%%{
      f = find(chan.ro(ii,:)==-1);
      if length(f)>0
          f = f(1)-1;
      else
          f = length(chan.ro(ii,:));
      end
       
      ro = (chan.ro(ii,1:f));
      tau = (chan.tau(ii,1:f));
      fd = (chan.fd(ii,1:f));
      %%}
      phi = zeros(1,length(tau));
      
      hT_DS = zeros(length(tau),NFFT);
      hTD = zeros(length(tau),NFFT);  
      hF_DS = zeros(length(tau),NFFT);

        for k = 1:length(tau)
  freqIndx = 1:NFFT;
  freqIndx = freqIndx - (NFFT/2) - 1;
  carSpacing = 1/TU;
  freqIndx = 2 * pi * freqIndx * carSpacing;
  hF_DS(k,:) = hF_DS(k,:) + ro(k) * exp(1j*( phi(k) - freqIndx*tau(k)*1e-6));
  hT_DS(k,:) = fftshift(ifft(fftshift(hF_DS(k,:))));    
  hTD(k,:) = hT_DS(k,:);
        end

  hT_DSS = (hTD(:,:));
% ----------------------------------------------------------------
lenDop = 1*(NFFT + nCP);
indx_ds = zeros(length(tau),NFFT);
for t = 1:length(tau)
hT_DSS(t,:) = fftshift(hT_DSS(t,:));
doppIndx = fd(t)*(0:(lenDop-1));
doppIndx = 2 * pi * doppIndx * ts;
doppIndx = exp(1j*doppIndx);
indx_ds(t,:) = doppIndx(nCP+1:nCP+NFFT);
end
BEM_Cf = hT_DSS;
BEM_seq = indx_ds(:,1:NFFT);
x(ii,:) = (t2_rx_ChanEq_FFT_LSQR((y(ii,:)), 1:NFFT, BEM_Cf, BEM_seq, 30));
%%}
clear H_c;
end
       %}
end
       
       
       
 


% ----------------------------------------------------------------
% LMMSE Analysis of pilot patterns and channel estimation for DVB-T2
for n = 1:num
%x(n,:) = ((conj(H_c)*inv(H_c*conj(H_c))+eye(NFFT)/snr)*y(n,:).');
end
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


