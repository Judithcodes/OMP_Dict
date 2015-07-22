function t2_ch_noise_wr(DVBT2,FidLogFile)


%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_ch_noise_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
ENABLED  = DVBT2.CH.NOISE.ENABLE;  % Noise enable
TYPE     = DVBT2.CH.NOISE.TYPE;     % Channel type
SIM_DIR   = DVBT2.SIM.SIMDIR;    % Simulation directory 
DI_FNAME = DVBT2.CH.NOISE_FDI;    % Input file
DO_FNAME = DVBT2.CH.NOISE_FDO;    % Output file

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
global DATA;

if ENABLED
  fprintf(FidLogFile, '\tDVBT2-CH-NOISE:  Adding noise (%s)\n', TYPE);

  % Reading Tx output sequence
  if strcmp(DI_FNAME, '')
    data = DATA;
  else
    load(strcat(SIM_DIR, filesep, DI_FNAME), 'data'); % Load input data
  end
  
  switch TYPE
    case 'DVBT'
    data = t2_ch_dvbtnoise(DVBT2, FidLogFile, data);
    otherwise     
    error('Unknown noise  type %s', TYPE);
  end  
else % If disabled
  fprintf(FidLogFile,'\tDVBT2-CH-NOISE - DISABLED\n');
end

%------------------------------------------------------------------------------
% Output saving and formatting
%------------------------------------------------------------------------------
if ENABLED
  if strcmp(DO_FNAME, '')
    DATA = data;
    fprintf(FidLogFile,'\t\tNoisy signal stored in workspace\n');
  else
    %strcat(SIM_DIR, filesep, DO_FNAME)
    save(strcat(SIM_DIR, filesep, DO_FNAME),'data')
    fprintf(FidLogFile,'\t\tNoisy signal saved in file: %s\n',DO_FNAME);
  end
end
