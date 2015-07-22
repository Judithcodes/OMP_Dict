function STD = t2_std_config_wr(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
    ;
  otherwise,
    error('t2_std_config_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
TYPE     = DVBT2.STD_TYPE;   % Standard type

switch TYPE
 case 'DVBT2BL'
  STD = t2_std_dvbt2_bl(DVBT2, FidLogFile); 
 otherwise     
  error(sprintf('Unknown standard type %s', TYPE));
end


