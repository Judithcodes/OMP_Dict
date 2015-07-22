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
%* Description : t2_t2_dvbt2blmadapt_schedule DVBT2 scheduling generator
%******************************************************************************
function SCHED = t2_tx_dvbt2blmadapt_schedule(DVBT2, SCHED)

NUM_PLPS = DVBT2.NUM_PLPS;

NUM_TOTAL_L1_BIAS_BALANCING_CELLS = DVBT2.STANDARD.NUM_TOTAL_L1_BIAS_BALANCING_CELLS;

T2FramesToSignal = DVBT2.STANDARD.END_T2_FRAME_SIG+1; % Number of T2 frames to signal (and therefore schedule) - could be more because of IBS


% Now generate and store sufficiently long vector indicating number of FEC blocks in each Interleaving Frame
for plp=1:NUM_PLPS
    TOTAL_INT_FRAMES_SIG = DVBT2.STANDARD.PLP(plp).TOTAL_INT_FRAMES_SIG;
    NBLOCKS = SCHED.NBLOCKS{plp};
    if length(NBLOCKS)==1 % If only one entry, all Interleaving Frames have the same number of blocks
        NBLOCKS = repmat(NBLOCKS,1,TOTAL_INT_FRAMES_SIG); 
    elseif length(NBLOCKS)<TOTAL_INT_FRAMES_SIG
        NBLOCKS(end+1:TOTAL_INT_FRAMES_SIG) = NBLOCKS(1:TOTAL_INT_FRAMES_SIG-length(NBLOCKS)); %If not specified, assume that dynamic pattern will repeat
    end
    SCHED.NBLOCKS{plp} = NBLOCKS(1:TOTAL_INT_FRAMES_SIG); %Store number of blocks for each Interleaving Frame
end

% Scheduling

% Sort PLPs into PLP types (0, 1 and 2 = common, type 1 and type 2)
PLPTypeOrder = {[] [] []};

for plp=1:NUM_PLPS
    PLPTypeOrder{DVBT2.PLP(plp).PLP_TYPE + 1} = [PLPTypeOrder{DVBT2.PLP(plp).PLP_TYPE + 1} plp];
end

PLPOrder = [PLPTypeOrder{1} PLPTypeOrder{2} PLPTypeOrder{3}]; % List of all PLPs in order

sliceLengths = zeros(NUM_PLPS,T2FramesToSignal);
subsliceLengths=zeros(NUM_PLPS,T2FramesToSignal);
subsliceIntervals=zeros(1,T2FramesToSignal);

for j=1:length(PLPOrder)
    plp = PLPOrder(j);
    P_I = DVBT2.PLP(plp).P_I;
    I_JUMP = DVBT2.PLP(plp).I_JUMP;
    FIRST_FRAME_IDX = DVBT2.PLP(plp).FIRST_FRAME_IDX;
    
    NCells = DVBT2.PLP(plp).FECLEN / DVBT2.STANDARD.PLP(plp).MAP.V; % Cells per FEC block
    NBLOCKS = SCHED.NBLOCKS{plp}; % vector of number of FEC blocks in each Interleaving Frame
    
    PLPCellsPerInterleavingFrame = NBLOCKS * NCells; % Cells in each interleaving frame for the PLP (row, one col per I/L frame)
    PLPCellsPerMappedFrame = PLPCellsPerInterleavingFrame / P_I; % Cells in each T2 frame to which this PLP is mapped
    PLPCellsPerMappedFrame = repmat(PLPCellsPerMappedFrame, P_I, 1); % Repeat for each T2-frame to which PLP mapped
    PLPCellsPerMappedFrame = reshape(PLPCellsPerMappedFrame,1,[]); % Reshape to row vector
    PLPCellsPerT2Frame = zeros(1, T2FramesToSignal); %row: one column per T2-frame 
    PLPMappedFrameIndices = FIRST_FRAME_IDX+1 : I_JUMP : T2FramesToSignal;
    PLPCellsPerT2Frame(PLPMappedFrameIndices) = PLPCellsPerMappedFrame(1:length(PLPMappedFrameIndices));
    sliceLengths(j, :) = PLPCellsPerT2Frame;

    if DVBT2.PLP(plp).PLP_TYPE<2
        subsliceLengths(j, :) = PLPCellsPerT2Frame;
    else % Type 2
        subsliceLengths(j,:) = PLPCellsPerT2Frame / DVBT2.NUM_SUBSLICES;
        subsliceIntervals = subsliceIntervals + subsliceLengths(j,:);
    end
