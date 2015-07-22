function DataOut = t2_ch_dvbtnoise(DVBT2, FidLogFile, DataIn)


%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_ch_dvbtnoise SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
SNR  = DVBT2.CH.NOISE.SNR;   % Signal to noise ratio (dB)
C_PS = DVBT2.STANDARD.C_PS;  % Carriers per symbols
TU   = DVBT2.STANDARD.TU;    % Duration of the data part in the OFDM symbol
NFFT = DVBT2.STANDARD.NFFT;  % Number of carrier per symbols
SEED0 = DVBT2.CH.NOISE.SEED;  % Noise seed
T    = 1/DVBT2.STANDARD.SF;  % Elementary period

MISO_ENABLED = DVBT2.MISO_ENABLED;   % 1=MISO 0=SISO

if strcmp(DVBT2.CH.PSCEN.CHSTR.TYPE, 'DTG-II')
    pulsesPerBurst  = DVBT2.CH.IINOISE.PULSES;             % Pulses per burst
    minPulseSpacing = DVBT2.CH.IINOISE.MIN_PULSE_SPACING;  % Mininum pulse spacing
    maxPulseSpacing = DVBT2.CH.IINOISE.MAX_PULSE_SPACING;  % Maximum pulse spacing
    burstSpacing    = DVBT2.CH.IINOISE.BURST_SPACING;      % Burst spacing
    clipLevel       = DVBT2.CH.IINOISE.CLIP_LEVEL;         % Clipping level (dB wrt rms signal)
end
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

if (MISO_ENABLED)
    % Combine the two Tx signals at the receiver input
    data = DataIn.data{1} + DataIn.data{2};
else
    data = DataIn.data{1};
end

if(SNR>100)
  fprintf(FidLogFile, '\t\tSNR = Infinite\n');
  DataOut.data = data;
  DataOut.ch   = DataIn.ch;
else
  fprintf(FidLogFile, '\t\tSNR = %.2f dB\n', SNR);

  % Signal bandwidth
  sBW = C_PS/TU;
    
  % Noise bandwidth
  nBW = NFFT/TU; 
    
  % Signal power
  p = sum(data.*conj(data))/length(data);

  % noise generation
  snr = 10^(SNR/10);
  desv = sqrt(p/snr)/sqrt(2*sBW/nBW);
    
  if (SEED0 == 0)
    SEED0 = sum(100*clock);    
  end      

  randn('state', SEED0);  
  n = randn(size(data)) + 1i*randn(size(data));  
  n = n.*desv;

  %Gate the noise to make it into impulsive noise if required
  %Pulses should be 250ns long, but make them 2 complex samlpes for now
  %(=2x109 ns)
  
  if strcmp(DVBT2.CH.PSCEN.CHSTR.TYPE, 'DTG-II')
      totalDuration = length(data)*T;
      nBursts = ceil((totalDuration - maxPulseSpacing * pulsesPerBurst)/burstSpacing);
      pulseSeparations = minPulseSpacing + (maxPulseSpacing-minPulseSpacing) .* ...
          rand(pulsesPerBurst, nBursts);
      pulseStarts = cumsum (pulseSeparations);
      pulseStarts = pulseStarts + repmat(burstSpacing*(0:nBursts-1),pulsesPerBurst,1);
      pulsePositions = reshape(round(pulseStarts./T),1,[]);
      gate = zeros(1,length(data));
      gate(pulsePositions)=1;
      gate(pulsePositions+1)=1;
      n = n .* gate;
  end

  DataOut.data = data + n;
  DataOut.ch   = DataIn.ch;

  %Apply clipping when doing II simulations
  if strcmp(DVBT2.CH.PSCEN.CHSTR.TYPE, 'DTG-II')
      clipLevel = 10^(clipLevel/20)*sqrt(p);
      dataReals = real(DataOut.data);
      dataImags = imag(DataOut.data);
      maxs = dataReals > clipLevel;
      dataReals(maxs) = clipLevel;
      mins = dataReals < -clipLevel;
      dataReals(mins) = -clipLevel;
      maxs = dataImags > clipLevel;
      dataImags(maxs) = clipLevel;
      mins = dataImags < -clipLevel;
      dataImags(mins) = -clipLevel;
      DataOut.data = dataReals + 1j*dataImags;
  end
end      
