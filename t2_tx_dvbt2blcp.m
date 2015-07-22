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
%* Description : T2_TX_DVBT2BLCP DVBT Guard Interval Insertion
%*               DOUT = T2_TX_DVBT2BLCP(DVBT, FID, DIN) Insert the guard interval
%*               to the ofdm signal following the configuration parameters of
%*               the DVBT2 structure. FID specifies the file identifier where
%*               any debug message is sent.
%******************************************************************************

function DataOut = t2_tx_dvbt2blcp(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2blcp SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
GUARD_INT = 1/DVBT2.GI_FRACTION; % Guard interval 
NFFT      = DVBT2.STANDARD.NFFT; % FFT number of points
MISO_ENABLED = DVBT2.MISO_ENABLED; % 1=MISO 0=SISO
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

if (MISO_ENABLED)
    misoGroups = 2;
else
    misoGroups = 1;
end

for misoGroup = 1:misoGroups

    dataAux = DataIn{misoGroup};

    nCP = fix(NFFT/GUARD_INT); % Number of samples of cyclic prefix

    numSymb = size(dataAux,1);
    fprintf(FidLogFile,'\t\tTx%d Guard interval=1/%d - Number of symbols=%d\n',... 
            misoGroup,GUARD_INT, numSymb);

    % Format input
    dataCP = zeros(numSymb, NFFT+nCP);
    dataCP(:, nCP + (1:NFFT)) = dataAux;
    dataCP(:, 1:nCP) = dataAux(:, NFFT-nCP+1:NFFT);
    dataAux = reshape(dataCP.', (NFFT+nCP)*numSymb, 1);

    DataOut{misoGroup} = dataAux;
end