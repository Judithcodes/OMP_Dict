function t2_rx_ofdm_wr(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_rx_ofdm_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------

ENABLED  = DVBT2.RX.OFDM.ENABLE; % Enable
DI_FNAME = DVBT2.RX.OFDM_FDI;    % Input file
DO_FNAME = DVBT2.RX.OFDM_FDO;     % Output file   
TYPE     = DVBT2.RX.OFDM.TYPE;   % Block type   
SIM_DIR   = DVBT2.SIM.SIMDIR;    % Simulation directory 

L_F         = DVBT2.STANDARD.L_F;       % Symbols per frame
SP_PATTLEN  = DVBT2.STANDARD.SP_PATTLEN; % Scattered pilots pattern length
SP_LOC      = DVBT2.STANDARD.SP_LOC;     % Scattared pilots locations
SP_FNAME   = DVBT2.RX.SP_FDO;      % SP file
SIM_DIR    = DVBT2.SIM.SIMDIR;    % Simulation directory 
EDGE_LOC    = DVBT2.STANDARD.EDGE_LOC;   % Edge pilots locations
PN_SEQ      = DVBT2.STANDARD.PN_SEQ;     % PN sequence
EDGE_FNAME     = 'EDGEcen_rx_do';          % EDGE file

SEED   = DVBT2.CH.PSCEN.SEED;  % Seed for the random number generator
MISO_ENABLED = DVBT2.MISO_ENABLED;   % 1=MISO 0=SISO

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
global DATA;

if ENABLED
  fprintf(FidLogFile,'\tDVBT2-RX-OFDM: (%s)\n', TYPE);
          
  if strcmp(DI_FNAME, '')
    data = DATA;
  else
    load(strcat(SIM_DIR, filesep, DI_FNAME), 'data'); % Load input data
  end
  

  switch TYPE
    case 'DVBT2BL'
          if (MISO_ENABLED)
    misoGroups = 2;
          else
    misoGroups = 1;
          end
  chSeed = 1000*rand(1);
  % Get the channel response
  ch = t2_ch_dvbtpscen_getch(DVBT2, chSeed, FidLogFile);
        % Get the mapped prbs sequence
      prbs = t2_tx_dvbt2blfadapt_prbsseq(DVBT2);
      data = t2_rx_dvbt2blofdm(DVBT2, FidLogFile, data, ch.fd(:,misoGroups));

      %{
      % Separate SP here and save them to file
      numSymb = size(data,1);
            
        for symbIdx=1:numSymb   % for each symbol
            symbInFrame = mod(symbIdx-1, L_F);
            % Get scattered pilot locations
            spLoc = SP_LOC(mod(symbInFrame,SP_PATTLEN)+1, :);
            spLoc = spLoc(find(spLoc>0));
            % Assign pilot signals before marking them
            spLoc_rx_my = data(symbIdx,spLoc);
            refSequence = xor(prbs, PN_SEQ(symbInFrame + 1));
            %edgePilotMap = t2_tx_dvbt2blfadapt_bpsk_sp(DVBT2, refSequence);
            EDGE_rx_my = data(symbIdx,EDGE_LOC);

            if symbIdx==1
                 spLoc_rx_m_array = zeros(numSymb,length(spLoc_rx_my));
                 EDGE_rx_m_array = zeros(numSymb,length(EDGE_rx_my));
                 %spLoc_rx_m_array_ifft = zeros(numSymb,length(spLoc_rx_my));
            end

            %spLoc_rx_m_array_ifft(symbIdx,1:length(spLoc_rx_my)) = ...
            %ifftshift(ifft(spLoc_rx_my));

             spLoc_rx_m_array(symbIdx,1:length(spLoc_rx_my)) = spLoc_rx_my;
             EDGE_rx_m_array(symbIdx,1:length(EDGE_rx_my)) = EDGE_rx_my;
        end
          
        % Write scattered pilot to file
        if ~strcmp(SP_FNAME, '')
         save(strcat(SIM_DIR, filesep, SP_FNAME),'spLoc_rx_m_array')
         save(strcat(SIM_DIR, filesep, EDGE_FNAME),'EDGE_rx_m_array')

         %save(strcat(SIM_DIR, filesep, SP_FNAME, '_ifft'),'spLoc_rx_m_array_ifft')
       fprintf(FidLogFile,'\t\tScattered pilot output  saved in file: %s\n',...
       SP_FNAME);
        end
       %}
      
    otherwise     
      error('Unknown OFDM demodulation type %s', TYPE);
  end
  
else % If disabled
  fprintf(FidLogFile,'\tDVBT2-RX-OFDM: DISABLED\n');
end

%------------------------------------------------------------------------------
% Output saving and formatting
%------------------------------------------------------------------------------
if ENABLED
  if strcmp(DO_FNAME, '')
    DATA = data;
    fprintf(FidLogFile,'\t\tOFDM demodulation output stored in workspace\n');
  else
    save(strcat(SIM_DIR, filesep, DO_FNAME),'data')
    fprintf(FidLogFile,'\t\tOFDM demodulation output saved in file: %s\n',...
            DO_FNAME);
  end
end
