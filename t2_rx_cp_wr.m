function t2_rx_cp_wr(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_rx_cp_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
ENABLED   = DVBT2.RX.CP.ENABLE;  % Enable
DI_FNAME  = DVBT2.RX.CP_FDI;     % Input file
DO_FNAME  = DVBT2.RX.CP_FDO;     % Output file
TYPE      = DVBT2.RX.CP.TYPE;    % Block type
SIM_DIR   = DVBT2.SIM.SIMDIR;    % Simulation directory 

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
global DATA;

if ENABLED
  fprintf(FidLogFile,'\tDVBT2-RX-CP: (%s)\n', TYPE); 
          
  if strcmp(DI_FNAME, '')
    data = DATA;
  else
    load(strcat(SIM_DIR, filesep, DI_FNAME), 'data'); % Load input data
    %d=data.data;
    %d(3000:3010)

  end
  
  switch TYPE
    case 'DVBT2BL'
      data = t2_rx_dvbt2blcp(DVBT2, FidLogFile, data);
    otherwise     
      error('Unknown cyclic prefix removal type %s', TYPE);
  end
  
else % If disabled
  fprintf(FidLogFile,'\tDVBT2-RX-CP: DISABLED\n');
end

%------------------------------------------------------------------------------
% Output saving and formatting
%------------------------------------------------------------------------------
if ENABLED
  if strcmp(DO_FNAME, '')
    DATA = data;
    fprintf(FidLogFile,'\t\tCP output stored in workspace\n');
  else
    save(strcat(SIM_DIR, filesep, DO_FNAME),'data')
    fprintf(FidLogFile,'\t\tCP output saved in file: %s\n',DO_FNAME);
  end
end
