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
%* Description : T2_RX_DVBTRX_SADAPTBER Computes the bit error rates after
%*               DVBT2 stream adaptor.
%*               [BER_HP, BER_LP] = T2_RX_DVBTRX_SADAPTBER(DVBT2) returns the
%*               bit error rate of the high and low (if any) priority streams
%*               after the DVBT2 stream adaptor.
%*
%*               [BER_HP, BER_LP] = T2_RX_DVBTRX_SADAPTBER(DVBT2, FID) specifies
%*               the file identifier in FID where any debug message is sent.
%******************************************************************************

function [Ber] = t2_rx_dvbt2blrx_sadaptber(DVBT2, FidLogFile)


%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_rx_dvbtrx_sadaptber SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
PLP = DVBT2.RX_PLP; % PLP to decode in the receiver

ENABLED  = DVBT2.RX.BER.SADAPT_EN;  % Enable
TX_FNAME = DVBT2.TX.MADAPT_FDI;     % Transmiter data
RX_FNAME = DVBT2.RX.SADAPT_FDO;     % Receiver data
SIM_DIR  = DVBT2.SIM.SIMDIR;        % Simulation directory 

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
global DATA;
Ber = NaN;


global DVBT2_STATE;
if DVBT2.START_T2_FRAME == 0
    DVBT2_STATE.RX.SADAPTBER.UNUSED_DATA = [];
    DVBT2_STATE.RX.SADAPTBER.TOTAL_ERRORS = 0;
    DVBT2_STATE.RX.SADAPTBER.TOTAL_BITS = 0;
end

totalErrors = DVBT2_STATE.RX.SADAPTBER.TOTAL_ERRORS;
totalBits = DVBT2_STATE.RX.SADAPTBER.TOTAL_BITS;

if ENABLED
  if strcmp(TX_FNAME, '')
    fprintf(FidLogFile,'\tINFO: BER computation aborted - TX file not saved\n');
    return;
  end  
  
  fprintf(FidLogFile,'\tINFO: Stream adaption output BER = ');
  
  % Load input data
  if strcmp(RX_FNAME, '')
    rxData = DATA;
  else
    load(strcat(SIM_DIR, filesep, RX_FNAME), 'data');
    rxData = data;
  end
  
  load(strcat(SIM_DIR, filesep, TX_FNAME), 'data');
  txData = data{PLP};
  
  rxData = reshape(rxData.',1, []);
  txData = reshape(txData.',1, []);
  
  bytes = length(rxData);
  if ~isempty(rxData)
    rxData = de2bi(rxData, 8, 'left-msb').';
  end
  rxData = reshape(rxData, 8*bytes,1);
  bits = length(rxData);
  
  %txData = txData(1:bytes);
  if ~isempty(txData)
    txData = de2bi(txData, 8, 'left-msb').';
  end
  txData = [DVBT2_STATE.RX.SADAPTBER.UNUSED_DATA; txData(:)];
  DVBT2_STATE.RX.SADAPTBER.UNUSED_DATA = txData(bits+1:end); % Save tx bits that haven't been received yet
  txData = txData(1:bits);

  totalErrors = totalErrors + sum(xor(rxData, txData));
  totalBits = totalBits + bits;

  Ber = totalErrors/totalBits;

  DVBT2_STATE.RX.SADAPTBER.TOTAL_BITS = totalBits;
  DVBT2_STATE.RX.SADAPTBER.TOTAL_ERRORS = totalErrors;

  fprintf(FidLogFile,'%f (%d/%d)\n', Ber, totalErrors, totalBits);

end
