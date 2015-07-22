%*******************************************************************************
%* Copyright (c) 2011 AICIA, BBC, Pace, Panasonic, SIDSA
%* 
%* Permission is hereby granted, free of charge, to any person obtaining a copy
%* of this software and associated documentation files (the "Software"), to deal
%* in the Software without restriction, including without limitation the rights
%* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%* copies of the Software, and to permit persons to whom the Software is
%* furnished to do so, subject to the following conditions:
%*
%* The above copyright notice and this permission notice shall be included in
%* all copies or substantial portions of the Software.
%*
%* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%* THE SOFTWARE.
%* 
%* This notice contains a licence of copyright only and does not grant 
%* (implicitly or otherwise) any patent licence and no permission is given 
%* under this notice with regards to any third party intellectual property 
%* rights that might be used for the implementation of the Software.  
%*
%******************************************************************************
%* Project     : DVB-T2 Common Simulation Platform 
%* URL         : http://dvb-t2-csp.sourceforge.net
%* Date        : $Date$
%* Version     : $Revision$
%* Description : T2_STD_DVBT2_BL_P2PLOC DVBT2 P2 Pilots Location 
%*               P2PLOC = T2_STD_DVBT2_BL_P2PLOC(...) 
%*               generates the P2 pilots location vector 
%******************************************************************************

function P2PLoc = t2_std_dvbt2_bl_p2ploc(MODE, C_PS, K_EXT, TR_LOC, SP_PATTERN, EXTENDED, MISO_ENABLED)

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

if (strcmp(MODE,'32k') && ~MISO_ENABLED)
    step=6;
else
    step=3;
end

P2Pilots = zeros(1, C_PS);
P2Pilots(1:step:C_PS) = 1; % every 3 or 6
if (EXTENDED)
    P2Pilots(1:K_EXT) = 1;
    P2Pilots(C_PS-K_EXT+1:C_PS) = 1;
    TR_LOC = TR_LOC + K_EXT;
end

if (MISO_ENABLED)
    if (EXTENDED)
        P2Pilots(K_EXT+2:K_EXT+3) = 1;
        P2Pilots(C_PS-K_EXT-2: C_PS-K_EXT-1) = 1;
    else
        P2Pilots(2:3) = 1;
        P2Pilots(C_PS-2: C_PS-1) = 1;
    end
    % TR partners
    P2Pilots(TR_LOC(mod(TR_LOC-1,3)==1)+1) = 1;
    P2Pilots(TR_LOC(mod(TR_LOC-1,3)==2)-1) = 1;
    P2Pilots(TR_LOC) = 0; % Expunge any that are already reserved tones
end


P2PLoc = find(P2Pilots);
