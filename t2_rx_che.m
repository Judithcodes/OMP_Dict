function DataOut = t2_rx_che(DVBT2, FidLogFile, DataIn, DataCh, ChParams)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 5,
    ;
  otherwise,
    error('t2_rx_idealche SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
C_LOC      = DVBT2.STANDARD.C_LOC;  % Carriers location
CHSTR      = DVBT2.CH.PSCEN.CHSTR;  % Channel structure 
NFFT       = DVBT2.STANDARD.NFFT;   % Number of points per OFDM symbol
TU         = DVBT2.STANDARD.TU;     % Length in s of the OFDM symbol data part

% IO options
SIM_DIR      = DVBT2.SIM.SIMDIR;          % Saving directory
MISO_ENABLED = DVBT2.MISO_ENABLED;

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
% Initialize data
numSymb = size(DataIn,1);     % Number of symbols

if MISO_ENABLED
    misoGroups = 2;
else
    misoGroups = 1;
end

chanType = CHSTR.TYPE;
chanType = upper(chanType); 

for misoGroup = 1:misoGroups
    if strcmp(ChParams.format, 'FreqResponse')
      elseif ~isempty(ChParams) && isempty(find(ChParams.fd(:,misoGroup), 1)) %No doppler
      elseif ~isempty(find(ChParams.fd(:,misoGroup), 1)) % for DVBT-P channel
          
      %{   
      F = dftmtx(NFFT);
      F_H = conj(F);
      load(strcat(SIM_DIR, filesep, 'H_CIR'),'hT_DSS')

     % Get the delay, atenuation, phase and doppler frequency
      ro  = ChParams.ro(:,misoGroup);
      tau = ChParams.tau(:,misoGroup);
      phi = ChParams.phi(:,misoGroup);
      fd  = ChParams.fd(:,misoGroup);

      hT_DS = zeros(length(tau),NFFT);
      hTD = zeros(length(tau),NFFT);  
      hF_DS = zeros(length(tau),NFFT);

        for k=1:length(tau)
  freqIndx = 1:NFFT;
  freqIndx = freqIndx - (NFFT/2) - 1;
  carSpacing = 1/TU;
  freqIndx = 2 * pi * freqIndx * carSpacing;
  hF_DS(k,:) = hF_DS(k,:) + ro(k) * exp(1j*( phi(k) - freqIndx*tau(k)*1e-6));
  hT_DS(k,:) = fftshift(ifft(fftshift(hF_DS(k,:))));    
  hTD(k,:) = hT_DS(k,:);
        end

  if length(tau)>1
  hT_DSS = sum(hTD(:,:));
  else
  hT_DSS = (hTD(:,:));
  end
  hT_DSS = fft(fftshift(hT_DSS(1,:)));
  hT_DSS = fftshift(hT_DSS);
  hEstCh = hT_DSS;
          
  hEst{misoGroup} = hEstCh;
  hEst{misoGroup} = repmat(hEstCh,[numSymb 1]);      
  hEst{misoGroup} = hEst{misoGroup}(:, C_LOC); 
          %}
  load(strcat(SIM_DIR, filesep, 'hEstCh'),'hEstCh')
  hEst{misoGroup} = hEstCh;      
  hEst{misoGroup} = hEst{misoGroup}(:, C_LOC); 
  
  % ----------------------------------------------------------------
  %         ANMSE
  %
  %{
  numSymb = size(DataIn,1);     % Number of symbols
  summ = 0;
  for ii = 1:numSymb
    L_F         = DVBT2.STANDARD.L_F;       % Symbols per frame
    C_LOC      = DVBT2.STANDARD.C_LOC;  % Carriers location
    symbInFrame = mod(ii-1, L_F);
    SP_LOC      = DVBT2.STANDARD.SP_LOC;     % Scattared pilots locations
    SP_PATTLEN  = DVBT2.STANDARD.SP_PATTLEN; % Scattered pilots pattern length
    prbs = t2_tx_dvbt2blfadapt_prbsseq(DVBT2);
    PN_SEQ      = DVBT2.STANDARD.PN_SEQ;     % PN sequence
    C_PS      = DVBT2.STANDARD.C_PS;     % Scattared pilots locations
    spLoc = SP_LOC(mod(symbInFrame,SP_PATTLEN)+1, :);
    spLoc = spLoc(spLoc>0);
    refSequence = xor(prbs, PN_SEQ(symbInFrame + 1));
    MISOInversionData(1:C_PS) = 1;
    scatteredPilotMap = t2_tx_dvbt2blfadapt_bpsk_sp(DVBT2, refSequence) .* MISOInversionData;
    pilots_tx_my = scatteredPilotMap(spLoc);
    if mod(ii,2)
    pilots_corrected = DataIn(ii,(1:12:6817));
    else
    pilots_corrected = DataIn(ii,(7:12:6817));
    end
    summ = summ + (norm(pilots_tx_my(1:568)-pilots_corrected(1:568),2)^2)...
        /(norm(pilots_tx_my(1:568),2)^2);
  end
  20 * log10(summ/numSymb)
  %}
  % ----------------------------------------------------------------
  
    else
    end
end

% Equalizer
if (MISO_ENABLED)
else 
    %DataIn(1013,1:50).'
    %DataIn = DataIn./hEst{1}; %Do the equalisation here so the plot looks nice.
    %DataIn(1013,1:50).'
    DataOut.data = DataIn;
    DataOut.h_est = hEst{1};
end
