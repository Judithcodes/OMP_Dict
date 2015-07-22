function t2_tx_datagen_wr(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_tx_tstrgen_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
ENABLED  = DVBT2.TX.DATAGEN.ENABLE;  % Enable
DO_FNAME = DVBT2.TX.DATAGEN_FDO;     % Output file name
TYPE     = DVBT2.TX.DATAGEN.TYPE;    % Block type
SIM_DIR  = DVBT2.SIM.SIMDIR;         % Simulation directory 

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
global DATA;

if ENABLED
  fprintf(FidLogFile,'\tData generator: (%s)\n', TYPE);

  switch TYPE
    case 'DVBT2BL'
      data = t2_tx_dvbt2bldatagen(DVBT2, FidLogFile);
    case 'DVBT2VV'
      data = t2_tx_dvbt2vvdatagen(DVBT2, FidLogFile);
    case 'DVBT2DYNVV'
      data = t2_tx_dvbt2dynvvdatagen(DVBT2, FidLogFile);          
    case 'DVBT2ITU'
      data = t2_tx_dvbt2itudatagen(DVBT2, FidLogFile);
    case 'DVBT2RAWBBFILE'
      data = t2_tx_dvbt2rawbbfiledatagen(DVBT2, FidLogFile);
    case 'DVBT2TSFILE'
      data = t2_tx_dvbt2tsdatagen(DVBT2, FidLogFile);          
    case 'DVBT2MIFILE'
      data = t2_tx_dvbt2midatagen(DVBT2, FidLogFile);          
    otherwise     
      error('Unknown data generator type %s', TYPE);
  end

else
  fprintf(FidLogFile,'\tData generator: DISABLED\n');
end

%------------------------------------------------------------------------------
% Output saving and formatting
%------------------------------------------------------------------------------
if ENABLED  
  if strcmp(DO_FNAME, '')
    DATA = data; 
    
    fprintf(FidLogFile,'\t\tData stored in workspace\n');
  else
    save(strcat(SIM_DIR, filesep, DO_FNAME),'data')
    fprintf(FidLogFile,'\t\tData saved in file: %s\n',...
            DO_FNAME);
  end
end
