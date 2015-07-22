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
%* Description : T2_TX_DVBT2BLMADAPT DVBT2 Mode Adaptation including
%*               allocation model 2
%*               DOUT = T2_TX_DVBT2MODEL2MADAPT(DVBT2, FID, DIN) builds BB
%*               frames.  FID specifies
%*               the file where any debug message is sent.  
%******************************************************************************

function [DataOut] = t2_tx_dvbt2model2madapt(DVBT2, FidLogFile, DataIn)
%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2blmadapt SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
NUM_PLPS   = DVBT2.NUM_PLPS; % Number of PLPs
NUM_GROUPS = DVBT2.NUM_GROUPS;
TS = DVBT2.STANDARD.TS; % total symbol period
SF = DVBT2.STANDARD.SF; % sampling frequency
BW = DVBT2.BW; %bandwidth in MHz
L_F = DVBT2.STANDARD.L_F; % symbols per frame
FEF_LENGTH = DVBT2.FEF_LENGTH;
FEF_INTERVAL = DVBT2.FEF_INTERVAL;
FEF_ENABLED = DVBT2.FEF_ENABLED;
if ~FEF_ENABLED
    FEF_INTERVAL = 1;
    FEF_LENGTH = 0;
end

SPEC_VERSION = DVBT2.SPEC_VERSION;
%------------------------------------------------------------------------------
% State initialisation
%------------------------------------------------------------------------------
global DVBT2_STATE;
if DVBT2.START_T2_FRAME == 0
  DVBT2_STATE.MADAPT.NEXT_INT_FRAME = zeros(NUM_PLPS,1);
  for plp=1:NUM_PLPS
      STREAM = DVBT2.PLP(plp).STREAM;
      if ((STREAM.TS_GS == 0 || STREAM.TS_GS == 3) && STREAM.MODE == 0) % Dummy CRC=0 in Normal mode for packetised streams
          DVBT2_STATE.MADAPT.PLP(plp).UNUSED_DATA = zeros(1,8);
          DVBT2_STATE.MADAPT.PLP(plp).NUM_UNUSED_BITS = [0 1]; % The CRC wasn't in the original input stream so doesn't count to the bits carried over from previous CW
      else
          DVBT2_STATE.MADAPT.PLP(plp).UNUSED_DATA = [];
          DVBT2_STATE.MADAPT.PLP(plp).NUM_UNUSED_BITS = [0 1];
      end
      DVBT2_STATE.MADAPT.PLP(plp).MADAPT_UNUSED_PACKETS = [];
      DVBT2_STATE.MADAPT.PLP(plp).DNP = 0;
      DVBT2_STATE.MADAPT.PLP(plp).ISCR = 0;
      DVBT2_STATE.MADAPT.PLP(plp).MADAPT_DELAY_DATA = [];
      DVBT2_STATE.MADAPT.PLP(plp).NBLOCKS = zeros(1,DVBT2.PLP(plp).COMP_DELAY); % todo do this properly;
  end
end

%------------------------------------------------------------------------------
% PLP Loop
%------------------------------------------------------------------------------

retainLastPacket = ~(strcmp(SPEC_VERSION,'1.0.1') || strcmp(SPEC_VERSION,'1.1.1'));

ccm=1;

for plp=2:NUM_PLPS
    if ~strcmp(DVBT2.PLP(plp).CRATE, DVBT2.PLP(plp-1).CRATE)
        ccm = 0;
    end
    if ~strcmp(DVBT2.PLP(plp).CONSTELLATION, DVBT2.PLP(plp-1).CONSTELLATION)
        ccm = 0;
    end
    if DVBT2.PLP(plp).FECLEN ~= DVBT2.PLP(plp-1).FECLEN
        ccm = 0;
    end
end
    
if (NUM_PLPS > 1)
    sis = 0;
else
    sis = 1;
end