end

if DVBT2.PSEUDO_FIXED_FRAME_STRUCTURE
    %Check Common and Type1 PLPs fit
    numCommonPLPs=length(PLPTypeOrder{1});
    numType1PLPs=length(PLPTypeOrder{2});
    totalCommonCells=sum(sliceLengths(1:numCommonPLPs, :),1); % total cells for each T2-frame per column
    totalType1Cells=sum(sliceLengths(numCommonPLPs+1:numCommonPLPs+numType1PLPs, :),1);
    assert(all(totalCommonCells <= DVBT2.MAX_COMMON_CELLS_PER_T2_FRAME), 'Too many common cells for allowed space')
    assert(all(totalType1Cells <= DVBT2.MAX_TYPE1_CELLS_PER_T2_FRAME), 'Too many Type 1 cells for allowed space')

    %Reassign sub-slices to fill Type2 space
    requiredSubsliceInterval = DVBT2.MAX_TYPE2_CELLS_PER_T2_FRAME / DVBT2.NUM_SUBSLICES;
    assert (all(subsliceIntervals <= requiredSubsliceInterval), 'Too many Type 2 cells for allowed space')
    if isempty(DVBT2.SUB_SLICE_INTERVAL)
        subsliceIntervals = repmat(requiredSubsliceInterval, 1, T2FramesToSignal); %Reassign subsliceIntervals to fill allowed space
    else %subsliceIntervals will be assigned later...
        assert (requiredSubsliceInterval == DVBT2.SUB_SLICE_INTERVAL, 'Calculated and defined values of SUB_SLICE_INTERVAL are inconsistent')
    end
end

if isempty(DVBT2.PLP(1).PLP_START) % calculate start addresses automatically
    startAddresses = cumsum(subsliceLengths);
    startAddresses = [zeros(1,T2FramesToSignal); startAddresses]; 
    startAddresses = startAddresses + NUM_TOTAL_L1_BIAS_BALANCING_CELLS; % first PLP starts after the BBCs
    startAddresses = startAddresses(1:NUM_PLPS,:); %Remove redundant last line

    auxStartAddresses = sum (sliceLengths, 1) + NUM_TOTAL_L1_BIAS_BALANCING_CELLS;

    if DVBT2.PSEUDO_FIXED_FRAME_STRUCTURE
        if T2FramesToSignal > 1
            assert (sum(startAddresses (1,2:end) ~= startAddresses(1,1)) == 0, 'Error: Start address of 1st PLP varies between frames')
        end
        type1Start = startAddresses(1,1) + DVBT2.MAX_COMMON_CELLS_PER_T2_FRAME;
        if ~isempty (PLPTypeOrder{2}) %There are some Type 1 PLPs
            plp = PLPTypeOrder{2}(1); %First type 1 PLP
            shifts = type1Start - startAddresses(PLPOrder==plp, :);
            assert(min(shifts) >= 0, 'Error: Number of Common cells > MAX_COMMON_CELLS_PER_T2_FRAME');
            for j = 1:length(PLPTypeOrder{2})
                plp = PLPTypeOrder{2}(j);
                startAddresses(PLPOrder==plp, :) = startAddresses(PLPOrder==plp, :) + shifts;
            end
        end
        type2Start = type1Start + DVBT2.MAX_TYPE1_CELLS_PER_T2_FRAME;
        if ~isempty (PLPTypeOrder{3}) %There are some Type 2 PLPs
            plp = PLPTypeOrder{3}(1); %First type 2 PLP
            shifts = type2Start - startAddresses(PLPOrder==plp, :);
            assert(min(shifts) >= 0, 'Error: Number of Type 1 cells > MAX_TYPE1_CELLS_PER_T2_FRAME');
            for j = 1:length(PLPTypeOrder{3})
                plp = PLPTypeOrder{3}(j);
                startAddresses(PLPOrder==plp, :) = startAddresses(PLPOrder==plp, :) + shifts;
            end
        end
        auxStart = type2Start + DVBT2.MAX_TYPE2_CELLS_PER_T2_FRAME;
        assert (sum(auxStartAddresses > auxStart) == 0, 'Error: Number of Type 2 cells > MAX_TYPE2_CELLS_PER_T2_FRAME');
        auxStartAddresses = repmat (auxStart, 1, T2FramesToSignal);
        type2Starts = repmat(type2Start, 1, T2FramesToSignal);
    else
        if ~isempty (PLPTypeOrder{3}) %There are some Type 2 PLPs
            type2Starts = startAddresses(length(PLPTypeOrder{1}) + length(PLPTypeOrder{2}) + 1, :);
        else
            type2Starts = zeros(1, T2FramesToSignal);
        end
            
    end    
