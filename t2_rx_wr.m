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
%* Description : T2_RX_WR DVB-T2 Receiver Wrapper
%*               RESULT = T2_RX_WR(DVBT2) wrapper for the DVBT2 receiver. 
%*               Depending on the parameters of the DVBT2 structure, this 
%*               function select the im plementation of the receiver.
%*
%*               Depending on the seletced implementation, some simulation 
%*               results like the bit error rate may be available in the RESULT
%*               structure.
%*  
%*               RESULT = T2_RX_WR(DVBT2, FID) specifies the file identifier in 
%*               FID where any debug message is sent.
%******************************************************************************

function Result = t2_rx_wr(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_rx_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
ENABLED = DVBT2.RX.ENABLE; % Receiver enable
TYPE    = DVBT2.RX.TYPE;   % Transmiter type

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

if ENABLED
  fprintf(FidLogFile,'Starting Rx Digital Video Broadcasting - DVB-T2:(%s)\n', TYPE);

  switch TYPE
    case 'DVBT2BL'
      Result = t2_rx_dvbt2blrx(DVBT2, FidLogFile);    
    otherwise     
      sprintf('Unknown receiver type %s', TYPE);
  end
  
  fprintf(FidLogFile,'End of Rx Digital Video Broadcasting - DVB-T2 \n');
else
  fprintf(FidLogFile,'Rx Digital Video Broadcasting - DVB-T2 - DISABLED \n');
  Result = 0;
end
