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
%* Description : T2_TX_DVBT2BLTINT DVBT2 Time Interleaver.
%*               DOUT = T2_TX_DVBT2BLTINT(DVBT2, FID, DIN) interleaves the data 
%*               following the configuration parameters of DVBT2 structure.
%*               FID specifies the file identifier where any debug message is 
%*               sent.
%*               This implementation assumes single RF, single PLP mode so the interleaver
%*               depth has a constant value NFEC (FEC blocks).
%*               NOTE: This part of the baseline specification is still under discussion
%******************************************************************************

function DataOut = t2_tx_dvbt2bltint(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_tx_dvbt2bltint SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
NUM_PLPS   = DVBT2.NUM_PLPS; % Number of PLPs
NSPLIT = 5; % Number of columns occupied by each FEC block. 
SCHED = DataIn.sched;
%------------------------------------------------------------------------------
% PLP Loop
%------------------------------------------------------------------------------

for plp=1:NUM_PLPS

    %------------------------------------------------------------------------------
    % PLP-specific Parameters Definition
    %------------------------------------------------------------------------------
    FECLEN   = DVBT2.PLP(plp).FECLEN;            % The inner fec length
    START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME; % First Interleaving Frame to generate
    NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleaving Frames to generate (may be zero)
    NBLOCKS = SCHED.NBLOCKS{plp}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame
    NUM_FBLOCK = sum(NBLOCKS); % Total number of FEC blocks to generate
    BITS_PER_CELL = DVBT2.STANDARD.PLP(plp).MAP.V; % constellation order
    NTI = DVBT2.PLP(plp).NTI; % Number of TI blocks per Interleaving Frame

    %------------------------------------------------------------------------------
    % Procedure
    %------------------------------------------------------------------------------

    cellsPerFECBlock = FECLEN / BITS_PER_CELL; 

    if NTI>0  % if TI is enabled

      outputData = [];  % andrew - outputData could never get smaller if fewer cells for next PLP!
      numRows = cellsPerFECBlock / NSPLIT;
      data = DataIn.data{plp}(1:NUM_FBLOCK*cellsPerFECBlock); % trim to whole number of sub-frames

      FECBlocksPerSmallTIBlock = floor(NBLOCKS/NTI); % These are all vectors, one element per I/L frame
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
            numCols = NSPLIT * NFEC_TI;

            TIBlock = data(startIndex:startIndex+NFEC_TI*cellsPerFECBlock-1);
            interleavingTable = reshape(TIBlock, numRows, numCols);
            interleavingTable = interleavingTable.';

            outputData(startIndex:startIndex+NFEC_TI*cellsPerFECBlock-1) = interleavingTable(:);
            startIndex = startIndex + NFEC_TI*cellsPerFECBlock;
        end
      end

      fprintf(FidLogFile,'\t\tTime interleaver: %d interleaved Interleaving Frames\n',... 
              NUM_INT_FRAMES);
    else % NTI==0 => BYPASSED

      outputData = DataIn.data{plp};
      fprintf(FidLogFile,'\t\tTime interleaver bypassed\n');

    end

    % Write V&V test point
    write_vv_test_point(outputData, NBLOCKS*cellsPerFECBlock, 0, vv_fname('11',plp,DVBT2), 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)

    %------------------------------------------------------------------------------
    % Output formatting
    %------------------------------------------------------------------------------
    DataOut.data{plp} = outputData;
end

DataOut.sched = SCHED;
DataOut.l1 = DataIn.l1;