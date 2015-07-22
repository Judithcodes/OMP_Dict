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
%* Description : T2_RX_DVBTRX_IDCODBER Computes the bit error rates after DVBT
%*               inner decoder.
%*               [BER, NUMERRORS, NUMERRFEC, NUMERRPERFEC] = ... 
%*               T2_RX_DVBTRX_IDCODBER(DVBT2) returns the bit error rate, the
%*               number of bit erros, the number of errors per FEC and the 
%*               Number of erroneous FEC blocks after the LDPC.
%*
%******************************************************************************

function [Ber, TotalErrors, TotalErrFec, AllErrPerFec] = t2_rx_dvbt2blrx_idcodber(DVBT2, FidLogFile)


%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_rx_dvbtrx_idcodber SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
PLP = DVBT2.RX_PLP; % PLP to decode in the receiver

ENABLED  = DVBT2.RX.BER.IDCOD_EN;   % Enable
TX_FNAME = DVBT2.TX.ICOD_FDI;       % Transmiter data
RX_FNAME = DVBT2.RX.IDCOD_FDO;      % Receiver data
SIM_DIR  = DVBT2.SIM.SIMDIR;        % Simulation directory 

CR     = DVBT2.STANDARD.PLP(PLP).ICOD.CR;  % Coding rate
FECLEN = DVBT2.PLP(PLP).FECLEN; 

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
global DATA;
nSymb = 0; % OFDM symbols to avoid corner cases in the BER measure
Ber = NaN;
TotalErrors = 0;
TotalErrFec = 0;
AllErrPerFec = 0;

global DVBT2_STATE;
if DVBT2.START_T2_FRAME == 0
    DVBT2_STATE.RX.IDCODBER.UNUSED_DATA = [];
    DVBT2_STATE.RX.IDCODBER.ERR_PER_FEC = [];
    DVBT2_STATE.RX.IDCODBER.TOTAL_ERR_FEC = 0;
    DVBT2_STATE.RX.IDCODBER.TOTAL_BITS = 0;
    DVBT2_STATE.RX.IDCODBER.TOTAL_ERRORS = 0;
end

if ENABLED
    
    AllErrPerFec = DVBT2_STATE.RX.IDCODBER.ERR_PER_FEC;
    TotalErrFec = DVBT2_STATE.RX.IDCODBER.TOTAL_ERR_FEC;
    TotalBits = DVBT2_STATE.RX.IDCODBER.TOTAL_BITS;
    TotalErrors = DVBT2_STATE.RX.IDCODBER.TOTAL_ERRORS;



  if strcmp(TX_FNAME, '')
    fprintf(FidLogFile,'\tINFO: BER computation aborted - TX file not saved\n');
    return;
  end  
  
  fprintf(FidLogFile,'\tINFO: Inner decoder output BER = ');
  
  % Load input data
  if strcmp(RX_FNAME, '')
    rxData = DATA(:);
  else
    load(strcat(SIM_DIR, filesep, RX_FNAME), 'data');
    rxData = data(:);
  end
  
  load(strcat(SIM_DIR, filesep, TX_FNAME), 'data');
  txData = data.data{PLP}(:);
  
  if ~isempty(rxData)
    rxData = de2bi(rxData(:), 8, 'left-msb');
  end
  
  rxData = reshape(rxData.', [],1);
  numBits = length(rxData);
  
  txData = txData(:);
  if ~isempty(txData)
    txData = de2bi(txData, 8, 'left-msb');
  end
  txData = reshape(txData.', [],1);
  txData = [DVBT2_STATE.RX.IDCODBER.UNUSED_DATA; txData];

  DVBT2_STATE.RX.IDCODBER.UNUSED_DATA = txData(numBits+1:end);
  txData = txData(1:numBits);
  aux = xor(rxData, txData);
  TotalErrors = TotalErrors + sum(aux); % Number of erroneous bits
  TotalBits = TotalBits + numBits;
  nDataPerFecBlock = FECLEN*CR;
  aux = reshape(aux, nDataPerFecBlock, []);   
  NumErrPerFec=sum(aux,1); % Number of errors per FEC
  AllErrPerFec = [AllErrPerFec NumErrPerFec];
  
  
  NumErrFec = length(find(NumErrPerFec)); % Number of erroneous FEC blocks
  TotalErrFec = TotalErrFec + NumErrFec;
  
  Ber = TotalErrors/TotalBits;
  fprintf(FidLogFile,'%f (%d/%d)\n', Ber, TotalErrors, TotalBits);
  fprintf(FidLogFile,'\tINFO: Number of erroneous FEC blocks: %d of %d\n', TotalErrFec, length(AllErrPerFec));

  DVBT2_STATE.RX.IDCODBER.ERR_PER_FEC = AllErrPerFec;
  DVBT2_STATE.RX.IDCODBER.TOTAL_ERR_FEC = TotalErrFec;
  DVBT2_STATE.RX.IDCODBER.TOTAL_BITS = TotalBits;
  DVBT2_STATE.RX.IDCODBER.TOTAL_ERRORS = TotalErrors;

end
