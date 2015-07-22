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
%* Description : T2_RX_DVBT2BLMISO DVBT2 MISO equaliser.
%*               DATAOUT = T2_RX_DVBT2BLMISO(DVBT2, FID, DATAIN) performs MISO decoding of 
%*               DATAIN following the configuration parameters of the DVBT2
%*               structure and stores the result in DATAOUT. FID specifies
%*               the file identifier where any debug message is sent.
%******************************************************************************

function DataOut = t2_rx_dvbt2blmiso(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_rx_dvbt2blmiso SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
MODE     = DVBT2.MODE;               % DVBT mode
C_DATA  = DVBT2.STANDARD.C_DATA; % Data carriers per normal symbol
C_P2	= DVBT2.STANDARD.C_P2; % Data carriers in P2 symbols
N_FC	= DVBT2.STANDARD.N_FC; % Data carriers in frame closing symbols (including the thinning cells)
L_F     = DVBT2.STANDARD.L_F; % symbols per T2-frame
N_P2    = DVBT2.STANDARD.N_P2; % Number of P2 symbols per T2-frame
L_FC    = DVBT2.STANDARD.L_FC; % Number of Frame Closing symbols

MISO_ENABLED = DVBT2.MISO_ENABLED;
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

fprintf(FidLogFile,'\t\tMode=%s\n', MODE);

if ~MISO_ENABLED
    DataOut = DataIn;
    return;
end

dataAux = DataIn.data.';
hest1 = DataIn.h_est{1}.';
hest2 = DataIn.h_est{2}.';

%sum = DataIn.h_est{1}.';
%subt = DataIn.h_est{2}.';

%hest1 = (sum + subt)/2;
%hest2 = (sum - subt)/2;
 
dataAux = reshape(dataAux, 2,[]); % each column is an Alamouti pair
hest1 = reshape(hest1, 2, []);
hest2 = reshape(hest2, 2, []);

% ZF equaliser
denom = hest1(1,:).* conj(hest1(2,:)) + hest2(1,:) .* conj(hest2(2,:));
data = (dataAux(1,:) .* conj(hest1(2,:)) + hest2(1,:) .* conj(dataAux(2,:))) ./ denom;
data = [data; (-hest2(2,:) .* conj(dataAux(1,:)) + conj(hest1(1,:)) .* dataAux(2,:))./conj(denom)];

% Calculate new effective coefficient (proportional to sqrt of power SNR)
hest = abs(denom.^2) ./ (abs(hest1(2,:)).^2 + abs (hest2(1,:)) .^2);
hest = [hest; abs(denom.^2) ./ (abs(hest2(2,:)).^2 + abs (hest1(1,:)) .^2)];
hest = sqrt(hest);

DataOut.data = reshape(data, C_DATA, []).';
DataOut.h_est = reshape(hest, C_DATA, []).';
