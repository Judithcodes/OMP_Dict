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
%* Description : T2_RX_DVBT2BLTDINT DVBT2 Time De-Interleaver.
%*               DATAOUT = T2_RX_DVBT2BLTDINT(DVBT2, FID, DATAIN) de-interleaves 
%*               the data DATAIN and stores the result in DATAOUT following the
%*               configuration parameters of the DVBT2 structure. FID specifies
%*               the file identifier where any debug message is sent.
%******************************************************************************

function DataOut = t2_rx_dvbt2bltdint(DVBT2, FidLogFile, DataIn)

%-------------------------------------------------------------------------
% 

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_rx_dvbt2tdint SYNTAX');
end

%------------------------------------------------------------------------------
% State initialisation
%------------------------------------------------------------------------------
global DVBT2_STATE;
if DVBT2.START_T2_FRAME == 0
  DVBT2_STATE.TDINT.UNUSED_DATA = [];
  DVBT2_STATE.TDINT.UNUSED_HEST = [];
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------  

PLP = DVBT2.RX_PLP; % PLP to decode in the receiver
FECLEN = DVBT2.PLP(PLP).FECLEN; % FEC block size (16200 or 64800)
NSPLIT = 5; % Number of columns occupied by each FEC block. 
BITS_PER_CELL = DVBT2.STANDARD.PLP(PLP).MAP.V;
NTI = DVBT2.PLP(PLP).NTI; % Number of TI blocks per Interleaving Frame
START_T2_FRAME = DVBT2.START_T2_FRAME;
NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES;
P_I = DVBT2.PLP(PLP).P_I;
I_JUMP = DVBT2.PLP(PLP).I_JUMP;
FIRST_FRAME_IDX = DVBT2.PLP(PLP).FIRST_FRAME_IDX;


%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

SCHED = DataIn.sched;

lastFrameIdx = FIRST_FRAME_IDX + (P_I-1)*I_JUMP; % last T2 frame of first interleaving frame
START_INT_FRAME = ceil((START_T2_FRAME-lastFrameIdx)/(P_I * I_JUMP));
endIntFrame = floor((START_T2_FRAME+NUM_SIM_T2_FRAMES-1-lastFrameIdx)/(P_I * I_JUMP));
NUM_INT_FRAMES = endIntFrame - START_INT_FRAME + 1;
NBLOCKS = SCHED.NBLOCKS{PLP}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame
NUM_FBLOCK = sum(NBLOCKS); % Total number of FEC blocks to generate

if NTI>0
  
  cellsPerFECBlock = FECLEN / BITS_PER_CELL;
  numCols = cellsPerFECBlock / NSPLIT;
  
  data = [DVBT2_STATE.TDINT.UNUSED_DATA; DataIn.data]; % Prepend any data that wasn't processed last time
  h_est = [DVBT2_STATE.TDINT.UNUSED_HEST; DataIn.h_est]; % channel estimate
  
  outputData = zeros(1,NUM_FBLOCK*cellsPerFECBlock);
  outputH = zeros(1,NUM_FBLOCK*cellsPerFECBlock);
  
  FECBlocksPerSmallTIBlock = floor(NBLOCKS/NTI); % All these results are vectors - one element per I/L frame
  FECBlocksPerBigTIBlock = ceil(NBLOCKS/NTI);
  numBigTIBlocks = mod(NBLOCKS,NTI);
  numSmallTIBlocks = NTI-numBigTIBlocks;
  
  
  startIndex = 1;
  
  for n=0:NUM_INT_FRAMES-1	% n=Interleaving Frame index
    for s=0:NTI-1	% s=TI Block index
      if (s<numSmallTIBlocks(n+1))
        NFEC_TI = FECBlocksPerSmallTIBlock(n+1);
      else
        NFEC_TI = FECBlocksPerBigTIBlock(n+1);
      end
      numRows = NSPLIT * NFEC_TI;
      
      TIBlock = data(startIndex:startIndex+NFEC_TI*cellsPerFECBlock-1);
      
      interleavingTable = reshape(TIBlock, numRows, numCols);
      interleavingTable = interleavingTable.';
      outputData(startIndex:startIndex+NFEC_TI*cellsPerFECBlock-1) = interleavingTable(:);
      % interleave the h estimate for one TI-block
      TIBlock = h_est(startIndex:startIndex+NFEC_TI*cellsPerFECBlock-1);
      interleavingTable = reshape(TIBlock, numRows, numCols);
      interleavingTable = interleavingTable.';
      outputH(startIndex:startIndex+NFEC_TI*cellsPerFECBlock-1) = interleavingTable(:);
      startIndex = startIndex + NFEC_TI*cellsPerFECBlock;
    end
  end
  
  % Save any data that wasn't processed this time (e.g. not a whole
  % Interleaving Frame
  DVBT2_STATE.TDINT.UNUSED_DATA = data(startIndex:end);
  DVBT2_STATE.TDINT.UNUSED_HEST = h_est(startIndex:end);
  
  fprintf(FidLogFile,'\t\tTime de-interleaver: %d de-interleaved Interleaving Frames\n',... 
  NUM_INT_FRAMES);
  
else %NTI==0 => BYPASSED
  
  outputData = DataIn.data.' ;
  outputH    = DataIn.h_est.';
  fprintf(FidLogFile,'\t\tTime interleaver bypassed\n');

end

%------------------------------------------------------------------------------
% Output Formatting
%------------------------------------------------------------------------------
DataOut.data = outputData;
DataOut.h_est = outputH;
DataOut.sched = SCHED;
