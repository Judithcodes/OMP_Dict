function chan = t2_rx_ompalg_full(DVBT2, FidLogFile)
%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_rx_ompalg SYNTAX');
end
%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
ENABLED    = DVBT2.RX.BMPALG.ENABLE; % Enable  
SIM_DIR    = DVBT2.SIM.SIMDIR;       % Simulation directory 
SP_FNAME   = DVBT2.RX.SP_FDO;        % SP file
TU    = DVBT2.STANDARD.TU;    % Length in s of the OFDM symbol data part
GI    = DVBT2.GI_FRACTION;    % Length in s of the OFDM symbol data part
SNR           = DVBT2.CH.NOISE.SNR;     % Signal to noise ratio (dB)
MISO_ENABLED = DVBT2.MISO_ENABLED;   % 1=MISO 0=SISO
P2P_LOC     = DVBT2.STANDARD.P2P_LOC;   % P2 pilots locations
NFFT     = DVBT2.STANDARD.NFFT;  % FFT number of points
PN_SEQ      = DVBT2.STANDARD.PN_SEQ;     % PN sequence
SP_LOC      = DVBT2.STANDARD.SP_LOC;     % Scattared pilots locations
SP_PATTLEN  = DVBT2.STANDARD.SP_PATTLEN; % Scattered pilots pattern length
C_PS     = DVBT2.STANDARD.C_PS;
L_F         = DVBT2.STANDARD.L_F;       % Symbols per frame
N_P2        = DVBT2.STANDARD.N_P2;       % P2 symbols per frame
L_FC        = DVBT2.STANDARD.L_FC;       % FC symbols per frame 1 or 0
FCP_LOC     = DVBT2.STANDARD.FCP_LOC;    % FC pilots locations
GUARD_INT = 1/DVBT2.GI_FRACTION; % Guard interval 
nCP = fix(NFFT/GUARD_INT); % Number of samples of cyclic prefix
C_L = (NFFT - C_PS - 1)/2 + 1;
prbs = t2_tx_dvbt2blfadapt_prbsseq(DVBT2);
ts = TU/NFFT;
snr = 10^(SNR/10);
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

if ENABLED
  fprintf(FidLogFile,'\tDVBT2-RX-OMPALG for TUBS data: %d\n');

    if (MISO_ENABLED)
    misoGroups = 2;
          else
    misoGroups = 1;
    end

    load(strcat(SIM_DIR, filesep, 'sp_tx_do'), 'spLoc_tx_m_array'); % Load data

     if (MISO_ENABLED)
     else

  [num numSymb] = size(spLoc_tx_m_array);
  Ly = (NFFT+NFFT+nCP)-1;  % power for fconv function
  Ly2 = pow2(nextpow2(Ly));

  % Creating dictionary for matching pursuit
  % Insert scattered pilots  
%   L = 301;
  L = ceil(1*0.2500/(NFFT * ts))  %% 25% of the carrier spacing
  K = TU*GI/(1e-9)
  P = 32;
  
    ro = -1*ones(num,P);
    fd = -1*ones(num,P);
    tau = -1*ones(num,P);
    phi = -1*ones(num,P);    
    load(strcat(SIM_DIR, filesep, SP_FNAME), 'spLoc_rx_m_array'); % Load data
    
    if N_P2 > 0
        load(strcat(SIM_DIR, filesep, SP_FNAME), 'p2pLoc_rx_m_array'); % Load p2 pilot data
    end
    if L_FC > 0
        load(strcat(SIM_DIR, filesep, SP_FNAME), 'fcpLoc_rx_m_array'); % Load Frame closing pilot data
    end
    
    global name0;
    global DICTIONARY;
    global time;
    
        if isempty(name0)
    name0 = cellstr('');
    DICTIONARY = zeros(1024,length(P2P_LOC));
        end
        
    % Search for every symbol
    for index = 1:num
type = 0; % data symbol
%------------------------------------------------------------------------------
symbInFrame = mod(index-1, L_F);
%symbInFrame = mod(index-1, 2);

type = symbInFrame<N_P2;
            % TODO: take care of P2 edges
            if type == 1 % fill in p2 symbol pilot values
             refSequence = xor(prbs, PN_SEQ(symbInFrame + 1));
             MISOInversionP2(1:C_PS) = 1;
             P2PilotMap = t2_tx_dvbt2blfadapt_bpsk_p2p(DVBT2, refSequence) .* MISOInversionP2;
             pilots_tx_my = P2PilotMap(P2P_LOC);
             pilotsLoc = P2P_LOC;
            else
             % Get scattered pilot locations and pattern length
             spLoc = SP_LOC(mod(symbInFrame,SP_PATTLEN)+1, :);
             spLoc = spLoc(spLoc>0);
             refSequence = xor(prbs, PN_SEQ(symbInFrame + 1));
             MISOInversionData(1:C_PS) = 1;
             scatteredPilotMap = t2_tx_dvbt2blfadapt_bpsk_sp(DVBT2, refSequence) .* MISOInversionData;
             pilots_tx_my = scatteredPilotMap(spLoc);
             pilotsLoc = spLoc;
            end
            
            %%% Get Frame Closing pilot locations and values
            if((symbInFrame == L_F-L_FC))  
                fcpLoc = FCP_LOC(find(FCP_LOC>0));
                pilots_tx_my = scatteredPilotMap(FCP_LOC);
                pilotsLoc = fcpLoc;
            end
                     
