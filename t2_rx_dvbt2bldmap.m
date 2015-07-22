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
%* Description : T2_RX_DVBT2BLDMAP DVBT2 Demapper
%*               DATAOUT = T2_RX_DVBT2BLDMAP(DVBT2, FID, DATAIN) demaps DATAIN
%*               and stores de result in DATAOUT following the configuration 
%*               parameters of the DVBT2 structure. FID specifies the file
%*               identifier where any debug message is sent.
%******************************************************************************

function DataOut = t2_rx_dvbt2bldmap(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_rx_dvbt2bldmap SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------

PLP = DVBT2.RX_PLP; % PLP to decode in the receiver

MODE     = DVBT2.MODE;                  % DVBT mode
CONSTEL  = DVBT2.PLP(PLP).CONSTELLATION;         % DVBT constellation
V        = DVBT2.STANDARD.PLP(PLP).MAP.V;        % Bits per cell
SNR      = DVBT2.CH.NOISE.SNR;          % Signal to noise ratio (dB)
C        = DVBT2.STANDARD.PLP(PLP).MAP.C;        % Bits per cell
           
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

dataAux = DataIn.data;  % Data carriers
chStateInf = abs(DataIn.h_est).^2; % CSI: Channel State Information 

fprintf(FidLogFile,'\t\tLLR Demapper - %s\n', CONSTEL);
fSigma = 10^(-SNR/10);
numPoints = size(dataAux, 2);

% Matlab and DVB grey constellation are different 
dataAux = -conj(dataAux);

qamDemodObj = modem.qamdemod('M', 2^V, 'SymbolOrder', 'Gray', ...
      'OutputType', 'Bit', 'DecisionType', 'Approximate LLR', 'NoiseVariance', (C^2)*fSigma);

dataAux = demodulate(qamDemodObj, C*dataAux);

% Apply CSI
chStateInf=repmat(chStateInf, V,1);
dataAux=dataAux.*chStateInf;

% Bit reordering
DataOut=zeros(size(dataAux));
k=1:2:V;
DataOut(1:2:V,:)=dataAux(1:V/2,:);
DataOut(2:2:V,:)=dataAux(V/2 + (1:V/2),:);

