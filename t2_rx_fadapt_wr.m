function t2_rx_fadapt_wr(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_rx_fadapt_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
ENABLED  = DVBT2.RX.FADAPT.ENABLE; % Enable
DI_FNAME = DVBT2.RX.FADAPT_FDI;    % Input file
DO_FNAME = DVBT2.RX.FADAPT_FDO;    % Output file
TYPE     = DVBT2.RX.FADAPT.TYPE;   % Block type
SIM_DIR   = DVBT2.SIM.SIMDIR;    % Simulation directory 

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
global DATA;

if ENABLED
  fprintf(FidLogFile,'\tDVBT2-RX-FADAPT: (%s)\n', TYPE);
          
  if strcmp(DI_FNAME, '')
    data = DATA;
    
  else
    load(strcat(SIM_DIR, filesep, DI_FNAME), 'data'); % Load input data    
  end

  switch TYPE
    case 'DVBT2BL'
      data = t2_rx_dvbt2blfadapt(DVBT2, FidLogFile, data);  
    otherwise     
      error('Unknown inner frame adaptation type %s', TYPE);
  end 

else % If disabled
  fprintf(FidLogFile,'\tDVBT2-RX-FADAPT: DISABLED\n');
end

%------------------------------------------------------------------------------
% Output saving and formatting
%------------------------------------------------------------------------------
if ENABLED
  if strcmp(DO_FNAME, '')
    DATA = data;
    fprintf(FidLogFile,'\t\tFrame adaptation output stored in workspace\n');
  else
    save(strcat(SIM_DIR, filesep, DO_FNAME),'data')
    fprintf(FidLogFile,'\t\tFrame adaptation output  saved in file: %s\n',...
            DO_FNAME);
  end
end
