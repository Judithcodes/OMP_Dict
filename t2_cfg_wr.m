function DVBT2 = t2_cfg_wr(DVBT2,TestPath,FidLogFile)  

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
   error('Test path is required.');
  case 2,
    FidLogFile = 1; % Standard output   
  case 3,
  otherwise,
    error('t2_cfg_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
TYPE    = DVBT2.CFG_TYPE;   % Configuration type

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
fprintf(FidLogFile,'Configuration type: %s\n', TYPE); 
switch TYPE
  case 'DVBT2BL'
     DVBT2 = t2_cfg_dvbt2blcfg(DVBT2, TestPath);
  case 'DVBT2BL_NOL1'
     DVBT2 = t2_cfg_dvbt2blcfg_nol1(DVBT2, TestPath);
  case 'DVBT2MI'
     DVBT2 = t2_cfg_dvbt2micfg(DVBT2, TestPath);
  otherwise     
     error('Unknown configration type %s', TYPE);
end
