function [SPLoc, SPPattlen, SP_DX] = t2_std_dvbt2_bl_scatloc(C_PS, SP_PATTERN, EXTENDED, K_EXT)

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

SPLoc = zeros(y, ceil(C_PS/(x*y)));

for l=0:y-1
    if (EXTENDED)
        loc = find(mod((0:C_PS-1)-K_EXT, x*y) == x*(mod(l,y)));
    else
        loc = find(mod(0:C_PS-1, x*y) == x*(mod(l,y)));
    end
  %m = x*mod(k-1,y)+1;
  %loc = m:x*y:C_PS;  
    SPLoc(l+1,1:length(loc)) = loc;  
end

SPPattlen=y;
SP_DX = x;

