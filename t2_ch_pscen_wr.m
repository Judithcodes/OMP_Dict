function t2_ch_pscen_wr(DVBT2, FidLogFile)
  
%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_ch_pscen_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
ENABLED  = DVBT2.CH.PSCEN.ENABLE;  % Enable of the channel propagation scenario
TYPE     = DVBT2.CH.PSCEN.TYPE;    % Channel type
SIM_DIR   = DVBT2.SIM.SIMDIR;    % Simulation directory 
DI_FNAME = DVBT2.CH.PSCEN_FDI;     % Input file
DO_FNAME = DVBT2.CH.PSCEN_FDO;     % Output file

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
global DATA;

if ENABLED
   fprintf(FidLogFile,...
      '\tDVBT2-CH-PSCEN: Applying propagation scenario: (%s)\n', TYPE);
   
   % Reading Tx output sequence
   if strcmp(DI_FNAME, '')
     data = DATA;
   else
     load(strcat(SIM_DIR, filesep, DI_FNAME), 'data'); % Load input data
   end
   
   switch TYPE
     case 'DVBT'
    %d=data{1};
    %d(3000:3010)
       data = t2_ch_dvbtpscen(DVBT2, FidLogFile, data);
    %d=data.data{1};
    %d(3000:3010)
     otherwise     
       error('Unknown propagation channel scenario  type %s', TYPE);
   end
else  
  fprintf(FidLogFile,'\tDVBT2-CH-PSCEN: DISABLED\n'); 
end
 
%------------------------------------------------------------------------------
% Output saving and formatting
%------------------------------------------------------------------------------
if ENABLED
  if strcmp(DO_FNAME, '')
    DATA = data;
    fprintf(FidLogFile,'\tChannel convolution stored in workspace\n');
  else
    save(strcat(SIM_DIR, filesep, DO_FNAME),'data') 
    fprintf(FidLogFile,'\tChannel convolution saved in file: %s\n', ...
       DO_FNAME);
  end
end
