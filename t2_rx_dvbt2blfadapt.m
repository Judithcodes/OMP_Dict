function DataOut = t2_rx_dvbt2blfadapt(DVBT2, FidLogFile, DataIn)


%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_rx_dvbtfadapt SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
MODE        = DVBT2.MODE;                % Mode
EXTENDED    = DVBT2.EXTENDED;            % Extended BW
K_EXT       = DVBT2.STANDARD.K_EXT;               % extra carriers each side in ext carrier mode
SP_PATTERN  = DVBT2.SP_PATTERN;          % Scattered pilot pattern
C_DATA      = DVBT2.STANDARD.C_DATA;      % Data carriers per symbol
N_FC        = DVBT2.STANDARD.N_FC;      % Data carriers per FC symbol
C_P2        = DVBT2.STANDARD.C_P2;      % Data carriers per P2 symbol
C_PS        = DVBT2.STANDARD.C_PS;       % Carriers per symbol
L_F         = DVBT2.STANDARD.L_F;       % Symbols per frame
N_P2        = DVBT2.STANDARD.N_P2;      % P2 symbols per frame
L_FC        = DVBT2.STANDARD.L_FC;      % P2 symbols per frame
SP_LOC      = DVBT2.STANDARD.SP_LOC;     % Scattared pilots locations
SP_PATTLEN  = DVBT2.STANDARD.SP_PATTLEN; % Scattered pilots pattern length
SP_DX       = DVBT2.STANDARD.SP_DX;      % Scattered pilot bearing carrier spacing
CP_LOC      = DVBT2.STANDARD.CP_LOC;     % Continual pilots locations
EDGE_LOC    = DVBT2.STANDARD.EDGE_LOC;   % Edge pilots locations
P2P_LOC     = DVBT2.STANDARD.P2P_LOC;   % P2 pilots locations
FCP_LOC     = DVBT2.STANDARD.FCP_LOC;   % FC pilots locations

P2_TR_LOC   = DVBT2.STANDARD.P2_TR_LOC;   % P2 reserved tones locations
NORM_TR_LOC      = DVBT2.STANDARD.TR_LOC;   % normal symbol reserved tones locations
FC_TR_LOC   = DVBT2.STANDARD.FC_TR_LOC;   % Frame closing symbol reserved tones locations

MISO_ENABLED = DVBT2.MISO_ENABLED; % 1 = MISO 0 = SISO
NFFT     = DVBT2.STANDARD.NFFT;  % FFT number of points
C_L = (NFFT - C_PS - 1)/2 + 1;

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

fprintf(FidLogFile,'\t\tMode=%s\n', MODE);
data = DataIn.data;

if (MISO_ENABLED)
    hEst1 = DataIn.h_est{1};
    hEst2 = DataIn.h_est{2};
else
    hEst1 = DataIn.h_est;
end

numSymb = size(data,1);
numFrames = floor(numSymb/L_F);

fprintf(FidLogFile,'\t\tNumber of complete frames: %d (%d symbols per frame)\n', numFrames, L_F);
fprintf(FidLogFile,'\t\tNumber of received symbols: %d\n', numSymb);  
fprintf(FidLogFile,'\t\tScattered pilots pattern: %s\n', SP_PATTERN);

if ~strcmp(SP_PATTERN, 'NONE')
  % Get the position of pilots to extract data carriers  
  symbols  = zeros(numSymb, C_DATA);
  channel1  = zeros(numSymb, C_DATA);
  channel2  = zeros(numSymb, C_DATA);

  for symbIdx=1:numSymb   % for each symbol

    dataCarr = true(1,C_PS);
    symbInFrame = mod(symbIdx-1, L_F);
    %ind = mod(symbIdx-1, 2);

    if (symbInFrame<N_P2) % It's a P2 symbol
         % Mark P2 pilots
         dataCarr(P2P_LOC) = 0;

         % Remember number of data cells
         nData = C_P2; 

         % Mark TR locations
         if (EXTENDED)
             currTRLoc = P2_TR_LOC + K_EXT;
         else
             currTRLoc = P2_TR_LOC;
         end


    elseif (symbInFrame == L_F-L_FC) % It's a Frame Closing Symbol
         % Mark FC pilots
         dataCarr(FCP_LOC) = 0;

         % Mark edge pilots
         dataCarr(EDGE_LOC) = 0;

         % Remember number of data cells
         nData = N_FC;

         % Mark TR locations
         if (EXTENDED)
            currTRLoc = FC_TR_LOC + K_EXT;
         else
            currTRLoc = FC_TR_LOC; 
         end
    else

        % Mark Continual pilots
        dataCarr(CP_LOC) = 0;

spLoc = SP_LOC(mod(symbInFrame,SP_PATTLEN)+1, :);
%spLoc = SP_LOC(mod(ind,SP_PATTLEN)+1, :);
spLoc = spLoc(find(spLoc>0));

        % Mark scattered pilots
        dataCarr(spLoc) = 0;
        
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
         dataCarr(spLocLeft) = 0;
         dataCarr(spLocRight) = 0;
         %dataCarr(symbIdx, 1:C_L) = 0;
         %}
         
        % Mark edge pilots
        dataCarr(EDGE_LOC) = 0;

        % Remember number of data cells
        nData = C_DATA; 

        % Mark TR locations
         if EXTENDED
             currTRLoc = NORM_TR_LOC + SP_DX*mod(symbInFrame+K_EXT/SP_DX, SP_PATTLEN); % Set tone reservation locations
         else
             currTRLoc = NORM_TR_LOC + SP_DX*mod(symbInFrame, SP_PATTLEN); % Set tone reservation locations
         end
    end
    % Measure power in data and TR
    meanDataPower = mean(abs(data(symbIdx, dataCarr)).^2);
    maxTRPower = max(abs(data(symbIdx, currTRLoc)).^2);
    carrierPAPR = max(abs(data(symbIdx,:)).^2)/mean(abs(data(symbIdx,:)).^2);
    carrierPeakPower=max(abs(data(symbIdx,:)).^2);
    %fprintf(FidLogFile, 'Symbol %d Mean data power %f max TR power %f Carrier PAPR %f Peak carrier power %f\n',symbIdx, meanDataPower, maxTRPower, carrierPAPR,carrierPeakPower);

    dataCarr(currTRLoc) = 0;
    % Save data carriers
    dataLoc = find(dataCarr);
    symbols(symbIdx, 1:nData) = data(symbIdx, dataLoc(1:nData)); % extra columns in P2 and FC symbol will be zero
    channel1(symbIdx, 1:nData) = hEst1(symbIdx, dataLoc(1:nData));
    if MISO_ENABLED
      channel2(symbIdx, 1:nData) = hEst2(symbIdx, dataLoc);
    end
  end

  data = symbols;
  if MISO_ENABLED
      hEst = {channel1 channel2};
  else
      hEst = channel1;
  end
else
  if MISO_ENABLED
    hEst = {hEst1 hEst2};
  else
    hEst = hEst1;
  end
end  

DataOut.data = data;
DataOut.h_est = hEst;

