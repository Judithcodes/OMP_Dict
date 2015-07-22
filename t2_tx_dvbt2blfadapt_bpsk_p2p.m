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
%* Description : T2_TX_DVBT2BLFADAPT_BPSK_P2P BPSK modulator for P2 pilots.
%*               MAPPED_DATA = T2_TX_DVBT2BLFADAPT_BPSK_P2P(DATA) generates the
%*               BPSK mapping of DATA with appropriate amplitude according
%                to the P2 pilot pattern.
%******************************************************************************

function DataOut = t2_tx_dvbt2blfadapt_bpsk_p2p(DVBT2, DataIn)


%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
MODE          = DVBT2.MODE; % Scattered pilot pattern
MISO_ENABLED  = DVBT2.MISO_ENABLED; % Scattered pilot pattern

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

if (strcmp(MODE,'32k') && ~MISO_ENABLED)
    C = sqrt(37)/5;
else
    C = sqrt(31)/5;
end

C_POINTS    = [1 -1]*C; % Constellation points

DataOut = C_POINTS(DataIn+1);
