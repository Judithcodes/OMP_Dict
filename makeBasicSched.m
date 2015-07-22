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
%* Description : makeBasicSched DVBT2 scheduling from input L1 data
%******************************************************************************
function SCHED = makeBasicSched (DVBT2, L1Data)

nPLP = L1Data.decValues (1, strcmp('NUM_PLP',L1Data.fieldNames)~=0);

% STATE INITIALISATION
global DVBT2_STATE;

if (DVBT2.START_T2_FRAME==0)
    DVBT2_STATE.RX.L1DECODE.MAKEBASICSCHED.SCHED.startAddresses = [];
    DVBT2_STATE.RX.L1DECODE.MAKEBASICSCHED.SCHED.sliceLengths = [];
    DVBT2_STATE.RX.L1DECODE.MAKEBASICSCHED.SCHED.subsliceLengths = [];
    DVBT2_STATE.RX.L1DECODE.MAKEBASICSCHED.SCHED.subsliceIntervals = [];
    DVBT2_STATE.RX.L1DECODE.MAKEBASICSCHED.SCHED.NBLOCKS=cell(1,nPLP);
end

% RETRIEVE STATE
SCHED= DVBT2_STATE.RX.L1DECODE.MAKEBASICSCHED.SCHED;


T2FramesToSignal = DVBT2.NUM_SIM_T2_FRAMES;
firstT2Frame = DVBT2.START_T2_FRAME;

% L1Data has 1 row for each T2-frame and the L1-fields are in the columns

NBLOCKS = L1Data.decValues (:, strcmp('PLP_NUM_BLOCKS',L1Data.fieldNames)~=0)';
SCHED.subsliceIntervals = [SCHED.subsliceIntervals L1Data.decValues(:, strcmp('SUB_SLICE_INTERVAL',L1Data.fieldNames)~=0)'];
startAddressesSig = L1Data.decValues (:, strcmp('PLP_START',L1Data.fieldNames)~=0)';


plpTypes = L1Data.decValues (1, strcmp('PLP_TYPE',L1Data.fieldNames)~=0);
plpIDs = L1Data.decValues (1, strcmp('PLP_ID',L1Data.fieldNames)~=0);
plpIDs = plpIDs (1:nPLP);

sliceLengths = zeros(nPLP,T2FramesToSignal);
subsliceLengths=zeros(nPLP,T2FramesToSignal);
subsliceIntervals=zeros(1,T2FramesToSignal);
startAddresses=zeros(nPLP,T2FramesToSignal);

for plp=1:nPLP
    plpSigIndex = find(plpIDs==DVBT2.PLP(plp).PLP_ID,1,'first'); % Index in the signalling loop
    P_I = DVBT2.PLP(plp).P_I;
    I_JUMP = DVBT2.PLP(plp).I_JUMP;
    FIRST_FRAME_IDX = DVBT2.PLP(plp).FIRST_FRAME_IDX;
    
    NCells = DVBT2.PLP(plp).FECLEN / DVBT2.STANDARD.PLP(plp).MAP.V; % Cells per FEC block
    
    % Get vector of number of FEC blocks in each Frame - assumes L1 signalling
    % is present on every frame, not just those frames which PLP is present

    %Need to edit vector down to 1 per interleaving frame only
    myFrames = find(mod((firstT2Frame:firstT2Frame+T2FramesToSignal-1)-FIRST_FRAME_IDX, I_JUMP)==0);
    plpNBLOCKS = NBLOCKS(plpSigIndex,myFrames);

    SCHED.NBLOCKS{plp} = [SCHED.NBLOCKS{plp} plpNBLOCKS];
    
    PLPCellsPerInterleavingFrame = plpNBLOCKS * NCells; % Cells in each interleaving frame for the PLP (row, one col per I/L frame)
    PLPCellsPerMappedFrame = PLPCellsPerInterleavingFrame / P_I; % Cells in each T2 frame to which this PLP is mapped
    PLPCellsPerMappedFrame = repmat(PLPCellsPerMappedFrame, P_I, 1); % Repeat for each T2-frame to which PLP mapped
    PLPCellsPerMappedFrame = reshape(PLPCellsPerMappedFrame,1,[]); % Reshape to row vector
    PLPCellsPerT2Frame = zeros(1, T2FramesToSignal); %row: one column per T2-frame 
    PLPCellsPerT2Frame(myFrames) = PLPCellsPerMappedFrame;    
    sliceLengths(plp, :) = PLPCellsPerT2Frame;

    if DVBT2.PLP(plp).PLP_TYPE<2
        subsliceLengths(plp, :) = PLPCellsPerT2Frame;
    else % Type 2
        subsliceLengths(plp,:) = PLPCellsPerT2Frame / DVBT2.NUM_SUBSLICES;
        subsliceIntervals = subsliceIntervals + subsliceLengths(plp,:);
    end
    
    startAddresses(plp, :)=startAddressesSig(plpSigIndex,:);
    
end

SCHED.startAddresses = [SCHED.startAddresses startAddresses];
SCHED.sliceLengths = [SCHED.sliceLengths sliceLengths];
SCHED.subsliceLengths = [SCHED.subsliceLengths subsliceLengths];

% STORE STATE
DVBT2_STATE.RX.L1DECODE.MAKEBASICSCHED.SCHED = SCHED;
