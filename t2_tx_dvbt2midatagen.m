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
%* Description : T2_TX_DVBT2MIDATAGEN DVB TS reader.
%*               DOUT = T2_TX_DVBT2MIDATAGEN(DVBT2) reads from a 
%*               T2MI stream file. 
%*               DOUT = T2_TX_DVBT2BLTSDATAGEN(DVBT2, FID) specifies the file 
%*               identifier in FID where any debug message is sent.
%******************************************************************************

function DataOut = t2_tx_dvbt2midatagen(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_tx_dvbt2midatagen SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------

NUM_PLPS = DVBT2.NUM_PLPS;
T2MI_FILENAME = DVBT2.SIM.INPUT_T2MI_FILENAME;
FIRST_SIG_T2_FRAME = DVBT2.FIRST_SIG_T2_FRAME; % First signalled T2 frame index - currently we assume this is zero
FIRST_SIG_SUPERFRAME = DVBT2.FIRST_SIG_SUPERFRAME; % First signalled superframe index
START_T2_FRAME = DVBT2.START_T2_FRAME;
NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES; % Frames to generate
N_T2 = DVBT2.N_T2; % Superframe length


%------------------------------------------------------------------------------
% State initialisation
%------------------------------------------------------------------------------
global DVBT2_STATE;
if DVBT2.START_T2_FRAME == 0
  DVBT2_STATE.DATAGEN.T2MI_FILE_OFFSET = 0;
  DVBT2_STATE.DATAGEN.T2MI_STATE = [];
  DVBT2_STATE.DATAGEN.T2MI_CURRENT_BLOCK_IDX(1:NUM_PLPS) = -1;
  DVBT2_STATE.DATAGEN.T2MI_CURRENT_FRAME_IDX(1:NUM_PLPS) = -1;
  DVBT2_STATE.DATAGEN.T2MI_CURRENT_SUPERFRAME_IDX(1:NUM_PLPS) = -1;
  DVBT2_STATE.DATAGEN.T2MI_UNUSED_DATA_REL_FRAME = {};
  for plp=1:NUM_PLPS
      DVBT2_STATE.DATAGEN.T2MI_UNUSED_DATA{plp} = [];
      DVBT2_STATE.DATAGEN.T2MI_UNUSED_DATA_REL_FRAME{plp} = [];
  end
  DVBT2_STATE.DATAGEN.T2MI_UNUSED_L1.pre = [];
  DVBT2_STATE.DATAGEN.T2MI_UNUSED_L1.conf = [];
  DVBT2_STATE.DATAGEN.T2MI_UNUSED_L1.dyn = [];
  DVBT2_STATE.DATAGEN.T2MI_UNUSED_L1.ext = [];
  DVBT2_STATE.DATAGEN.T2MI_UNUSED_L1_REL_FRAME = [];
end

currentBlockIdx = DVBT2_STATE.DATAGEN.T2MI_CURRENT_BLOCK_IDX;
currentFrameIdx = DVBT2_STATE.DATAGEN.T2MI_CURRENT_FRAME_IDX;
currentSuperframeIdx = DVBT2_STATE.DATAGEN.T2MI_CURRENT_SUPERFRAME_IDX;


% assert(FIRST_SIG_T2_FRAME==0);
blocksPerT2Frame = zeros(NUM_PLPS, NUM_SIM_T2_FRAMES); % table of number of blocks associated with each T2 frame for each PLP
t2FrameStartPositions = zeros(NUM_PLPS, NUM_SIM_T2_FRAMES); % table of where each T2 frame starts in the output vector
T2FramesIdx = mod(START_T2_FRAME:START_T2_FRAME+NUM_SIM_T2_FRAMES-1, N_T2);

plpIDs = zeros(1,NUM_PLPS);

l1FutureNeeded = false; % TODO: L1 repetition

% Do the scheduling. NBLOCKS was populated during the initial pass through
% the T2MI file. In the future this initial pass could perhaps be
% eliminated and the NBLOCKS created here. 
for plp=1:NUM_PLPS
    SCHED.NBLOCKS{plp} = DVBT2.PLP(plp).NBLOCKS;
end

SCHED = t2_tx_dvbt2blmadapt_schedule(DVBT2, SCHED);

unusedL1 = DVBT2_STATE.DATAGEN.T2MI_UNUSED_L1;
unusedL1RelFrame = DVBT2_STATE.DATAGEN.T2MI_UNUSED_L1_REL_FRAME;

for plp=1:NUM_PLPS
    plpIDs(plp) = DVBT2.PLP(plp).PLP_ID; % Make a vector of PLP_IDs for converting PLP_ID into PLP index
    
    % Work out how much stuff to collect and where to put it in the output
    % array
    P_I = DVBT2.PLP(plp).P_I;
    I_JUMP = DVBT2.PLP(plp).I_JUMP;
    FIRST_FRAME_IDX = DVBT2.PLP(plp).FIRST_FRAME_IDX;
    K_BCH = DVBT2.STANDARD.PLP(plp).OCOD.K_BCH;   % BCH unencoded block length
    START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME; % First Interleaving Frame to generate
    NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleaving Frames to generate (may be zero)
    NBLOCKS{plp} = SCHED.NBLOCKS{plp}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame
    blocksPerT2Frame(plp, mod(T2FramesIdx-FIRST_FRAME_IDX, P_I*I_JUMP)==0) = NBLOCKS{plp}; % associate them with the first T2 frame they are mapped to
    t2FrameStartPositions(plp,:) = K_BCH/8 * [0 cumsum(blocksPerT2Frame(plp,1:end-1))] + 1;

    DataOut.data{plp} = zeros(sum(NBLOCKS{plp})*K_BCH/8,1); % Prepare the output vector
    unusedData{plp} = DVBT2_STATE.DATAGEN.T2MI_UNUSED_DATA{plp};
    unusedDataRelFrame{plp} = DVBT2_STATE.DATAGEN.T2MI_UNUSED_DATA_REL_FRAME{plp};
    unusedDataToUse = reshape(unusedData{plp}(unusedDataRelFrame{plp}<NUM_SIM_T2_FRAMES,:)',[],1);
    DataOut.data{plp}(1:numel(unusedDataToUse)) = unusedDataToUse; % insert any blocks already received
    unusedData{plp} = unusedData{plp}(unusedDataRelFrame{plp}>=NUM_SIM_T2_FRAMES,:); % Data for future interleaving frames which is stored up whilst waiting for the L1-future or for MFI
    unusedDataRelFrame{plp} = unusedDataRelFrame{plp}(unusedDataRelFrame{plp}>=NUM_SIM_T2_FRAMES);
    
    if DVBT2.PLP(plp).IN_BAND_A_FLAG
        l1FutureNeeded = true;
    end
end

DataOut.l1.pre = unusedL1.pre(unusedL1RelFrame<NUM_SIM_T2_FRAMES,:);
DataOut.l1.conf = unusedL1.conf(unusedL1RelFrame<NUM_SIM_T2_FRAMES,:);
DataOut.l1.dyn = unusedL1.dyn(unusedL1RelFrame<NUM_SIM_T2_FRAMES,:);
DataOut.l1.ext = unusedL1.ext(unusedL1RelFrame<NUM_SIM_T2_FRAMES,:);
DataOut.l1.dyn_next = [];

unusedL1.pre = unusedL1.pre(unusedL1RelFrame>=NUM_SIM_T2_FRAMES);
unusedL1.conf = unusedL1.conf(unusedL1RelFrame>=NUM_SIM_T2_FRAMES);
unusedL1.dyn = unusedL1.dyn(unusedL1RelFrame>=NUM_SIM_T2_FRAMES);
unusedL1.ext = unusedL1.ext(unusedL1RelFrame>=NUM_SIM_T2_FRAMES);
unusedL1RelFrame = unusedL1RelFrame(unusedL1RelFrame>=NUM_SIM_T2_FRAMES);

fidT2MI = fopen(T2MI_FILENAME, 'r');
if strcmp(T2MI_FILENAME(end-3:end),'t2mi')
    isDataPiping = false;
    PID = 0;
else
    isDataPiping = true;
    PID = DVBT2.SIM.INPUT_T2MI_PID;
end
    
fseek(fidT2MI, DVBT2_STATE.DATAGEN.T2MI_FILE_OFFSET, 'bof');

T2MIState = DVBT2_STATE.DATAGEN.T2MI_STATE;

start_frame_idx = mod(START_T2_FRAME, N_T2);
start_superframe_idx = mod(FIRST_SIG_SUPERFRAME + floor(START_T2_FRAME / N_T2), 16); % superframe_idx wraps at 16

end_frame_idx = mod(START_T2_FRAME+NUM_SIM_T2_FRAMES-1, N_T2);
end_superframe_idx = mod(FIRST_SIG_SUPERFRAME + floor((START_T2_FRAME+NUM_SIM_T2_FRAMES-1) / N_T2), 16); % superframe_idx wraps at 16

done = 0;

while ~done 
    [T2MIPacket T2MIState] = get_t2mi_packet(fidT2MI, T2MIState, PID, isDataPiping);
    if feof(fidT2MI)
        break;
    end
    
    if T2MIPacket.packet_type == hex2dec('00') % Baseband Frame packet
        packetFrameNum = diffFrameIdx(T2MIPacket.superframe_idx, T2MIPacket.frame_idx, start_superframe_idx, start_frame_idx, N_T2);
        if (packetFrameNum >= 0) % Discard any from a previous frame (startup issue?)
            plpID = T2MIPacket.plp_id;
            plp = find(plpIDs == plpID, 1, 'first');
            K_BCH = DVBT2.STANDARD.PLP(plp).OCOD.K_BCH;   % BCH unencoded block length
            fprintf(FidLogFile, 'frame_idx: %d  plp: %d current %d\n', T2MIPacket.frame_idx, plp, currentFrameIdx(plp));
            if T2MIPacket.intl_frame_start
                % assert(currentBlockIdx(plp)==-1 || currentBlockIdx(plp)==NBLOCKS{plp}(packetFrameNum-DVBT2.PLP(plp).P_I * DVBT2.PLP(plp).I_JUMP+1));
                fprintf(FidLogFile, 'Start of Interleaving Frame (%d,%d) for PLP %d\n', T2MIPacket.superframe_idx,T2MIPacket.frame_idx, plp)
                currentSuperframeIdx(plp) = T2MIPacket.superframe_idx;
                currentFrameIdx(plp) = T2MIPacket.frame_idx;
                currentBlockIdx(plp) = 0;
            elseif currentBlockIdx(plp) ~= -1
                assert(currentFrameIdx(plp) == T2MIPacket.frame_idx);
                assert(currentSuperframeIdx(plp) == T2MIPacket.superframe_idx);                
            end
            
            if (currentBlockIdx(plp) ~= -1)
                fprintf(FidLogFile, 'Got Block %d of T2 frame %d for plp %d\n',currentBlockIdx(plp),packetFrameNum+START_T2_FRAME,plp);
                if packetFrameNum < NUM_SIM_T2_FRAMES
                    pos = t2FrameStartPositions(plp,packetFrameNum+1) + currentBlockIdx(plp)*K_BCH/8;
                    DataOut.data{plp}(pos:pos+K_BCH/8-1) = T2MIPacket.bbframe';
                else
                    % Not needed for this run - keep it for next time (e.g.
                    % for a future frame whilst awaiting the L1-future, or
                    % for a multi-frame interleaved PLP
                    unusedData{plp} = [unusedData{plp} ; T2MIPacket.bbframe];
                    unusedDataRelFrame{plp} = [unusedDataRelFrame{plp}; packetFrameNum];
                end
                currentBlockIdx(plp)=currentBlockIdx(plp)+1;
            end
        else
            fprintf(FidLogFile, 'Discarding packet for (%d,%d), packetFrameNum=%d\n',T2MIPacket.superframe_idx, T2MIPacket.frame_idx,packetFrameNum);
        end
        
    elseif T2MIPacket.packet_type == hex2dec('10') % L1-current packet
        packetFrameNum = diffFrameIdx(T2MIPacket.superframe_idx, T2MIPacket.frame_idx, start_superframe_idx, start_frame_idx, N_T2);

        if packetFrameNum < NUM_SIM_T2_FRAMES
            % Store pre and post for L1 block to use
            DataOut.l1.pre = [DataOut.l1.pre; T2MIPacket.l1pre];
            DataOut.l1.conf = [DataOut.l1.conf; T2MIPacket.l1conf];
            DataOut.l1.dyn = [DataOut.l1.dyn; T2MIPacket.l1dyn];
            DataOut.l1.ext = [DataOut.l1.ext; T2MIPacket.l1ext];
        else
            % Not needed for this run - keep it for next time (e.g.
            % L1-current??? for a future frame whilst awaiting the
            % L1-future (is this the right ordering?)
            unusedL1.pre = [unusedL1.pre; T2MIPacket.l1pre];
            unusedL1.conf = [unusedL1.conf; T2MIPacket.l1conf];
            unusedL1.dyn = [unusedL1.dyn; T2MIPacket.l1dyn];
            unusedL1.ext = [unusedL1.ext; T2MIPacket.l1ext];
            unusedL1RelFrame = [unusedL1RelFrame; packetFrameNum];
        end

        
        if T2MIPacket.superframe_idx == end_superframe_idx && T2MIPacket.frame_idx == end_frame_idx && ~l1FutureNeeded
            done = 1; % receiving the L1-current means that there are no more BBFrames for a given T2-frame (there might be an L1-future)
        end

    elseif T2MIPacket.packet_type == hex2dec('11') % L1-future packet
        packetFrameNum = diffFrameIdx(T2MIPacket.superframe_idx, T2MIPacket.frame_idx, start_superframe_idx, start_frame_idx, N_T2);

        if packetFrameNum>=0 
            % extract the "L1-next"
            DataOut.l1.dyn_next = [DataOut.l1.dyn_next T2MIPacket.l1dyn_next];
            % extract the IBS and insert it into the correct BBFrame        
            for i=1:T2MIPacket.num_inband
                plpID = T2MIPacket.plp_id(i);
                plp = find(plpIDs == plpID, 1, 'first'); % Get the PLP index from the PLP_ID
                K_BCH = DVBT2.STANDARD.PLP(plp).OCOD.K_BCH;   % BCH unencoded block length                
                % Find the first baseband frame of the relevant interleaving frame
                pos = t2FrameStartPositions(plp,packetFrameNum+1);
                bbframe = DataOut.data{plp}(pos:pos+K_BCH/8-1);
                bbframe = reshape(de2bi(bbframe, 8, 'left-msb')', [],1); % convert to bits
                % Read the header to get DFL
                DFL = bi2de(bbframe(33:48)', 'left-msb');
                bbframe(DFL+1+80:DFL+80+T2MIPacket.inband_len(i)) = T2MIPacket.inband{i}; % Insert the inband signalling
                bbframe = reshape(bi2de(reshape(bbframe,8,[])','left-msb'),[],1); % Convert back to bytes
                DataOut.data{plp}(pos:pos+K_BCH/8-1) = bbframe; % Put back in output array
            end
        end
        
        if T2MIPacket.superframe_idx == end_superframe_idx && T2MIPacket.frame_idx == end_frame_idx
            done = 1; % receiving the L1-future means that there are no more BBFrames for a given T2-frame
        end


    end
end

% Store state for next time
DVBT2_STATE.DATAGEN.T2MI_FILE_OFFSET = ftell(fidT2MI);
DVBT2_STATE.DATAGEN.T2MI_STATE = T2MIState;
DVBT2_STATE.DATAGEN.T2MI_CURRENT_BLOCK_IDX = currentBlockIdx;
DVBT2_STATE.DATAGEN.T2MI_CURRENT_FRAME_IDX = currentFrameIdx;
DVBT2_STATE.DATAGEN.T2MI_CURRENT_SUPERFRAME_IDX = currentSuperframeIdx;

for plp=1:NUM_PLPS
    DVBT2_STATE.DATAGEN.T2MI_UNUSED_DATA{plp} = unusedData{plp};
    DVBT2_STATE.DATAGEN.T2MI_UNUSED_DATA_REL_FRAME{plp} = unusedDataRelFrame{plp} - NUM_SIM_T2_FRAMES;
end

DVBT2_STATE.DATAGEN.T2MI_UNUSED_L1 = unusedL1;
DVBT2_STATE.DATAGEN.T2MI_UNUSED_L1_REL_FRAME = unusedL1RelFrame - NUM_SIM_T2_FRAMES;

fclose(fidT2MI);


for plp=1:NUM_PLPS
  K_BCH = DVBT2.STANDARD.PLP(plp).OCOD.K_BCH;
  assert(isempty(find(DataOut.data{plp}(1:K_BCH/8:end)==0,1,'first')));
  write_vv_test_point(DataOut.data{plp}, DVBT2.STANDARD.PLP(plp).OCOD.K_BCH/8, NBLOCKS{plp}, vv_fname('03', plp, DVBT2), 'byte', DVBT2, 1, DVBT2.START_T2_FRAME+1)
end

DataOut.sched = SCHED;
end

function d = diffFrameIdx(sf1,f1,sf2,f2, N_T2)

modVal = N_T2 * 16;% superframe index wraps after 16 superframes
d =(sf1*N_T2+f1) - (sf2*N_T2+f2);
d = mod(d,modVal); % superframe index wraps after 15
if (d>modVal/2)
    d = d-modVal; % take the difference in the smaller direction
end

end