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
%* Description : T2_STD_DVBT2_BL_FC_USE DVBT2 Use of Frame closing symbol 
%*               L_FC = T2_STD_DVBT2_BL_FC_USE(MODE, GI, SP_PATTERN) 
%*               returns the number of frame closing symbols (i.e. 0 or 1)
%******************************************************************************

function L_FC = t2_std_dvbt2_bl_fc_use(MODE, GI_FRACTION, SP_PATTERN, MISO_ENABLED)

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

FCSUseTable = {...
    {}  {'PP6'} {'PP4'} {'PP4'} {'PP2'} {'PP2'} {}; ...
    {} {'PP7' 'PP6'} {'PP4' 'PP5'} {'PP4' 'PP5'} {'PP2' 'PP3'} {'PP2' 'PP3'} {'PP1'}; ...
    {} {'PP7'} {'PP4' 'PP5'} {'PP4' 'PP5'} {'PP2' 'PP3'} {'PP2' 'PP3'} {'PP1'}; ...
    {} {'PP7'} {'PP4' 'PP5'} {} {'PP2' 'PP3'} {} {'PP1'}; ...
    {} {} {'PP4' 'PP5'} {} {'PP2' 'PP3'} {} {'PP1'} ...
    };
   
    

if (MISO_ENABLED)
    if SP_PATTERN=='PP8'
        L_FC = 0;
    else
        L_FC = 1;
    end
else

    switch MODE % get row of table 58
        case '1k'
            r=5;
        case '2k'
            r=4;
        case '4k'
            r=4;
        case '8k'
            r=3;
        case '16k'
            r=2;
        case '32k'
            r=1;
        otherwise, error('t2_std_dvbt2_bl_fc_use UNKNOWN MODE');
    end

    % column of table 58
    c = find([1/128 1/32 1/16 19/256 1/8 19/128 1/4]== GI_FRACTION);

    if isempty(find(ismember(FCSUseTable{r,c},SP_PATTERN), 1))
        L_FC = 0; % FCS not used in this combo
    else
        L_FC = 1;
    end
end