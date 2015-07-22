function DataOut = t2_rx_dvbt2blcdint(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_tx_dvbt2blcdint SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------  

PLP = DVBT2.RX_PLP; % PLP to decode in the receiver

FECLEN_BITS = DVBT2.PLP(PLP).FECLEN; % FEC block size (16200 or 64800)
BITS_PER_CELL = DVBT2.STANDARD.PLP(PLP).MAP.V; % constellation order
CELLS_PER_FEC_BLOCK = FECLEN_BITS / BITS_PER_CELL;
NTI = DVBT2.PLP(PLP).NTI; % Number of TI blocks per Interleaving Frame
START_T2_FRAME = DVBT2.START_T2_FRAME;
NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES;
P_I = DVBT2.PLP(PLP).P_I;
I_JUMP = DVBT2.PLP(PLP).I_JUMP;
FIRST_FRAME_IDX = DVBT2.PLP(PLP).FIRST_FRAME_IDX;
PN_DEGREE = ceil(log2(CELLS_PER_FEC_BLOCK));
MAX_STATES = 2^PN_DEGREE;

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

SCHED = DataIn.sched;

lastFrameIdx = FIRST_FRAME_IDX + (P_I-1)*I_JUMP; % last T2 frame of first interleaving frame
START_INT_FRAME = ceil((START_T2_FRAME-lastFrameIdx)/(P_I * I_JUMP));
endIntFrame = floor((START_T2_FRAME+NUM_SIM_T2_FRAMES-1-lastFrameIdx)/(P_I * I_JUMP));
NUM_INT_FRAMES = endIntFrame - START_INT_FRAME + 1;
NBLOCKS = SCHED.NBLOCKS{PLP}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame
NUM_FBLOCK = sum(NBLOCKS); % Total number of FEC blocks to decode
FEC_BLOCKS_PER_INTERLEAVING_FRAME = NBLOCKS;

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
outputData.data = zeros(1, NUM_FBLOCK*CELLS_PER_FEC_BLOCK);
outputData.h_est = zeros(1, NUM_FBLOCK*CELLS_PER_FEC_BLOCK);
outputData.sched = SCHED;

if NTI==0    
    FECBlocksPerSmallTIBlock(1:NUM_INT_FRAMES) = 1;
    FECBlocksPerBigTIBlock(1:NUM_INT_FRAMES) = 1;
    numBigTIBlocks(1:NUM_INT_FRAMES) = 0;
    numSmallTIBlocks = NBLOCKS;
else
    FECBlocksPerSmallTIBlock = floor(NBLOCKS/NTI); % These are all vectors, one per Interleaving Frame
    FECBlocksPerBigTIBlock = ceil(NBLOCKS/NTI);
    numBigTIBlocks = mod(NBLOCKS,NTI);
    numSmallTIBlocks = NTI-numBigTIBlocks;
end

input_cell_index_start = 1;

k=0; % overall FEC block index
for n=0:NUM_INT_FRAMES-1
    
    for s=0:numSmallTIBlocks(n+1)+numBigTIBlocks(n+1)-1 % TI block index
      N=0; % reset shift at beginning of each TI-block
      if (s<numSmallTIBlocks(n+1))
		  NFEC_TI = FECBlocksPerSmallTIBlock(n+1);
	  else
		  NFEC_TI = FECBlocksPerBigTIBlock(n+1);
      end

  
      for r=0:NFEC_TI-1 % FEC block index within TI block
  
         shift = CELLS_PER_FEC_BLOCK;  % do this to force the 'while' to fire once
                                    % value will get overwritten anyway
         while shift >= CELLS_PER_FEC_BLOCK,
            N_binary = de2bi(N, PN_DEGREE);
            shift = bi2de(N_binary, 'left-msb');
            N = N + 1;
         end

         input_cell_index_end = input_cell_index_start + CELLS_PER_FEC_BLOCK - 1;
   
         % apply shift to get back
         permutations = mod(permutations_store+shift,CELLS_PER_FEC_BLOCK);
    


      
      % apply permutation other way round to get back
      outputData.data(input_cell_index_start:input_cell_index_end) = DataIn.data(input_cell_index_start+permutations(1:CELLS_PER_FEC_BLOCK));
      outputData.h_est(input_cell_index_start:input_cell_index_end) = DataIn.h_est(input_cell_index_start+permutations(1:CELLS_PER_FEC_BLOCK));
      k = k + 1;
      input_cell_index_start = input_cell_index_end+1;
      
    end
  end
end

%------------------------------------------------------------------------------
% Output formatting
%------------------------------------------------------------------------------
%d=outputData.data;
%sum(sum(d(:,:)))

DataOut = outputData;
