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
%* Description : T2_RX_DVBT2BLCP DVBT Cyclic Prefix Removal Block
%*               DATAOUT = T2_RX_DVBT2BLCP(DVBT2, FID, DATAIN) Removes the guard 
%*               interval of the ofdm signal DATAIN and stores the result in 
%*               DATAOUT. FID specifies the file identifier where any debug
%*               message is sent.
%******************************************************************************

function DataOut = t2_rx_dvbt2blcp(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_rx_dvbt2blcp SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
GUARD_INT = 1/DVBT2.GI_FRACTION; % Guard interval 
NFFT      = DVBT2.STANDARD.NFFT; % FFT number of points

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

dataAux = DataIn.data;

nCP = fix(NFFT/GUARD_INT); % Number of samples of cyclic prefix

nPerSym = NFFT + nCP;      % Number of samples per symbols

numSymb = floor(length(dataAux)/nPerSym); % Number of symbols
  
dataAux = dataAux(1:numSymb*nPerSym);
  
dataAux = reshape(dataAux, nPerSym, numSymb); % Format input
  
fprintf(FidLogFile,'\t\tGuard interval=1/%d - Number of symbols=%d\n',... 
        GUARD_INT, numSymb);

DataOut = dataAux((nCP+1):end, :).'; % Remove nCP samples
