function t2_rx_che_wr(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_rx_che_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
ENABLED    = DVBT2.RX.CHE.ENABLE; % Enable
DI_FNAME   = DVBT2.RX.CHE_FDI;    % Input file
DO_FNAME   = DVBT2.RX.CHE_FDO;    % Output file
CH_FNAME   = DVBT2.RX.CHE_FCH;     % Channel
TYPE       = DVBT2.RX.CHE.TYPE;   % Block type
SIM_DIR    = DVBT2.SIM.SIMDIR;    % Simulation directory 

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
global DATA;

if ENABLED
  fprintf(FidLogFile,'\tDVBT2-RX-CHE: (%s)\n', TYPE);

  % Read input data
  if strcmp(DI_FNAME, '')
    data = DATA;   
  else
    load(strcat(SIM_DIR, filesep, DI_FNAME), 'data'); % Load input data
  end

  switch TYPE
    case 'IDEAL'
      dataIn = data;

      % Read the ch output file
      if strcmp(CH_FNAME, '')
        error('t2_rx_idealche: missing propagation scenario output file, cannot perform equalization');
      else
        load(strcat(SIM_DIR, filesep, CH_FNAME), 'data'); % Load input data
        dataCh   = data.data;
        chParams = data.ch;
      end
  
%data = t2_rx_idealche(DVBT2, FidLogFile, dataIn, dataCh, chParams);
%dataIn.'
data = t2_rx_che(DVBT2, FidLogFile, dataIn, dataCh, chParams);

    otherwise     
      error('Unknown channel estimator type %s', TYPE);
  end   

else % If disabled
  fprintf(FidLogFile,'\tDVBT2-RX-CHE: DISABLED\n');
end

%------------------------------------------------------------------------------
% Output saving and formatting
%------------------------------------------------------------------------------
if ENABLED
  if strcmp(DO_FNAME, '')
    DATA = data;
    fprintf(FidLogFile,'\t\tChannel estimator output stored in workspace\n');
  else
    save(strcat(SIM_DIR, filesep, DO_FNAME),'data')
    fprintf(FidLogFile,'\t\tChannel estimator output  saved in file: %s\n',...
            DO_FNAME);
  end
end

