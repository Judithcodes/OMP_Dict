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
%* Description : T2_STD_DVBT2_BL_C_FC DVBT2 Number of active cells in FCS
%*               C_FC = T2_STD_DVBT2_BL_C_FC(Mode, Extended, SpPattern) 
%*               returns the number of active cells in the frame closing
%                symbol
%******************************************************************************

function C_FC = t2_std_dvbt2_bl_c_fc(MODE, EXTENDED, SP_PATTERN, FC_TR_LOC)
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

% Table in the same format as in ES 302 755
CFCTable = [ ...
402	654	490	707	544	0 0 0; ...
804	1309 980 1415 1088 0 1396 0; ...
1609 2619 1961 2831 2177 0 2792 0; ...
3218	5238	3922	5662	4354 0 5585 0; ...
3264	5312	3978	5742	4416 0 5664 0 ;...
6437	10476	7845	11324	8709	11801	11170 0; ...
6573	10697	8011	11563	8893	12051	11406 0; ...
0 20952 0 22649 0 23603 0 0; ...
0 21395 0 23127 0 24102 0 0; ...
];


% Scattered pilots location
switch SP_PATTERN
  case 'PP1'
    c = 1;
  case 'PP2'
    c = 2;
  case 'PP3'
    c = 3;
  case 'PP4'
    c = 4;
  case 'PP5'
    c = 5;
  case 'PP6'
    c = 6;
  case 'PP7'
    c = 7;
  case 'PP8'
    c = 8;
  otherwise, error('t2_std_dvbt2_bl_scatloc SP Pattern');
end

switch MODE
    case '1k'
        r=1;
    case '2k'
        r=2;
    case '4k'
        r=3;
    case '8k'
        r=4;
    case '16k'
        r=6;
    case '32k'
        r=8;
    otherwise, error('t2_std_dvbt2_bl_c_fc UNKNOWN MODE');
end
if (EXTENDED), r=r+1; end

C_FC = CFCTable(r,c) - length(FC_TR_LOC);
