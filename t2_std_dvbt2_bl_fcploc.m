function FCPLoc = t2_std_dvbt2_bl_fcploc(MODE, C_PS, SP_PATTERN, EXTENDED)

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

% Scattered pilots location
switch SP_PATTERN
  case 'PP1'
    x = 3;
    y = 4;
  case 'PP2'
    x = 6;
    y = 2;
  case 'PP3'
    x = 6;
    y = 4;
  case 'PP4'
    x = 12;
    y = 2;
  case 'PP5'
    x = 12;
    y = 4;
  case 'PP6'
    x = 24;
    y = 2;
  case 'PP7'
    x = 24;
    y = 4;
  case 'PP8'
    x = 6;
    y = 16;
  otherwise, error('t2_std_dvbt2_bl_scatloc UNKNOWN MODE');
end

FCPilots = zeros(1, C_PS);
FCPilots(1:x:C_PS) = 1; % every D_x

if (strcmp(MODE,'1k') && (strcmp(SP_PATTERN,'PP4') || strcmp(SP_PATTERN,'PP5')) || strcmp(MODE,'2k') && strcmp(SP_PATTERN,'PP7'))
    FCPilots(C_PS-1) = 1;
end

FCPLoc = find(FCPilots);