else % Take from the DVBT2 structure (e.g. from T2-MI)
    startAddresses = zeros(NUM_PLPS,T2FramesToSignal);
    for j=1:length(PLPOrder)
        plp = PLPOrder(j);
        P_I = DVBT2.PLP(plp).P_I;
        FIRST_FRAME_IDX = DVBT2.PLP(plp).FIRST_FRAME_IDX;
        I_JUMP = DVBT2.PLP(plp).I_JUMP;
        ILFramesToSignal = ceil((T2FramesToSignal-FIRST_FRAME_IDX)/(P_I * I_JUMP));
  
        PLP_START = DVBT2.PLP(plp).PLP_START;
        if length(PLP_START)==1 % If only one entry, all Interleaving Frames have the same start address
            PLP_START = repmat(PLP_START,1,ILFramesToSignal);                 
        elseif length(PLP_START)<ILFramesToSignal
            PLP_START(end+1:ILFramesToSignal) = PLP_START(1:ILFramesToSignal-length(PLP_START)); %If not specified, assume that dynamic pattern will repeat
        end
        PLPMappedFrameIndices = FIRST_FRAME_IDX+1 : I_JUMP : T2FramesToSignal;
        startAddresses(j,PLPMappedFrameIndices) = PLP_START(1:length(PLPMappedFrameIndices));
    end
    
end

if ~isempty(DVBT2.SUB_SLICE_INTERVAL) % Use the sub-slice intervals from the DVBT2 structure if specified (e.g. from T2-MI)
    subsliceIntervals = DVBT2.SUB_SLICE_INTERVAL;
    if length(subsliceIntervals)<T2FramesToSignal
        subsliceIntervals(end+1:T2FramesToSignal) = subsliceIntervals(1:T2FramesToSignal-length(subsliceIntervals));
    end
end

if isfield(DVBT2, 'TYPE2_START') && ~isempty(DVBT2.TYPE2_START) % use type-2 start from DVBT2 structure (i.e. T2-MI)
    type2Starts = DVBT2.TYPE2_START;
end

% Aux streams
for aux = 1:DVBT2.NUM_AUX
    switch DVBT2.AUX(aux).AUX_STREAM_TYPE
        case 0  % TX-SIG Aux Stream
            N = 2^DVBT2.AUX(aux).Q;
            P = DVBT2.AUX(aux).P;            
            
            SCHED.AUX(aux).START = auxStartAddresses; %TODO: in MISO mode, go to the start of a new symbol
            auxLen = 1 + 4*(P+1)*N;
            SCHED.AUX(aux).LENGTH = repmat(auxLen,1,T2FramesToSignal); % length is the same in every T2-frame
            auxStartAddresses = auxStartAddresses + auxLen;
                        
        otherwise
            SCHED.AUX(aux).START = auxStartAddresses; 
            SCHED.AUX(aux).LENGTH = zeros(1,T2FramesToSignal); % dummy aux stream as used in the ALG-TST test case - no physical manifestation in the frame
    end            
end

% Reorder the PLPs

SCHED.sliceLengths(PLPOrder,:) = sliceLengths;
SCHED.subsliceLengths(PLPOrder,:) = subsliceLengths;
SCHED.startAddresses(PLPOrder,:) = startAddresses;
SCHED.subsliceIntervals = subsliceIntervals;
SCHED.type2Starts = type2Starts;

end
