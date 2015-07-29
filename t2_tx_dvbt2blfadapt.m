function DataOut = t2_tx_dvbt2blfadapt(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2blfadapt SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
MODE        = DVBT2.MODE;                % Mode
EXTENDED    = DVBT2.EXTENDED;            % Extended BW mode
K_EXT       = DVBT2.STANDARD.K_EXT;      % Extra carriers each side in ext BW mode
SP_PATTERN  = DVBT2.SP_PATTERN;          % Scattered pilot pattern
C_DATA      = DVBT2.STANDARD.C_DATA;     % Data carriers per symbol
N_FC        = DVBT2.STANDARD.N_FC;       % Data carriers per FC symbol
C_P2        = DVBT2.STANDARD.C_P2;       % Data carriers per P2 symbol
L_F         = DVBT2.STANDARD.L_F;                 % Symbols per frame
N_P2        = DVBT2.STANDARD.N_P2;       % P2 symbols per frame
L_FC        = DVBT2.STANDARD.L_FC;       % P2 symbols per frame
PN_SEQ      = DVBT2.STANDARD.PN_SEQ;     % PN sequence
SP_LOC      = DVBT2.STANDARD.SP_LOC;     % Scattared pilots locations
SP_PATTLEN  = DVBT2.STANDARD.SP_PATTLEN; % Scattered pilots pattern length
SP_DX       = DVBT2.STANDARD.SP_DX;      % Scattered pilots SP-bearing carrier spacing (x)
CP_LOC      = DVBT2.STANDARD.CP_LOC;     % Continual pilots locations
EDGE_LOC    = DVBT2.STANDARD.EDGE_LOC;   % Edge pilots locations
P2P_LOC     = DVBT2.STANDARD.P2P_LOC;    % P2 pilots locations
FCP_LOC     = DVBT2.STANDARD.FCP_LOC;    % FC pilots locations

P2_TR_LOC   = DVBT2.STANDARD.P2_TR_LOC;  % P2 reserved tones locations
NORM_TR_LOC = DVBT2.STANDARD.TR_LOC;     % normal symbol reserved tones locations
FC_TR_LOC   = DVBT2.STANDARD.FC_TR_LOC;  % Frame closing symbol reserved tones locations

MISO_ENABLED = DVBT2.MISO_ENABLED;       % Is MISO being used?
SP_FNAME     = DVBT2.TX.SP_FDO;          % SP file
EDGE_FNAME     = 'EDGEcen_ch_do';          % EDGE file

SIM_DIR      = DVBT2.SIM.SIMDIR;         % Simulation directory 

L = DVBT2.L; % Doppler steps
K = DVBT2.K;
NFFT     = DVBT2.STANDARD.NFFT;  % FFT number of points
C_PS     = DVBT2.STANDARD.C_PS;
C_L = 0;%(NFFT - C_PS - 1)/2 + 1;

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

if (MISO_ENABLED)
    misoGroups = 2;
else
    misoGroups = 1;
end

fprintf(FidLogFile,'\t\tMode=%s\n', MODE);

for misoGroup = 1:misoGroups
    % Process the relevant input vector
    dataAux = DataIn{misoGroup}(:);

    % Transmit only complete symbols
    numSymb   = floor(length(dataAux)/C_DATA); 
    dataAux   = dataAux(1:numSymb*C_DATA);
    numFrames = floor(length(dataAux)/(L_F*C_DATA));

    dataAux   = reshape(dataAux, C_DATA, numSymb).';
%dataAux
    fprintf(FidLogFile,'\t\tNumber of complete frames: %d (%d symbols per frame)\n', numFrames, L_F);
    fprintf(FidLogFile,'\t\tNumber of transmitted symbols: %d\n', numSymb);
    fprintf(FidLogFile,'\t\tScattered pilots pattern: %s\n', SP_PATTERN);

    if strcmp(SP_PATTERN, 'NONE')
       symbols = dataAux;
    else
      % Initialise output
      symbols = zeros(numSymb, C_PS);

      % Get the mapped prbs sequence
      prbs = t2_tx_dvbt2blfadapt_prbsseq(DVBT2);

      % Get the MISO inversion sequence
      MISOInversionData(1:C_PS) = 1;
      MISOInversionP2(1:C_PS) = 1;

      if misoGroup == 2
          %(mod(0:C_PS-1, 2*SP_DX)==SP_DX)
          MISOInversionData(mod(0:C_PS-1, 2*SP_DX)==SP_DX) = -1;
          MISOInversionP2(mod(0:C_PS-1, 6)==3) = -1;
      end
      
      for symbIdx=1:numSymb   % for each symbol
         symbInFrame = mod(symbIdx-1, L_F);
         ind = mod(symbIdx-1, 2);

         % Combine PRBS sequence with PN sequence, to form "Reference
         % Sequence"
         refSequence = xor(prbs, PN_SEQ(symbInFrame + 1));
         %refSequence = xor(prbs, PN_SEQ(ind + 1));

         % Create map for scattered, edge and FC pilots, with boosting
         %MISOInversionData(1:30)
         scatteredPilotMap = t2_tx_dvbt2blfadapt_bpsk_sp(DVBT2, refSequence) .* MISOInversionData;
         edgePilotMap = t2_tx_dvbt2blfadapt_bpsk_sp(DVBT2, refSequence);

         if (misoGroup == 2 && mod(symbInFrame, 2) == 1)
             edgePilotMap = -edgePilotMap;
         end

         % Create map for continual pilots, with boosting
         continualPilotMap = t2_tx_dvbt2blfadapt_bpsk_cp(DVBT2, refSequence) .* MISOInversionData;

         if (symbInFrame<N_P2) % It's a P2 symbol
             % Insert P2 pilots
             P2PilotMap = t2_tx_dvbt2blfadapt_bpsk_p2p(DVBT2, refSequence) .* MISOInversionP2;
             symbols(symbIdx, C_L+P2P_LOC) = P2PilotMap(P2P_LOC);
             nData = C_P2; % Remember number of data cells

             currTRLoc = P2_TR_LOC; % Set tone reservation locations
             if (EXTENDED)
                 currTRLoc = currTRLoc + K_EXT;
             end

         elseif (symbInFrame == L_F-L_FC)
             % Insert FC pilots
             symbols(symbIdx, C_L+FCP_LOC) = scatteredPilotMap(FCP_LOC);
             % Insert edge pilots
             symbols(symbIdx, C_L+EDGE_LOC) = edgePilotMap(EDGE_LOC);
             nData = N_FC; % Remember number of data cells

             currTRLoc= FC_TR_LOC; % Set tone reservation locations
             if (EXTENDED)
                 currTRLoc = currTRLoc + K_EXT;
             end

         else

             % Get scattered pilot locations and pattern length
             spLoc = SP_LOC(mod(symbInFrame,SP_PATTLEN)+1, :);
             %spLoc = SP_LOC(mod(ind,SP_PATTLEN)+1, :);
             spLoc = spLoc(spLoc>0);

             % Insert continual pilots
             symbols(symbIdx, C_L+CP_LOC) = continualPilotMap(CP_LOC);

             % Insert scattered pilots
             symbols(symbIdx, C_L+spLoc) = scatteredPilotMap(spLoc);

             % Write scattered pilots to the file
             spLoc_tx_my = scatteredPilotMap(spLoc);
             EDGE_tx_my = edgePilotMap(EDGE_LOC);

%              if symbIdx==1
            if(~exist('spLoc_tx_m_array', 'var'))
                 spLoc_tx_m_array = zeros(numSymb,length(spLoc_tx_my));
                 EDGE_tx_m_array = zeros(numSymb,length(EDGE_tx_my));
                 spLoc_tx_m_array_loc = zeros(numSymb,length(spLoc));
             end
             
             spLoc_tx_m_array(symbIdx,1:length(spLoc_tx_my)) = spLoc_tx_my;
             spLoc_tx_m_array_loc(symbIdx,1:length(spLoc)) = spLoc;
             EDGE_tx_m_array(symbIdx,1:length(EDGE_tx_my)) = EDGE_tx_my;
             
             % Insert edge pilots
             symbols(symbIdx, C_L+EDGE_LOC) = edgePilotMap(EDGE_LOC);
             nData = C_DATA;  % Remember number of data cells

             if EXTENDED
                 currTRLoc = NORM_TR_LOC + SP_DX*mod(symbInFrame+K_EXT/SP_DX, SP_PATTLEN); % Set tone reservation locations
             else
                 currTRLoc = NORM_TR_LOC + SP_DX*mod(symbInFrame, SP_PATTLEN); % Set tone reservation locations
             end
         end

         % Insert zeros around sp pilots for Doppler shift
         %{
         spLocLeft = [spLoc-1 ];
         spLocRight = [spLoc+1 ];
         if find(spLocLeft < 1)
         spLocLeft(find(spLocLeft < 1)) = [];
         end
         if find(spLocRight > C_PS)
         spLocRight(find(spLocRight > C_PS)) = [];
         end
         symbols(symbIdx, C_L+spLocLeft) = 1;
         symbols(symbIdx, C_L+spLocRight) = 1;
         %symbols(symbIdx, 1:C_L) = 1;
         %}
         % Insert dummy data in TR locations so they don't get filled with data
         symbols(symbIdx, C_L+currTRLoc) = 1;

         % Get data locations
         dcLoc = find(symbols(symbIdx, :)==0);

%symbols(symbIdx, :) = zeros(1, length(symbols(symbIdx, :)));
%symbols(symbIdx, C_L+spLoc) = scatteredPilotMap(spLoc);

         % Insert data carriers
         symbols(symbIdx, dcLoc(1:nData)) = dataAux(symbIdx, 1:nData);
         %symbols(symbIdx, C_L+spLocLeft) = 0;
         %symbols(symbIdx, C_L+spLocRight) = 0;
    
         %symbols(symbIdx, C_L+CP_LOC) = 0;
%symbols(symbIdx, :) = zeros(1, length(symbols(symbIdx, :)));
%symbols(symbIdx, C_L+spLoc) = scatteredPilotMap(spLoc);

         % Set TR locations back to zero
         symbols(symbIdx, C_L+currTRLoc) = 0;
      end
      
      % Save SP patterns here
             if ~strcmp(SP_FNAME, '')
                  if misoGroup == 1
                save(strcat(SIM_DIR, filesep, SP_FNAME),'spLoc_tx_m_array')
                save(strcat(SIM_DIR, filesep, EDGE_FNAME),'EDGE_tx_m_array')
                save(strcat(SIM_DIR, filesep, 'sp_tx_do_loc'),'spLoc_tx_m_array_loc')
                fprintf(FidLogFile,...
                '\t\tScattered pilot output  saved in file: %s\n',SP_FNAME);
                  end
                                   if misoGroup == 2
                                       spLoc_tx_m_array2 = spLoc_tx_m_array;
                save(strcat(SIM_DIR, filesep, 'sp_tx_do2'),'spLoc_tx_m_array2')
                save(strcat(SIM_DIR, filesep, 'sp_tx_do_loc2'),'spLoc_tx_m_array_loc','-append')
                fprintf(FidLogFile,...
                '\t\tScattered pilot output  saved in file: %s\n',SP_FNAME);
                                   end
                       
             end
    end

    % Write V&V point
    if (MISO_ENABLED)
        write_vv_test_point(symbols.', C_PS, L_F, sprintf('15Tx%d',misoGroup), 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)
    else
        write_vv_test_point(symbols.', C_PS, L_F, '15', 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)
    end
    
    DataOut{misoGroup} = symbols;
end



