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
%* Description : T2_TX_DVBT2BLCINT DVBT2 Cell Interleaver.
%*               DOUT = T2_TX_DVBT2BLCINT(DVBT2, FID, DIN) interleaves the cells 
%*               defined as the data input following config params of DVBT2 structure.
%*               FID specifies the file identifier where any debug message is 
%*               sent. Includes the shift between each FEC block. Reset
%*               every PL frame.
%*               NOTE: This part of the baseline specification is still under discussion
%******************************************************************************

function DataOut = t2_tx_dvbt2blcint(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_tx_dvbt2blcint SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
NUM_PLPS   = DVBT2.NUM_PLPS; % Number of PLPs
SCHED = DataIn.sched;
%------------------------------------------------------------------------------
% PLP Loop
%------------------------------------------------------------------------------

for plp=1:NUM_PLPS

    %------------------------------------------------------------------------------
    % PLP-specific Parameters Definition
    %------------------------------------------------------------------------------
    FECLEN_BITS   = DVBT2.PLP(plp).FECLEN;            % The inner fec length
    BITS_PER_CELL = DVBT2.STANDARD.PLP(plp).MAP.V; % constellation order
    CELLS_PER_FEC_BLOCK = FECLEN_BITS / BITS_PER_CELL;

    START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME; % First Interleaving Frame to generate
    NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleving Frames to generate (may be zero)
    NBLOCKS = SCHED.NBLOCKS{plp}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame
    NUM_FBLOCK = sum(NBLOCKS); % Total number of FEC blocks to generate

    NTI = DVBT2.PLP(plp).NTI; % Number of TI blocks per Interleaving Frame

    PN_DEGREE = ceil(log2(CELLS_PER_FEC_BLOCK));
    MAX_STATES = 2^PN_DEGREE;

    %------------------------------------------------------------------------------
    % Procedure
    %------------------------------------------------------------------------------


    switch PN_DEGREE
      case 11
        logic = [ 1 4 ];
      case 12
        logic = [ 1 3 ];
      case 13
        logic = [ 1 2 5 7 ];
      case 14
        logic = [ 1 2 5 6 10 12 ];
      case 15
        logic = [ 1 2 3 13 ];
    end

    %calculate LFSR permutations
    lfsr = [];
    permutations_store = zeros(1, CELLS_PER_FEC_BLOCK);    % pre-allocate memory

    p = 1;
    for i = 0:MAX_STATES-1
      toggle = mod(i,2); 

      if (i == 0 || i == 1)
        lfsr = zeros(1, PN_DEGREE-1);
      elseif i == 2
        lfsr = [ 1 zeros(1, PN_DEGREE-2) ];
      else
        logic_result = multiple_input_xor(lfsr(logic)); % calculate before shift
        lfsr = [lfsr(2:PN_DEGREE-1) logic_result ]; % shift calculated bit into MSB
      end

      addressVector = [ lfsr toggle ];  
      addressDecimal = bi2de(addressVector);

      if (addressDecimal < CELLS_PER_FEC_BLOCK)
        permutations_store(p) = addressDecimal;
        p = p + 1;
      end
    end

    % allocate data memory, truncate input cells to a multiple of sub frames
    outputData = zeros(1, NUM_FBLOCK*CELLS_PER_FEC_BLOCK);
    k=0; % overall FEC block index
    for n=0:NUM_INT_FRAMES-1
        FEC_BLOCKS_PER_INTERLEAVING_FRAME = NBLOCKS(n+1);
        if NTI==0 % TI disabled - equivalent to one TI block per FEC block as far as the CINT is concerned
            FECBlocksPerSmallTIBlock = 1;
            FECBlocksPerBigTIBlock = 1;
            numSmallTIBlocks = FEC_BLOCKS_PER_INTERLEAVING_FRAME;
            numBigTIBlocks = 0;
        else            
            FECBlocksPerSmallTIBlock = floor(FEC_BLOCKS_PER_INTERLEAVING_FRAME/NTI);
            FECBlocksPerBigTIBlock = ceil(FEC_BLOCKS_PER_INTERLEAVING_FRAME/NTI);
            numBigTIBlocks = mod(FEC_BLOCKS_PER_INTERLEAVING_FRAME,NTI);
            numSmallTIBlocks = NTI-numBigTIBlocks;
        end

        for s=0:(numSmallTIBlocks + numBigTIBlocks)-1 % TI block index
          N=0; % reset shift at beginning of each TI-block
          if (s<numSmallTIBlocks)
              NFEC_TI = FECBlocksPerSmallTIBlock;
          else
              NFEC_TI = FECBlocksPerBigTIBlock;
          end

          for r=0:NFEC_TI-1 % FEC block index within TI block

             shift = CELLS_PER_FEC_BLOCK;  % do this to force the 'while' to fire once
                                        % value will get overwritten anyway
             while shift >= CELLS_PER_FEC_BLOCK,
                N_binary = de2bi(N, PN_DEGREE);
                shift = bi2de(N_binary, 'left-msb');
                N = N + 1;
             end

             input_cell_index_start = (k*CELLS_PER_FEC_BLOCK)+1;
             input_cell_index_end = input_cell_index_start + CELLS_PER_FEC_BLOCK - 1;

             permutations = mod(permutations_store+shift,CELLS_PER_FEC_BLOCK);
             outputData(input_cell_index_start+permutations(1:CELLS_PER_FEC_BLOCK)) = DataIn.data{plp}(input_cell_index_start:input_cell_index_end);

             k = k + 1;
         end
       end
    end

    % Write V&V test point
    write_vv_test_point(outputData, CELLS_PER_FEC_BLOCK, NBLOCKS, vv_fname('10',plp,DVBT2), 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)


    %------------------------------------------------------------------------------
    % Output formatting
    %------------------------------------------------------------------------------

    DataOut.data{plp} = outputData;
end

DataOut.sched = SCHED;
DataOut.l1 = DataIn.l1;