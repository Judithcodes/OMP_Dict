function DataOut = t2_ch_dvbtpscen(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_ch_dvbtpscen SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
SEED   = DVBT2.CH.PSCEN.SEED;  % Seed for the random number generator
MISO_ENABLED = DVBT2.MISO_ENABLED;   % 1=MISO 0=SISO

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

% Check the seed and generates a random one if not set
if SEED
  rSeed = round(SEED);
else
  rSeed = round(sum(100*clock));
end
rand('state', rSeed)
fprintf(FidLogFile, '\tChannel seed: %d\n', rSeed);

chSeed = 1000*rand(1);

% Get the channel response
ch = t2_ch_dvbtpscen_getch(DVBT2, chSeed, FidLogFile);

if (MISO_ENABLED)
    misoGroups = 2;
else
    misoGroups = 1;
end

for misoGroup = 1:misoGroups
    % Convolution of the input data
    if (strcmp(ch.format, 'FreqResponse'))
      %dataConv = t2_ch_dvbtpscen_frconv(DVBT2, DataIn{misoGroup}, ch.freq(:,misoGroup), ch.ampl(:,misoGroup), ch.phase(:,misoGroup), FidLogFile);
    elseif isempty(find(ch.fd,1)) % If no doppler
      %dataConv = t2_ch_dvbtpscen_conv(DVBT2, DataIn{misoGroup}, ch.ro(:,misoGroup), ch.tau(:,misoGroup), ch.phi(:,misoGroup), FidLogFile);
    else
      dataConv = t2_ch_dvbtpscen_doppconv(DVBT2, DataIn{misoGroup}, ch.ro(:,misoGroup), ch.tau(:,misoGroup), ch.phi(:,misoGroup), ch.fd(:,misoGroup), FidLogFile); 
    end   
    DataOut.data{misoGroup}   = dataConv(1:length(DataIn{misoGroup}));
end

DataOut.ch     = ch;