for plp=1:NUM_PLPS

    %------------------------------------------------------------------------------
    % PLP-specific Parameters Definition
    %------------------------------------------------------------------------------
    NBLOCKS = DVBT2.PLP(plp).NBLOCKS; % #FEC blocks in each I/L frame
    NUM_BLOCKS_MAX = DVBT2.PLP(plp).NUM_BLOCKS_MAX;
    K_BCH      = DVBT2.STANDARD.PLP(plp).OCOD.K_BCH;   % BCH unencoded block length
    STREAM       = DVBT2.PLP(plp).STREAM;                % stream parameters
    PLP_ID      =    DVBT2.PLP(plp).PLP_ID;
    IN_BAND_A_FLAG = DVBT2.PLP(plp).IN_BAND_A_FLAG;
    IN_BAND_B_FLAG = DVBT2.PLP(plp).IN_BAND_B_FLAG;
    IN_BAND_LEN = DVBT2.STANDARD.PLP(plp).IN_BAND_LEN;
    IN_BAND_A_LEN = DVBT2.STANDARD.PLP(plp).IN_BAND_A_LEN;
    IN_BAND_B_LEN = DVBT2.STANDARD.PLP(plp).IN_BAND_B_LEN;
    P_I = DVBT2.PLP(plp).P_I;
    I_JUMP = DVBT2.PLP(plp).I_JUMP;
    FIRST_FRAME_IDX = DVBT2.PLP(plp).FIRST_FRAME_IDX;
    
    DESIGN_DELAY = DVBT2.PLP(plp).DESIGN_DELAY; % Design delay in cycles of T
    COMP_DELAY = DVBT2.PLP(plp).COMP_DELAY; % compensating delay in Interleaving Frames
    
    START_INT_FRAME_SIG = DVBT2_STATE.MADAPT.NEXT_INT_FRAME(plp); % First Interleaving Frame to schedule (may not be output)
    NUM_INT_FRAMES_SIG = DVBT2.STANDARD.PLP(plp).TOTAL_INT_FRAMES_SIG-START_INT_FRAME_SIG; % Number of Interleaving Frames to schedule (may be zero)    

    %------------------------------------------------------------------------------
    % Procedure
    %------------------------------------------------------------------------------

    % Find which group the PLP belongs to and get the corresponding stream definition
    for group = 1:NUM_GROUPS
        if ~isempty(find([DVBT2.GROUP(group).DATA_PLPS DVBT2.GROUP(group).COMMON_PLP] ==plp, 1))
            DEF = DVBT2.SIM.GROUP(group).INPUT_STREAMS_DEFINITION;
        end
    end
    TS_RATE = DEF.TS_RATE;

    %-----------------------------
    % Pre-process input packets
    %-----------------------------

    assert (STREAM.NPD & STREAM.ISSYI)

    % Calculate UPL
    OUPL = STREAM.UPL; % Start with complete packets
    UPL = OUPL;    
    if STREAM.TS_GS == 0 || STREAM.TS_GS == 3 % TS or GFPS
        UPL = UPL - 8;
    end
    % add CRC8 to each user packet in normal mode
    if ((STREAM.TS_GS == 0 || STREAM.TS_GS == 3) && STREAM.MODE == 0)
        UPL = UPL + 8;
    end
    % Add 8-bit DNP count if NPD enabled
    if (STREAM.NPD)
        UPL = UPL + 8;
    end
    if (STREAM.ISSYI && STREAM.MODE==0) % add on ISSY bytes in NM
        UPL = UPL + 8*STREAM.ISSYLEN;
    end

    dataAux = DataIn{plp}';
    dataAux = reshape(dataAux, OUPL/8,[]); % one col per packet
    dataAux = [DVBT2_STATE.MADAPT.PLP(plp).MADAPT_UNUSED_PACKETS dataAux]; % Prepend any unused packets from last time

    unusedData = DVBT2_STATE.MADAPT.PLP(plp).UNUSED_DATA; % recover data not yet carried in a BBFRAME
    numUnusedBits = DVBT2_STATE.MADAPT.PLP(plp).NUM_UNUSED_BITS; % number of bits (may be fractional) that were not sent in the last frame (including bits in deleted null packets)
    DNP = DVBT2_STATE.MADAPT.PLP(plp).DNP;
    ISCR = DVBT2_STATE.MADAPT.PLP(plp).ISCR;    

    numKeptBits = length(unusedData);
    % calculate SYNCD for packetised streams 
    if (STREAM.TS_GS == 0 || STREAM.TS_GS == 3) % TS or GFPS
        if (STREAM.MODE == 0) % normal mode
            SYNCD = mod(numKeptBits - 8, UPL); % SYNCD points at CRC-8 of previous packet
        else
            SYNCD = mod(numKeptBits, UPL); % SYNCD points at first byte of packet
        end
    else
        SYNCD = 0;
    end

    % Calculate exact collection window duration
    switch BW
        case 1.7
            exactT = [71 131]; % [numerator denominator]
        case 5
            exactT = [7 40];
        case 6
            exactT = [7 48];
        case 7
            exactT = [1 8];
        case 8
            exactT = [7 64];
        case 10
            exactT = [7 80];
    end
    
    totalSymbolSamples = round(DVBT2.STANDARD.NFFT * (1 + DVBT2.GI_FRACTION)); % guaranteed to be an integer so ok to round
    t2FrameSamples = totalSymbolSamples * L_F + 2048;
    ilFrameSamples = t2FrameSamples * P_I * I_JUMP;
    cwSamples = [ilFrameSamples * FEF_INTERVAL FEF_INTERVAL]; %represents rational number
    cwSamples(1) = cwSamples(1) + (P_I * I_JUMP) * FEF_LENGTH; % add on P_I x I_JUMP x FEF_LENGTH / FEF_INTERVAL (denom is already FEF_INTERVAL)
    cwMicroseconds = cwSamples .* exactT;
    bitsPerCollectionWindow = cwMicroseconds .* [TS_RATE 1000000]; % times by TS_RATE/10^6 to get bits per CW
    bitsPerCollectionWindow = bitsPerCollectionWindow ./ gcd(bitsPerCollectionWindow(1),bitsPerCollectionWindow(2)); % cancel to lowest form
    
    %Tcw = round(1e6*(DVBT2.STANDARD.NFFT * (1 + DVBT2.GI_FRACTION) * L_F + 2048)/SF); % time in us should be exact 
    %Tcw = Tcw * P_I * I_JUMP;
    %if FEF_ENABLED
    %    Tcw = Tcw + (P_I * I_JUMP) * FEF_LENGTH /(SF/1e6 * FEF_INTERVAL);
    %end

    %bitsPerCollectionWindow = Tcw * (TS_RATE/1000000); % Input TS Bits per collection window
       
    dataOutAll = DVBT2_STATE.MADAPT.PLP(plp).MADAPT_DELAY_DATA';
    
    SCHED.NBLOCKS{plp} = [DVBT2_STATE.MADAPT.PLP(plp).NBLOCKS zeros(1,NUM_INT_FRAMES_SIG)];
    
    % This loop is over the frames that need to be processed to generate
    % the signalling information. These are not generally the same frames
    % that will be output since some output frames have already been
    % processed and some future frames need to be processed to generate the
    % signalling contained in these frames (e.g. IBS)
    for ILFrameIndex = START_INT_FRAME_SIG:START_INT_FRAME_SIG+NUM_INT_FRAMES_SIG-1
        % Calculate TTO for the first packet
        TTObits = numUnusedBits(1)/numUnusedBits(2); % TS bits from start of collection window to first transmitted packet. Will add on the DNPs
        if (STREAM.TS_GS == 0 || STREAM.TS_GS == 3) && STREAM.MODE==1 % TS or GFPS and HEM
            if (TTObits > OUPL-8) && (DNP == 0) % Start of collection window fell during sync byte of non-null packet
                TTObits = TTObits - OUPL;
            end
        end               
        
        numKeptBits = length(unusedData); % remember how many unused bits are going to be prepended
            
        % Calculate how many packets arrived during this collection window,
        % not counting those in the UNUSED_DATA from last time and any null
        % packets        
        numNewBits = [bitsPerCollectionWindow(1)-numUnusedBits(1) bitsPerCollectionWindow(2)]; 
        numPackets = ceil(numNewBits(1)/numNewBits(2) / OUPL);
        numUnusedBits = [OUPL * numPackets *numNewBits(2)- numNewBits(1) numNewBits(2)]; % Remember how many bits at end of last packet did not arrive in collection window
        bitsToKeep = ceil(numUnusedBits(1)/numUnusedBits(2)); % Bits to chop off the end. Include any bits that only partially arrived in the next collection window

        frameData = dataAux(:,1:numPackets); 
        dataAux = dataAux(:,numPackets+1:end); % keep the packets we don't need this time
        
        UPL = OUPL;

        % Sync byte removal
        if STREAM.TS_GS == 0 || STREAM.TS_GS == 3 % TS or GFPS
            assert(isempty(find(frameData(1,:) ~= STREAM.SYNC,1,'first')));           

            UPL = UPL - 8;
            
            if bitsToKeep>UPL
                bitsToKeep = UPL; % end of collection window fell inside the sync byte
            end
            
            if bitsToKeep==UPL % end of collection window fell during sync byte so in fact the last packet is not fragmented and belongs in the next Interleaving Frame
                dataAux=[frameData(:,end) dataAux]; % put the last packet on the beginning of the packets being kept for next time
                frameData = frameData(:,1:end-1);
                numPackets = numPackets-1;
                bitsToKeep = 0;
                numUnusedBits = [numUnusedBits(1)-OUPL*numUnusedBits(2) numUnusedBits(2)];
            end

            frameData = frameData(2:end,:);
        end

        if (STREAM.ISSYI && STREAM.MODE==0) % ISSY and NM
            frameData = [frameData ; zeros(STREAM.ISSYLEN,numPackets)]; %add space for the ISSY field
            ISSYStartPos = UPL+1;
            UPL = UPL + 8*STREAM.ISSYLEN;
            if (bitsToKeep>0) %if there are a whole number of packets, there are still no bits to keep after adding ISSY
                bitsToKeep = bitsToKeep + 8*STREAM.ISSYLEN;
            end
        end
        
        if STREAM.NPD
            isNull = (frameData(1,:)==hex2dec('1f') & frameData(2,:)==hex2dec('ff')); % Find which are the null packets
            frameData = [frameData ; zeros(1,numPackets)]; %add space for the DNP count
            UPL = UPL + 8;
            if (bitsToKeep>0) %if there are a whole number of packets, there are still no bits to keep after adding NPD
                bitsToKeep = bitsToKeep + 8;
            end
            
            if retainLastPacket
                % The last complete packet should always be transmitted (to
                % prevent DJB underflow)
                if (bitsToKeep==0)
                    isNull(end) = false; % last packet will be transmitted completely
                else
                    isNull(end-1) = false; % last packet is fragmented and we need to transmit the one before
                end
            end

            for i=1:numPackets
                if isNull(i) && DNP<255
                    DNP = DNP + 1;
                else
                    frameData(end,i) = DNP;
                    isNull(i) = false; % in case this was a null packet that had to be kept because DNP=255 already
                    DNP = 0;
                end
            end
            frameData(:,isNull) = []; % Actually delete the null packets
            
            % Adjust TTO bit counter for any null packets at the beginning
            % Find first and second transmitted packets
            ttoAddPackets = find(~isNull, 2, 'first') - 1;
            if numKeptBits==0 && STREAM.MODE == 0 % Normal mode and no bits carried over => apparently complete packet is really fragmented because it starts with the CRC8
                ttoAddPackets = ttoAddPackets(2); % Second transmitted packet is the one that TTO applies to
            else
                ttoAddPackets = ttoAddPackets(1); % First transmitted packet is the one that TTO applies to
            end
            TTObits = TTObits + OUPL * ttoAddPackets;
        else
            isNull = false(1,numPackets);
        end
        
        numNonNullPackets = sum(~isNull);
        
        % Calculate ISCR values for each packet
        if STREAM.ISSYLEN==3
            ISCRBits = 22;
        else
            ISCRBits = 15;
        end
        packetISCR = mod(round(ISCR + (0:numPackets-1)*OUPL * SF/TS_RATE), 2^ISCRBits);
        ISCR = mod(ISCR + numPackets * OUPL * SF/TS_RATE, 2^ISCRBits);
        packetISCR = packetISCR(~isNull); % Remove the ISCRs that apply to deleted null packets
        
        % Calculate TTO value for first packet        
        TTOBase = DESIGN_DELAY;
        if FEF_ENABLED
            TTOBase = TTOBase + FEF_LENGTH*(ILFrameIndex*P_I * I_JUMP/FEF_INTERVAL - floor((ILFrameIndex*P_I*I_JUMP+FIRST_FRAME_IDX)/FEF_INTERVAL));
        end
        TTO = TTOBase + TTObits * SF/TS_RATE;
        
        % Convert byte array to binary array
        dataAuxBin = reshape(de2bi(frameData(:), 8, 'left-msb').', UPL, []);

        % Add ISSY in Normal Mode
        if (STREAM.ISSYI && STREAM.MODE==0) % ISSY and NM
            
            if numKeptBits==0 % first, apparently complete packet is fragmented because the CRC8 was transmitted in previous interleaving frame
                ttoPos = 2;
                bufsPos = 3;
            else
                ttoPos = 1;
                bufsPos = 2;
            end
            
            assert(numPackets>=3); % require at least 3 ISSY variables
            
            % Put ISCR everywhere to begin with
            if STREAM.ISSYLEN==3
                packetISSY =[ones(1,numNonNullPackets); zeros(1,numNonNullPackets)]; % long ISCR starts '10'
            else
                packetISSY =zeros(1,numNonNullPackets); % short ISCR starts with '0'
            end
            packetISSY = [packetISSY; de2bi(packetISCR',ISCRBits,'left-msb')'];
            % Now insert TTO associated with first COMPLETE transmitted packet
            packetISSY(:,ttoPos) = t2_tx_dvbt2blmadapt_makeTTO(TTO, STREAM.ISSYLEN)';
            % and BUFS associated with second COMPLETE transmitted packet
            packetISSY(:,bufsPos) = t2_tx_dvbt2blmadapt_makeBUFS(STREAM.BUFFER_SIZE, STREAM.ISSYLEN);
            
            % Now insert it after each packet
            dataAuxBin(ISSYStartPos:ISSYStartPos+8*STREAM.ISSYLEN-1,:) = packetISSY;
        end        
        
         % add CRC8 to each user packet in normal mode
        if ((STREAM.TS_GS == 0 || STREAM.TS_GS == 3) && STREAM.MODE == 0) 
            dataAuxBin = [dataAuxBin ; zeros(8, numNonNullPackets)]; % add space for CRC at bottom

            UPL = UPL + 8;
            if (bitsToKeep>0)
                bitsToKeep = bitsToKeep + 8;
            end

            for pktIdx = 1:numNonNullPackets
                dataAuxBin(UPL-7:end, pktIdx) = t2_tx_dvbt2blmadapt_crc8(dataAuxBin(1:UPL-8, pktIdx)')';        
            end
        end

        dataAuxBin = [unusedData reshape(dataAuxBin,1,[])]; % Convert to binary and prepend unused bits from last time


        % Now remove the unused bits from the end
        if isNull(end)
            % end of collection window fell in a deleted null packet
            bitsToKeep = 0; % No unused data to keep for next time 
        end
        
        unusedData = dataAuxBin(end-bitsToKeep+1:end);
        dataAuxBin = dataAuxBin(1:end-bitsToKeep);        

        MODEb = de2bi(STREAM.MODE, 8, 'left-msb');

        MATYPE1b = de2bi(STREAM.TS_GS,2,'left-msb');

        MATYPE1b = [MATYPE1b de2bi(sis,1,'left-msb')];
        MATYPE1b = [MATYPE1b de2bi(ccm,1,'left-msb')];
        MATYPE1b = [MATYPE1b de2bi(STREAM.ISSYI,1,'left-msb')];
        MATYPE1b = [MATYPE1b de2bi(STREAM.NPD,1,'left-msb')];
        MATYPE1b = [MATYPE1b de2bi(STREAM.EXT,2,'left-msb')];

        MATYPE2b = de2bi(PLP_ID, 8, 'left-msb'); % MATYPE byte 2 = 0x00 (reserved)

        %---------------------------
        % Baseband frame generation
        %---------------------------

        numHeaderBits = 80;
        numDataFieldBitsMax = K_BCH-numHeaderBits;

        % Calculate index of first BBframe of each interleaving frame

        if isempty(NBLOCKS) % automatically assign minimum number of FEC blocks
            numBBFrames = ceil( (length(dataAuxBin)+IN_BAND_LEN)/numDataFieldBitsMax);
            assert(numBBFrames <= NUM_BLOCKS_MAX);
        else
            numBBFrames = NBLOCKS; % Fixed number of FEC blocks (e.g. for fixed rate common PLP)
        end
        
        SCHED.NBLOCKS{plp}(ILFrameIndex+1+COMP_DELAY) = numBBFrames;        
        
        fprintf(FidLogFile,'\t\tNumber of complete BB frames: %d (%d data bits per frame)\n', numBBFrames, numDataFieldBitsMax);
        fprintf(FidLogFile,'\t\tNumber of transmitted bytes: %d\n', numBBFrames*numDataFieldBitsMax/8);

        % Initialise output array
        bbFramedDataPreScrambling = zeros(1, numBBFrames*K_BCH/8);

        dataStart = 1;

        dflList = zeros(1, numBBFrames);

        if STREAM.ISSYI && STREAM.MODE==1
            assert(numBBFrames>=3); % Must have at least 3 ISSY variables per Interleaving Frame
        end
        
        for bbFrameIdx = 1:numBBFrames

            inBandField = [];
            if bbFrameIdx == 1 % It's the first BBFrame of an Interleaving Frame and might need IBS
                if  IN_BAND_A_FLAG                                   
                    inBandField = [inBandField zeros(1,IN_BAND_A_LEN)]; % dummy IBS to be replaced later
                end
                if IN_BAND_B_FLAG
                    inBandField = [inBandField t2_tx_dvbt2blmadapt_inbandgenB(TTO, packetISCR(1), STREAM.BUFFER_SIZE, TS_RATE)];
                end
            end

            numDataFieldBits = numDataFieldBitsMax - length(inBandField);

            dataEnd = dataStart + numDataFieldBits - 1;

            if dataEnd > length(dataAuxBin)
                dataEnd = length(dataAuxBin);
            end

            dataField = dataAuxBin(dataStart:dataEnd);

            padding = zeros(1,numDataFieldBits - length(dataField)); % Add BBFrame padding if not enough data

            numDataFieldBits = length(dataField);
            dflList(bbFrameIdx) = numDataFieldBits;

            %fprintf(FidLogFile,'\t\t%3d::\tpacketPos: %5d;\tSYNCD
            %%5d;\tdataStart: %9d;\tdataEnd: %9d\n', bbFrameIdx, packetPos, SYNCD, dataStart, dataEnd);
            
            % Generate UPL and SYNC header fields
            if (STREAM.MODE == 0) 
                UPLb = de2bi(UPL, 16, 'left-msb'); % user packet length
                SYNCb = de2bi(STREAM.SYNC, 8, 'left-msb'); % user packet sync byte                               
            elseif STREAM.ISSYI % HEM - UPL and SYNC fields used for ISSY 
                assert(STREAM.ISSYLEN==3);
                firstPacketIndex = 1+ceil((dataStart-1-numKeptBits)/UPL); % Index of the packet to which ISSY refers
                if bbFrameIdx == 1
                    ISSYb = t2_tx_dvbt2blmadapt_makeTTO(TTO, STREAM.ISSYLEN);
                elseif bbFrameIdx == 2
                    ISSYb = t2_tx_dvbt2blmadapt_makeBUFS(STREAM.BUFFER_SIZE, STREAM.ISSYLEN);
                elseif numDataFieldBits == 0 % pure padding
                    ISSYb = t2_tx_dvbt2blmadapt_makeBUFS(STREAM.BUFFER_SIZE, STREAM.ISSYLEN);
                elseif firstPacketIndex > numNonNullPackets % no packet starts in the data field - send BUFs
                    ISSYb = t2_tx_dvbt2blmadapt_makeBUFS(STREAM.BUFFER_SIZE, STREAM.ISSYLEN);
                else
                    ISSYb = t2_tx_dvbt2blmadapt_makeISCR(packetISCR(firstPacketIndex), STREAM.ISSYLEN);
                end
                UPLb = ISSYb(1:16);
                SYNCb = ISSYb(17:24);
            else % HEM and no ISSY, set to zero
                UPLb = zeros(1,16);
                SYNCb =zeros(1,8);
            end
            
            
            if (SYNCD >= numDataFieldBits) % No UP begins in the data field - use special value 65535
                 SYNCDb = de2bi(65535,16,'left-msb');
            else
                 SYNCDb = de2bi(SYNCD,16,'left-msb');
            end

            % Generate DFL header field
            DFLb = de2bi(numDataFieldBits, 16, 'left-msb');

            % Construct header, less CRC8 (this will be different for each BBFrame
            % because of the SYNCD field)

            bbHeader = [MATYPE1b MATYPE2b UPLb DFLb SYNCb SYNCDb];

            % Append CRC8 (different each BBFrame because of SYNCD field)

            CRC8b = xor(t2_tx_dvbt2blmadapt_crc8(bbHeader), MODEb);
            bbHeader = [bbHeader CRC8b];

            bbFrame = [bbHeader, dataField, inBandField, padding];

            % separate array to keep the BBFrames prior to scrambling for V&V
            % output point 3
            bbFramedDataPreScrambling((bbFrameIdx-1)*K_BCH/8+1:bbFrameIdx*K_BCH/8) = bi2de(reshape(bbFrame, 8, []).', 'left-msb').';

            % calculate new SYNCD for packetised streams 
            if (STREAM.TS_GS == 0 || STREAM.TS_GS == 3) % TS or GFPS
                SYNCD = mod(SYNCD - numDataFieldBits, UPL);
            end

            % calculate new dataStart position
            dataStart = dataStart + numDataFieldBits;
        end        
        dataOutAll = [dataOutAll bbFramedDataPreScrambling];
        
        t2_tx_dvbt2blmadapt_SaveDJBInfo(isNull, dflList, plp, ILFrameIndex, DVBT2); % Save info used by the DJB model
    end
    
    
    % keep the remaining data for next run
    DVBT2_STATE.MADAPT.PLP(plp).UNUSED_DATA = unusedData;
    DVBT2_STATE.MADAPT.PLP(plp).NUM_UNUSED_BITS = numUnusedBits; % number of bits (may be fractional) that were not sent in the last frame (including bits in deleted null packets)
    DVBT2_STATE.MADAPT.PLP(plp).DNP = DNP; % Number of deleted null packets at the end of last frame
    DVBT2_STATE.MADAPT.PLP(plp).ISCR = ISCR; % 
    DVBT2_STATE.MADAPT.NEXT_INT_FRAME(plp) = START_INT_FRAME_SIG + NUM_INT_FRAMES_SIG;
    DVBT2_STATE.MADAPT.PLP(plp).NBLOCKS = SCHED.NBLOCKS{plp};
    DVBT2_STATE.MADAPT.PLP(plp).MADAPT_UNUSED_PACKETS = dataAux;

    DataOut.data{plp} = dataOutAll';
 

end

% TODO: ensure that min number of blocks generated for data PLPs in groups.

% Calculate the scheduling now we know the numbers of FEC blocks
SCHED = t2_tx_dvbt2blmadapt_schedule(DVBT2, SCHED);

% Save schedule and DVBT2 parameter structure for DJB model
t2_tx_dvbt2blmadapt_SaveDJBParamsSched(SCHED, DVBT2);

% Now go back and insert all the IBS

for plp = 1:NUM_PLPS
    NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleving Frames to generate (may be zero)
    START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME;
    K_BCH      = DVBT2.STANDARD.PLP(plp).OCOD.K_BCH;   % BCH unencoded block length
    IN_BAND_A_FLAG = DVBT2.PLP(plp).IN_BAND_A_FLAG;
    IN_BAND_A_LEN = DVBT2.STANDARD.PLP(plp).IN_BAND_A_LEN;

    if IN_BAND_A_FLAG
        bbFrameIdx = 1;
        % This loop is for the frames to be output
        for ILFrameIndex = START_INT_FRAME:START_INT_FRAME+NUM_INT_FRAMES-1 % IBS for last I/L frame not ready yet
            inBandField = t2_tx_dvbt2blmadapt_inbandgenA(DVBT2, SCHED, plp, ILFrameIndex); % generate the IBS
            assert(length(inBandField)==IN_BAND_A_LEN);
            % Recover the relevant BBFrame
            bbFrame = DataOut.data{plp}((bbFrameIdx-1)*K_BCH/8+1:bbFrameIdx*K_BCH/8);
            
            bbFrame = reshape(de2bi(bbFrame, 8, 'left-msb')',[],1);
            DFL = bi2de(bbFrame(33:48)', 'left-msb');
            bbFrame(DFL+1+numHeaderBits:DFL+numHeaderBits+IN_BAND_A_LEN) = inBandField;
            DataOut.data{plp}((bbFrameIdx-1)*K_BCH/8+1:bbFrameIdx*K_BCH/8) = bi2de(reshape(bbFrame, 8, []).', 'left-msb').';
            bbFrameIdx = bbFrameIdx + SCHED.NBLOCKS{plp}(ILFrameIndex+1);
        end
        
    end

    % Save any BBFrames which are not needed for output this time
    bbFramesToOutput = sum(SCHED.NBLOCKS{plp}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES));
    DVBT2_STATE.MADAPT.PLP(plp).MADAPT_DELAY_DATA = DataOut.data{plp}(bbFramesToOutput*K_BCH/8+1:end);
    DataOut.data{plp} = DataOut.data{plp}(1:bbFramesToOutput*K_BCH/8);

    write_vv_test_point(DataOut.data{plp}, K_BCH/8, SCHED.NBLOCKS{plp}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES), vv_fname('03', plp, DVBT2), 'byte', DVBT2, 1, DVBT2.START_T2_FRAME+1)
    write_bbf_file(FidLogFile, DataOut.data{plp}, DVBT2.SIM.PLP(plp).OUTPUT_BBF_FILENAME, DVBT2.START_T2_FRAME==0);

end
       
DataOut.sched = SCHED;

end



