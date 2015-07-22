function t2_tx_l1gen_wr(DVBT2, FidLogFile)


%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_tx_l1gen_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
ENABLED  = DVBT2.TX.L1GEN.ENABLE;  % Enable
DI_FNAME = DVBT2.TX.L1GEN_FDI;     % Input file
DO_FNAME = DVBT2.TX.L1GEN_FDO;     % Output file
TYPE     = DVBT2.TX.L1GEN.TYPE;    % Block type 
SIM_DIR  = DVBT2.SIM.SIMDIR;    % Simulation directory 

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
global DATA;

if ENABLED
  fprintf(FidLogFile,'\tDVBT2-TX-L1GEN: (%s)\n', TYPE);

  if strcmp(DI_FNAME, '')
    data = DATA;
    %load(strcat(SIM_DIR, filesep, 'madapt_tx_do'), 'data'); % Load input data
  else
    load(strcat(SIM_DIR, filesep, DI_FNAME), 'data'); % Load input data
  end

  switch TYPE
    case 'DVBT2BL'
      data = t2_tx_dvbt2bll1gen(DVBT2, FidLogFile, data);    
    case 'DVBT2MI'
      data = t2_tx_dvbt2mil1gen(DVBT2, FidLogFile, data);
    otherwise     
      error('Unknown L1 generator type %s', TYPE);
  end
  
else % If disabled
  fprintf(FidLogFile,'\tDVBT2-TX-L1GEN: DISABLED\n');
end

%------------------------------------------------------------------------------
% Output saving and formatting
%------------------------------------------------------------------------------
if ENABLED
  if strcmp(DO_FNAME, '')
    DATA = data;
    fprintf(FidLogFile,'\t\tL1 generator output stored in workspace\n');
  else
    save(strcat(SIM_DIR, filesep, DO_FNAME),'data')
    fprintf(FidLogFile,'\t\tL1 generator output saved in file: %s\n',DO_FNAME);
  end
end
