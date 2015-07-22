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
%* Description : T2_TX_DVBT2BLBDMAP DVBT2 Bit De-Mapping
%*               DOUT = T2_TX_DVBT2BLBDMAP(DVBT2, FID, DIN) 
%*               FID specifies the file identifier where any debug message is 
%*               sent.
%******************************************************************************

function DataOut = t2_rx_dvbt2blbdmap(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_rx_dvbt2blbdmap SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
PLP = DVBT2.RX_PLP; % PLP to decode in the receiver

V        = DVBT2.STANDARD.PLP(PLP).MAP.V; % Bits per celll
CONSTEL  = DVBT2.PLP(PLP).CONSTELLATION;      % DVBT2 constellation
CRATE    = DVBT2.PLP(PLP).CRATE; %the code rate
FECLEN   = DVBT2.PLP(PLP).FECLEN; %the inner fec length
SPEC_VERSION = DVBT2.SPEC_VERSION;
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

%DataOut = reshape(DataIn,1,[]);

data = DataIn;

streams = V * 2;

switch CONSTEL
  case 'QPSK'
    mapping = [0 1 2 3] + 1;
  case '16-QAM'
    if strcmp(CRATE,'3/5') && FECLEN == 64800
      mapping = [0 5 1 2 4 7 3 6] + 1;
    elseif strcmp(CRATE,'1/3') && FECLEN == 16200
      mapping = [6 0 3 4 5 2 1 7] + 1;
    elseif strcmp(CRATE,'2/5') && FECLEN == 16200
      mapping = [7 5 4 0 3 1 2 6] + 1;
    else
      mapping = [7 1 4 2 5 3 6 0] + 1;
    end
  case '64-QAM'
    if strcmp(CRATE,'3/5') && FECLEN == 64800
      mapping = [2 7 6 9 0 3 1 8 4 11 5 10] + 1;
    elseif strcmp(CRATE,'1/3') && FECLEN == 16200      
      mapping = [4 2 0 5 6 1 3 7 8 9 10 11] + 1;
    elseif strcmp(CRATE,'2/5') && FECLEN == 16200
      mapping = [4 0 1 6 2 3 5 8 7 10 9 11] + 1;
    else
      mapping = [11 7 3 10 6 2 9 5 1 8 4 0] + 1;
    end
  case '256-QAM'
    if FECLEN == 16200
      if strcmp(CRATE,'1/3') && FECLEN == 16200        
        mapping = [4 0 1 2 5 3 6 7] + 1;
      elseif strcmp(CRATE,'2/5') && FECLEN == 16200
        mapping = [4 0 5 1 2 3 6 7] + 1;
      else
        mapping = [7 3 1 5 2 6 4 0] + 1;
      end
      
      streams = V;
    else
      if strcmp(CRATE,'3/5')
        mapping = [2 11 3 4 0 9 1 8 10 13 7 14 6 15 5 12] + 1;
      elseif strcmp(CRATE,'2/3') && ~strcmp(SPEC_VERSION, '1.0.1')
        mapping = [7 2 9 0 4 6 13 3 14 10 15 5 8 12 11 1] + 1;
      else
        mapping = [15 1 13 3 8 11 9 5 10 6 4 7 12 2 14 0] + 1;
      end
    end
end

data=reshape(data, 1, []);
numBits  = length(data);
numCells = floor(numBits/streams);
numBits  = numCells*streams;


cells = reshape(data', streams, size(data,2)/streams)';

%swap this to agree with spec, above line maps the wrong way
cells = cells(:, mapping);

DataOut = reshape(cells',1,[]);

