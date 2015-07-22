function t2_tx_fadapt_wr(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
    ;
  otherwise,
    error('t2_tx_fadapt_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
ENABLED  = DVBT2.TX.FADAPT.ENABLE; % Enable
DI_FNAME = DVBT2.TX.FADAPT_FDI;    % Input file
DO_FNAME = DVBT2.TX.FADAPT_FDO;    % Output file
TYPE     = DVBT2.TX.FADAPT.TYPE;   % Block type 
SIM_DIR  = DVBT2.SIM.SIMDIR;       % Simulation directory 

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

if ENABLED
  fprintf(FidLogFile,'\tDVBT2-TX-FADAPT: (%s)\n', TYPE);

  if strcmp(DI_FNAME, '')
    global DATA;
    data = DATA;
    
  else
    load(strcat(SIM_DIR, filesep, DI_FNAME), 'data'); % Load input data
  end        
  
  switch TYPE
    case 'DVBT2BL'
      data = t2_tx_dvbt2blfadapt(DVBT2, FidLogFile, data);
    otherwise     
      error(sprintf('Unknown frame adaptation type %s', TYPE));
  end
  
else % If disabled
  fprintf(FidLogFile,'\tDVBT2-TX-FADAPT: DISABLED\n');
end

%------------------------------------------------------------------------------
% Output saving and formatting
%------------------------------------------------------------------------------
if ENABLED
  if strcmp(DO_FNAME, '')
    global DATA;
    DATA = data;
    fprintf(FidLogFile,'\t\tFrame adaptation output stored in workspace\n');
  else
    save(strcat(SIM_DIR, filesep, DO_FNAME),'data')
    fprintf(FidLogFile,'\t\tFrame adaptation output saved in file: %s\n',...
            DO_FNAME);
  end
end
