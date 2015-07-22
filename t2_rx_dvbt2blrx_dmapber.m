function BER = t2_rx_dvbt2blrx_dmapber(DVBT2, FidLogFile)


%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_rx_dvbtrx_dmapber SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
PLP = DVBT2.RX_PLP; % PLP to decode in the receiver

ENABLED  = DVBT2.RX.BER.DMAP_EN; % Enable
TX_FNAME = DVBT2.TX.BMAP_FDO;    % Transmiter data
RX_FNAME = DVBT2.RX.BDMAP_FDI;   % Receiver data
SIM_DIR  = DVBT2.SIM.SIMDIR;     % Simulation directory 

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
BER = NaN;
global DATA;

global DVBT2_STATE;
if DVBT2.START_T2_FRAME == 0
    DVBT2_STATE.RX.DMAPBER.UNUSED_DATA = [];
    DVBT2_STATE.RX.DMAPBER.TOTAL_ERRORS = 0;
    DVBT2_STATE.RX.DMAPBER.TOTAL_BITS = 0;
end

totalErrors = DVBT2_STATE.RX.DMAPBER.TOTAL_ERRORS;
totalBits = DVBT2_STATE.RX.DMAPBER.TOTAL_BITS;

if ENABLED
  if strcmp(TX_FNAME, '')
    fprintf(FidLogFile,'\tINFO: BER computation aborted - TX file not saved\n');
    return;
  end

  % Load input data
  if strcmp(RX_FNAME, '')
    rxData = DATA;
  else
    rxData = load(strcat(SIM_DIR, filesep, RX_FNAME));
    rxData = rxData.data;
  end

  txData = load(strcat(SIM_DIR, filesep, TX_FNAME)); 
  txData = txData.data.data{PLP};
    
  bitsPerSymb = size(rxData,1); % Bits per mapper symbols
  
  % Converts to bits TX data
  txData = txData(:);
  if ~isempty(txData)
    txData = de2bi(txData, bitsPerSymb, 'left-msb').';
  end
  txData = reshape(txData, [],1);
  txData = [DVBT2_STATE.RX.DMAPBER.UNUSED_DATA; txData(:)];
  
  fprintf(FidLogFile,'\tINFO: Demapper output BER=');
  
  % BER can be calculated only if hard decision is used
  rxData = reshape(rxData, [],1);
  if ~isempty(rxData)
    rxData = ~(quantiz(rxData,0));  
  end
    
  numBits = length(rxData);
  
  DVBT2_STATE.RX.DMAPBER.UNUSED_DATA = txData(numBits+1:end);
  txData = txData(1:numBits);
  totalErrors = totalErrors + sum(xor(rxData, txData));
  totalBits = totalBits + numBits;
    
  BER = totalErrors/totalBits;
    
  fprintf(FidLogFile,'%f (%d/%d)\n', BER, totalErrors, totalBits);

  DVBT2_STATE.RX.DMAPBER.TOTAL_ERRORS = totalErrors;
  DVBT2_STATE.RX.DMAPBER.TOTAL_BITS = totalBits;

end

