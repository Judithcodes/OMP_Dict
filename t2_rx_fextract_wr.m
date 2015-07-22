function t2_rx_fextract_wr(DVBT2, FidLogFile)


%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_rx_fextract_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
ENABLED  = DVBT2.RX.FEXTRACT.ENABLE;  % Enable
DI_FNAME = DVBT2.RX.FEXTRACT_FDI;     % Input file
DO_FNAME = DVBT2.RX.FEXTRACT_FDO;     % Output file
TYPE     = DVBT2.RX.FEXTRACT.TYPE;    % Block type
SIM_DIR  = DVBT2.SIM.SIMDIR;       % Simulation directory 

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
global DATA;

if ENABLED
  fprintf(FidLogFile,'\tDVBT2-RX-FEXTRACT: (%s)\n', TYPE);
  
  if strcmp(DI_FNAME, '')
    data = DATA;
    
  else
    load(strcat(SIM_DIR, filesep, DI_FNAME), 'data'); % Load input data
  end
  
  switch TYPE
   case 'DVBT2BL'
     data = t2_rx_dvbt2blfextract(DVBT2, FidLogFile, data);
   otherwise     
    error('Unknown frame extract type %s', TYPE);
  end   
    
else % If desabled
  fprintf(FidLogFile,'\tDVBT2-RX-FEXTRACT: DISABLED\n');
end

%------------------------------------------------------------------------------
% Output saving and formatting
%------------------------------------------------------------------------------
if ENABLED
  if strcmp(DO_FNAME, '')
    DATA = data;
    fprintf(FidLogFile,...
            '\t\tFrame extract output stored in workspace\n');
  else
    save(strcat(SIM_DIR, filesep, DO_FNAME),'data')
    fprintf(FidLogFile,...
            '\t\tFrame extract output saved in file: %s\n', DO_FNAME);
  end
end
