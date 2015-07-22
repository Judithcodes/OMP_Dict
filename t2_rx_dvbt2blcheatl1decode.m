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
%* Description : T2_RX_DVBT2BLCHEATL1DECODE DVBT2 cheat-wire L1 decoding
%*               DOUT = T2_RX_DVBT2BLCHEATL1DECODE(DVBT2, FID, DIN, SCHED)
%*
%*               copies the SCHED (from the scheduler in the tx) to the
%*               output. Future implementations would actually decode the
%*               L1 signalling.
%******************************************************************************

function DataOut = t2_rx_dvbt2blcheatl1decode(DVBT2, FidLogFile, DataIn)  
%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2blcheatl1decode SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
SCHED_FNAME = DVBT2.TX.MADAPT_FDO; % Output of mode adapter including scheduling info
SIM_DIR  = DVBT2.SIM.SIMDIR;    % Simulation directory 
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
DataOut.data = DataIn.data;
DataOut.h_est = DataIn.h_est;

% Read the scheduler output file
if strcmp(SCHED_FNAME, '')
    error('t2_rx_dvbt2blcheatl1decode: missing scheduler output file');
else
    load(strcat(SIM_DIR, filesep, SCHED_FNAME), 'data'); % Load input data
    SCHED = data.sched;
end

fprintf(FidLogFile, '\t\tRead schedule from Mode Adapter output\n');

DataOut.sched = SCHED;