[LEN NUM] = size(pilots_tx_my);
loc1 = pilotsLoc(1,:);
loc1(find(loc1==0)) = [];
symbol1 = zeros(1,1*NFFT);
symbol1(C_L + loc1) = pilots_tx_my(1,1:length(loc1));
% FFT shift
fftDI = fftshift(symbol1, 2);
% IFFT
DataIn = 5/sqrt(27*C_PS)*NFFT*ifft(fftDI, NFFT, 2); % multiplying by NFFT undoes the scale factor applied by ifft()
% Format input
dataCP = zeros(1, NFFT+nCP);
dataCP(1, nCP + (1:NFFT)) = DataIn;
dataCP(1, 1:nCP) = DataIn(1, NFFT-nCP+1:NFFT);
dataCP = fft(dataCP, Ly2);
%------------------------------------------------------------------------------

        clear DICTIONARY;
        clear name0;
        name0 = cellstr('');
        DICTIONARY = zeros(1024,length(P2P_LOC));
    
        index
        numSymb = length(find(abs(spLoc_tx_m_array(index,:))>0));
        if mod(numSymb,2)
            numSymb = numSymb - 1;
        end
        
        y = spLoc_rx_m_array(index,1:numSymb); % received sp signal
        I = [];
        h = [];
        tau0 = [];
        fd0 = [];
        r0 = y(1:numSymb);
        c_s1 = 0;
        x1_est = [];
        
        
%%%%% Using P2 Pilots for estimation        
        if type == 1
            numSymb = length(find(abs(p2pLoc_rx_m_array(index,:))>0));
            y = p2pLoc_rx_m_array(index,1:numSymb);
            r0 = y(1:numSymb);
        end
        
%%% Using Frame Closing pilots in case of FC symbol
       if((symbInFrame == L_F-L_FC))  
           numSymb = length(find(abs(fcpLoc_rx_m_array(index,:))>0));
           y = fcpLoc_rx_m_array(index,1:numSymb);
           r0 = y(1:numSymb);
       end
        
        
   
  %search = t2_rx_ompalg_nano_intervalsearch_wodict(DVBT2, FidLogFile, r0, c_s1, x1_est, tau0, fd0, numSymb, index, type, K, L); %fprintf(FidLogFile,'\tDVBT2-RX-nano search %d\n');
  search = t2_rx_ompalg_nano_intervalsearch(DVBT2, FidLogFile, loc1, dataCP, r0, c_s1, x1_est, tau0, fd0, numSymb, index, type, K, L, 1); %fprintf(FidLogFile,'\tDVBT2-RX-nano search %d\n');
  search

    tau0(length(tau0)+1) = search(1);
    fd0(length(fd0)+1) = search(2);
    dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1, dataCP, index, type, search(1), search(2));
    c_s1 = zeros(1,numSymb);    
    c_s1(1,1:numSymb) = dict_element(1:numSymb);
    % coeff calc
    CS = zeros(numSymb,length(tau0));
    for ii=1:length(tau0)
        dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1, dataCP, index, type, tau0(ii), fd0(ii));
        CS(:,ii) = dict_element(1:numSymb);
    end
    b = (ctranspose(CS)*transpose(r0));
    A = (ctranspose(CS)*CS);
    %A = (ctranspose(CS)*CS)+eye(length(tau0))/snr;
    %x1_est = pinv(A)*b;
    x1_est = A\b;
    h = single(x1_est);

% start loop here p (paths) recursively  
T_n_old = -Inf;
T_n_log_old = Inf;
GAIC_old = Inf;
AIC_old = Inf;
BIC_old = Inf;
MDL_old = Inf;
T_n_var_old = -Inf;
res_norm_old = Inf;

