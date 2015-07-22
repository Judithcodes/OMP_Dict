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
%* Description : T2_TX_DVBT2TXSIGAUXGEN DVBT2 Aux stream TX-SIG tenerator
%*               DOUT = T2_TX_DVBT2TXSIGAUXGEN(DVBT2, FID, DIN) passes the input
%*               data straight through and generates and generates the aux
%*               stream
%******************************************************************************

function DataOut = t2_tx_dvbt2bltxsigauxgen(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2bltxsigauxgen SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------

NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES;

NUM_AUX = DVBT2.NUM_AUX;
START_T2_FRAME = DVBT2.START_T2_FRAME;

%L_F = DVBT2.STANDARD.L_F; % Number of symbols per T2 frame
N_P2 = DVBT2.STANDARD.N_P2; % Number of P2 symbols per T2-frame
%L_FC = DVBT2.STANDARD.L_FC; % Number of Frame Closing symbols

C_DATA = DVBT2.STANDARD.C_DATA; % Active cells per symbol
C_P2 = DVBT2.STANDARD.C_P2; % Active cells per P2 symbol
%C_FC = DVBT2.STANDARD.C_FC; % Active cells in Frame closing symbol
%N_FC = DVBT2.STANDARD.N_FC; % Data cells in Frame closing symbol including thinning cells

D_L1 = DVBT2.STANDARD.D_L1PRE + DVBT2.STANDARD.D_L1POST; % total L1 length
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
data = DataIn.data;
SCHED = DataIn.sched;

for aux=1:NUM_AUX
   if  DVBT2.AUX(aux).AUX_STREAM_TYPE == 0 % Tx-Sig
       TX_ID = DVBT2.AUX(aux).TX_ID;
       P = DVBT2.AUX(aux).P;
       M = 3*(P+1);
       N = 2^DVBT2.AUX(aux).Q;
       L = DVBT2.AUX(aux).R + 1;
       K = 1 + 4*(P+1)*N;
       
       amplTCell = sqrt(4/3);
       
       txSigCellTypeZT = zeros(M*N, NUM_SIM_T2_FRAMES); % 0=Z cell
       txSigFrame = mod(START_T2_FRAME + (0:NUM_SIM_T2_FRAMES-1), L);
       txSigCellIndex = mod(repmat((0:M*N-1).',1,NUM_SIM_T2_FRAMES)-repmat(txSigFrame*N,M*N,1),M*N);        % which cell in the pattern it is, accounting for cyclic shift
       % insert T cells
       txSigCellTypeZT(floor(txSigCellIndex/N)==TX_ID) = 1; % 1=T cell
       % insert B cells
       txSigCellType = zeros(K, NUM_SIM_T2_FRAMES);       
       txSigCellType(mod(0:K-1,4)==0,:)=2; % 2=B cell
       txSigCellType(txSigCellType~=2) = txSigCellTypeZT;
       
       % Make modulation values
       txSigCellModIndex = reshape(0:K*NUM_SIM_T2_FRAMES-1, K, NUM_SIM_T2_FRAMES);
       txSigCellModIndex = txSigCellModIndex + txSigFrame(1)*K;
       txSigCellModIndex = mod(txSigCellModIndex, K*L);
       
       modSequence = 2*(0.5-t2_tx_dvbt2blbbscramble_bbprbsseq(K*L)).';
       txSigCellMod = modSequence(txSigCellModIndex+1);
       
       txSigData = txSigCellMod; % modulate all cells at amplitude 1
       txSigData(txSigCellType == 0) = 0; % Z-cells have zero amplitude
       txSigData(txSigCellType == 1) = txSigData(txSigCellType == 1) * amplTCell; % T-cells amplitude sqrt(4/3)

       % Work out the modulation amplitude for the B cells (painful)
       
       % cell address for each cell
       txSigCellAddress = SCHED.AUX(aux).START(1,START_T2_FRAME+1:START_T2_FRAME+NUM_SIM_T2_FRAMES);
       txSigCellAddress = repmat(txSigCellAddress, K,1); % start address in each T2-frame
       txSigCellAddress = txSigCellAddress+repmat((0:K-1).',1,NUM_SIM_T2_FRAMES); % address of each cell in each T2-frame
       
       % Work out which OFDM symbol each cell falls in
       dataCellsP2Total = N_P2*C_P2-D_L1;
       dataCellsPerP2 = dataCellsP2Total / N_P2;
       txSigCellSymbol = floor((txSigCellAddress-dataCellsP2Total)/C_DATA)+N_P2;
       txSigCellSymbol(txSigCellSymbol<N_P2) = floor(txSigCellAddress(txSigCellSymbol<N_P2)/dataCellsPerP2);
       
       minSymb = min(txSigCellSymbol(:));
       maxSymb = max(txSigCellSymbol(:));
       for symb = minSymb:maxSymb
           isTCellInSymb = (txSigCellType==1) & (txSigCellSymbol==symb);
           isBCellInSymb = (txSigCellType==2) & (txSigCellSymbol==symb);
           numTCellsInSymbol = sum(isTCellInSymb,1); % number of T-cells in given symbol in each T2-frame
           numBCellsInSymbol = sum(isBCellInSymb,1); % number of B-cells in given symbol in each T2-frame
           numTxSigCellsInSymbol = sum(txSigCellSymbol==symb,1); % total number of TxSig cells in the symbol
           % Nt * (4/3)^2 + Nb * Ab^2 = Ntot
           amplBCell = sqrt((numTxSigCellsInSymbol - numTCellsInSymbol*amplTCell.^2)./numBCellsInSymbol);
           amplBCell = repmat(amplBCell, K,1); % Make it the same shape as the other arrays
           txSigData(isBCellInSymb) = txSigData(isBCellInSymb) .* amplBCell(isBCellInSymb);
           DataOut.auxData{aux} = txSigData;
       end
   else
       DataOut.auxData{aux} = [];
   end
end

fprintf(FidLogFile,'\t\tT2 Frames of TxSigAux generated = %d frames\n', NUM_SIM_T2_FRAMES);


DataOut.data = data;
DataOut.sched = SCHED;
DataOut.l1 = DataIn.l1;
end