for p = 2:P
    %search = t2_rx_ompalg_nano_intervalsearch_wodict(DVBT2, FidLogFile, r0, c_s1, x1_est, tau0, fd0, numSymb, index, type, K, L); %fprintf(FidLogFile,'\tDVBT2-RX-nano search %d\n');
    search = t2_rx_ompalg_nano_intervalsearch(DVBT2, FidLogFile, loc1,dataCP, r0, c_s1, x1_est, tau0, fd0, numSymb, index, type, K, L, p); 
    search
    %%{
    tau0(length(tau0)+1) = search(1);
    fd0(length(fd0)+1) = search(2);
    dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1, dataCP, index, type, search(1), search(2));
    c_s1 = zeros(1,numSymb);
    c_s1(1,1:numSymb) = dict_element(1:numSymb);
    % coeff calc
    CS = zeros(numSymb,length(tau0));
    for ii=1:length(tau0)
        dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1, dataCP, index, type, tau0(ii), fd0(ii));
        CS(:,ii) = dict_element(1:numSymb);
    end
    b = (ctranspose(CS)*transpose(r0));
    A = (ctranspose(CS)*CS);
    %A = (ctranspose(CS)*CS)+eye(length(tau0))/snr;
    %x1_est = pinv(A)*b;
    x1_est = A\b;
    if isnan(abs(x1_est(length(x1_est)))) || isinf(abs(x1_est(length(x1_est)))) 
    end
    %---------------------------------------------------------------------
    % Stopping criteria
    %T_n = norm((x1_est(1:length(x1_est)-1)-h),2)^2;
    %T_n_log = log(T_n/(p-1));
    %crit = abs(T_n_old - T_n);
    %T_n_var = ctranspose((x1_est(1:length(x1_est)-1)-h))*((x1_est(1:length(x1_est)-1)-h));
    %crit_our = 0.00001*10^(-(SNR/30));
    %variance = sqrt(10^(-SNR/10))/sqrt(2);
    %st_c = variance*sqrt(numSymb+2*sqrt(numSymb*log(numSymb))); % [182]
    res = r0;
    for ii = 1:length(tau0)
        %dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP,index, type, tau0(ii), fd0(ii));
        %res = res - (x1_est(ii)*dict_element(1:numSymb));
    end
    %res_norm = norm(res,2);
    %delta = 1/(sqrt(P)+3);
    %delta = delta - 0.01*delta;
    %---------------------------------------------------------------------
    v1 = transpose(r0-transpose(CS*x1_est));
    %n_var = ctranspose(v1)*(v1)/numSymb;
    RSS = ctranspose(v1)*(v1);
    %V_l = (length(r0)/2)*log(n_var);
    %r0_t = transpose(r0);
    %R = (ctranspose(CS*x1_est)*(CS*x1_est))/(ctranspose(r0_t)*(r0_t));
    %if R^2 > p/numSymb
        %S = RSS/(numSymb-p);
        %FSS = ctranspose(r0_t)*(CS*x1_est);
        %MDL = (numSymb/2)*log(S)+(p/2)*log(FSS/(p*S))+log(numSymb);
    %else
        %MDL = (numSymb/2)*log(ctranspose(r0_t)*(r0_t)/numSymb)+log(numSymb)/2;
    %end
    %GAIC = V_l + 2*log(log(length(r0)))*(p+1); %[136]
    %AIC = (numSymb/2)*log(RSS) + p; %[]
    BIC = (numSymb/2)*log(RSS) + 1*(p/2)*log(numSymb); %[]
    %---------------------------------------------------------------------    %if T_n > p || search(3) < 10^(-(SNR/100))/2%abs(x1_est(length(x1_est))) < 0.05%0.5%abs(T_n_old - T_n) < crit_our %|| (crit_old-crit) < -0.00001  %%% our criterion
    %if T_n > p || abs(x1_est(length(x1_est))) < 0.00002
    %if GAIC_old < GAIC % 0.347827 SNR=0
    %if AIC_old < AIC % 0.347827 SNR=0
    if BIC_old < BIC % 0.347827 SNR=0
    %if MDL_old < MDL % 0.347827 SNR=0
    %if T_n_log_old < T_n_log   % 0. SNR=0
    %if T_n_old > T_n   % 0.347519 SNR=0
    %if T_n > 1 || search(3) < 10^(-(SNR/200))/2 % 0.360957 SNR=0
    %if norm(res,2) < st_c
    %if res_norm_old < res_norm
    tau0(length(tau0)) = [];
    fd0(length(fd0)) = [];
    %h = x1_est;
    break
    end
    h = x1_est;
    %T_n_old = T_n;
    %T_n_var_old = T_n_var;
    %T_n_log_old = T_n_log;
    %crit_old = crit;
    %GAIC_old = GAIC;
    %AIC_old = AIC;
    BIC_old = BIC;
    %MDL_old = MDL;
    %res_norm_old = res_norm;
    %---------------------------------------------------------------------
    %%}
end
%length(tau0)

phi(index,1:length(tau0)) = zeros(1,length(tau0));
ro(index,1:length(h)) = h;
tau(index,1:length(tau0)) = tau0;
fd(index,1:length(fd0)) = fd0;

    end

  chan.tau = tau;
  chan.fd = fd;
  chan.ro = ro;

    % save channel estimation
  fns = strcat('DVBT2_chan', num2str(SNR),'.mat');
  save(strcat(SIM_DIR, filesep, fns),'chan')
  
     end
  else % If disabled
  fprintf(FidLogFile,'\tDVBT2-RX-OMPALG: DISABLED\n');
end