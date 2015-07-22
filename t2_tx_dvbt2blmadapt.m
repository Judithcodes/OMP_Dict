function [DataOut] = t2_tx_dvbt2blmadapt(DVBT2, FidLogFile, DataIn)
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
SF = DVBT2.STANDARD.SF; % sampling frequency
NFFT = DVBT2.STANDARD.NFFT; % FFT size
GI_FRACTION = DVBT2.GI_FRACTION;
L_F = DVBT2.STANDARD.L_F; % OFDM symbols per frame
P1LEN = DVBT2.STANDARD.P1LEN; % samples in P1
FEF_LENGTH = DVBT2.FEF_LENGTH;
FEF_INTERVAL = DVBT2.FEF_INTERVAL;
FEF_ENABLED = DVBT2.FEF_ENABLED;


% Calculated values
cyclesPerT2Frame = round((NFFT+NFFT*GI_FRACTION)*L_F+P1LEN);

%------------------------------------------------------------------------------
% State initialisation
%------------------------------------------------------------------------------
global DVBT2_STATE;
if DVBT2.START_T2_FRAME == 0
  for plp=1:NUM_PLPS
      DVBT2_STATE.MADAPT.PLP(plp).FIRST_BIT_INDEX = 0;
      STREAM = DVBT2.PLP(plp).STREAM;
      if ((STREAM.TS_GS == 0 || STREAM.TS_GS == 3) && STREAM.MODE == 0) % Dummy CRC=0 in Normal mode for packetised streams
          DVBT2_STATE.MADAPT.PLP(plp).UNUSED_DATA = zeros(1,8);
      else
          DVBT2_STATE.MADAPT.PLP(plp).UNUSED_DATA = [];
      end
      DVBT2_STATE.MADAPT.PLP(plp).UNUSED_PACKETS = [];
      DVBT2_STATE.MADAPT.PLP(plp).ISCRTotal = 0;
  end
end

%------------------------------------------------------------------------------
% PLP Loop
%------------------------------------------------------------------------------

ccm=1;

% Do the scheduling
for plp=1:NUM_PLPS
    SCHED.NBLOCKS{plp} = DVBT2.PLP(plp).NBLOCKS;
end

SCHED = t2_tx_dvbt2blmadapt_schedule(DVBT2, SCHED);

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
    START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME; % First Interleaving Frame to generate
    NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleving Frames to generate (may be zero)
    NBLOCKS = SCHED.NBLOCKS{plp}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame
    NUM_FBLOCK = sum(NBLOCKS); % Total number of FEC blocks to generate
    K_BCH      = DVBT2.STANDARD.PLP(plp).OCOD.K_BCH;   % BCH unencoded block length
    STREAM       = DVBT2.PLP(plp).STREAM;                % stream parameters
    PLP_ID      =    DVBT2.PLP(plp).PLP_ID;
    IN_BAND_A_FLAG = DVBT2.PLP(plp).IN_BAND_A_FLAG;
    IN_BAND_B_FLAG = DVBT2.PLP(plp).IN_BAND_B_FLAG;
    IN_BAND_LEN = DVBT2.STANDARD.PLP(plp).IN_BAND_LEN;
    P_I = DVBT2.PLP(plp).P_I;
    I_JUMP = DVBT2.PLP(plp).I_JUMP;
    FIRST_FRAME_IDX = DVBT2.PLP(plp).FIRST_FRAME_IDX;
    DESIGN_DELAY = DVBT2.PLP(plp).DESIGN_DELAY; % Design delay in cycles of T
   
    %------------------------------------------------------------------------------
    % Procedure
    %------------------------------------------------------------------------------

    %------------------------------------------------------------------------------
    % Dummy BBHEADER Definition
    %------------------------------------------------------------------------------
    %MATYPE1 = hex2dec('70');        % MATYPE byte 1:-
                                    % TS/GS = b'01' (GCS)
                                    % SIS/MIS = b'1' (single input stream)
                                    % CCM/ASM = b'1' (Constant Coding Modulation)
                                    % ISSYI = b'0' (ISSY not active)
                                    % NPD = b'0' (Null Packet Deletion not active)
                                    % EXT = b'00' (reserved)


    %UPL1 = hex2dec('00');           % User Packet Length = 0 (always the case for GCS)
    %UPL2 = hex2dec('00');           % User Packet Length = 0 (always the case for GCS)



    %DFL1 = floor((K_BCH-80)/256);   % Data Field Length set to unencoded BCH block 
    %DFL2 = rem(K_BCH-80, 256);      % length less header length (ie no padding)

    %SYNC = hex2dec('00');           % Sync byte - not releavent for GCS, since non-packetised

    %SYNCD1 = hex2dec('00');         % offset to start first UP - not relavent for 
                                    % GCS, since non-packetised

    %SYNCD2 = hex2dec('00');         % offset to start first UP - not relavent for 
                                    % GCS, since non-packetised


    dataAux = DataIn{plp}';
    unusedData = DVBT2_STATE.MADAPT.PLP(plp).UNUSED_DATA; % recover data not yet carried in a BBFRAME
    unusedPackets = DVBT2_STATE.MADAPT.PLP(plp).UNUSED_PACKETS; % recover compete packets not yet carried
    firstBitIndex = DVBT2_STATE.MADAPT.PLP(plp).FIRST_BIT_INDEX;
    
    numHeaderBits = 80;
    numDataFieldBitsMax = K_BCH-numHeaderBits;

    
    %-----------------------------
    % Pre-process input packets
    %-----------------------------

    OUPL = STREAM.UPL; % Start with complete packets

    finalUPL = OUPL;
    % Calculate UPL
    if STREAM.TS_GS == 0 || STREAM.TS_GS == 3 % TS or GFPS
        finalUPL = finalUPL - 8;
    end
    % add CRC8 to each user packet in normal mode
    if ((STREAM.TS_GS == 0 || STREAM.TS_GS == 3) && STREAM.MODE == 0)
        finalUPL = finalUPL + 8;
    end
    % Add 8-bit DNP count if NPD enabled
    if (STREAM.NPD)
        finalUPL = finalUPL + 8;
    end
    if (STREAM.ISSYI && STREAM.MODE==0) % add on ISSY bytes in NM
        finalUPL = finalUPL + 8*STREAM.ISSYLEN;
    end

    % Convert input byte array to binary array
    dataAuxBin = reshape(de2bi(dataAux, 8, 'left-msb').', 1, []);

    if STREAM.TS_GS == 0 || STREAM.TS_GS == 3 % TS or GFPS
      dataAuxBin = reshape(dataAuxBin, OUPL, []);% one packet per column
      unusedPackets = [unusedPackets dataAuxBin]; % prepend unused packets from last time
    end
    
    numPackets = size(dataAuxBin,2);
        
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
    numPacketsInILFrame = numPackets; % default value 
    % Calculate index of first BBframe of each interleaving frame
    %IFStartIndex = cumsum(NBLOCKS)+1;
    %IFStartIndex = [1 IFStartIndex(1:end-1)];
    
    %fprintf(FidLogFile,'\t\tNumber of complete BB frames: %d (%d data bits per frame)\n', numBBFrames, numDataFieldBitsMax);
    %fprintf(FidLogFile,'\t\tNumber of transmitted bytes: %d\n', numBBFrames*numDataFieldBitsMax/8);

    if STREAM.ISSYI
        % Calculate TS rate            
        assert(all(diff(NBLOCKS)==0)); % Calculation only works if number of blocks is fixed
        % Basic no-FEFs calculation
        TS_RATE = (numDataFieldBitsMax * NBLOCKS(1) - IN_BAND_LEN)*OUPL/finalUPL *SF/(cyclesPerT2Frame*P_I*I_JUMP);
        % Account for FEF proportion
        if (FEF_ENABLED) 
            TS_RATE = TS_RATE *cyclesPerT2Frame*FEF_INTERVAL/(cyclesPerT2Frame*FEF_INTERVAL+FEF_LENGTH);
        end            

        DVBT2.SIM.GROUP(plp).INPUT_STREAMS_DEFINITION.TS_RATE = TS_RATE; % Kluge to get TS_RATE stored in DVBT2 for use by DJB model
    end
    
    % Initialise output array
    bbFramedDataPreScrambling = zeros(1, NUM_FBLOCK*K_BCH/8);
    bbFrameCount = 1;

    ISCRTotal = DVBT2_STATE.MADAPT.PLP(plp).ISCRTotal;    

    for ILFrameIndex = START_INT_FRAME:START_INT_FRAME+NUM_INT_FRAMES-1
        numBBFrames = NBLOCKS(ILFrameIndex - START_INT_FRAME+1); 
        dflList = zeros(1,numBBFrames);

        numBitsInILFrame = numBBFrames*numDataFieldBitsMax - IN_BAND_LEN;

        UPL = OUPL;

        if STREAM.TS_GS == 0 || STREAM.TS_GS == 3 % TS or GFPS
            numPacketsInILFrame = ceil((numBitsInILFrame-length(unusedData)) / finalUPL); % number of new packets to process
            dataAuxBin = unusedPackets(:,1:numPacketsInILFrame); % just take the packets that will be used this frame
            unusedPackets = unusedPackets(:,numPacketsInILFrame+1:end); % save the rest for next frame
            % remove sync byte
            assert(dataAux(1) == STREAM.SYNC);
            dataAuxBin = dataAuxBin(9:UPL,:);
            UPL = UPL - 8;

            ILFrameStartT2Frame = ILFrameIndex*P_I*I_JUMP + FIRST_FRAME_IDX; %index of first T2-frame of I/L frame
            ILFrameStartTime = ILFrameStartT2Frame*cyclesPerT2Frame;
            if (FEF_ENABLED)
                ILFrameStartTime = ILFrameStartTime + floor(ILFrameStartT2Frame/FEF_INTERVAL)*FEF_LENGTH; %start time in units of T
            end

            if STREAM.ISSYI
                % Calculate ISCR values for each packet
                packetISCRTotal = round(ISCRTotal + (0:numPacketsInILFrame-1)*OUPL * SF/TS_RATE); % doesn't wrap

                % Calculate TTO for first packet
                assert(DESIGN_DELAY>0); % in case we forgot to define it
                TTO = ISCRTotal - ILFrameStartTime + DESIGN_DELAY;        

                % Update ISCRTotal for next frame
                ISCRTotal = ISCRTotal + numPacketsInILFrame * OUPL * SF/TS_RATE;
                %packetISCR = packetISCR(~isNull); % Remove the ISCRs that apply to deleted null packets

                % Calculate TTO value for first packet    
                %iscrTotal = ceil((firstBitIndex+dataStart-1)/UPL)*OUPL*SF/TS_RATE; % time for first packet from beginning of first ever collection window in T
            end
        end
        
        if STREAM.ISSYI
            if STREAM.ISSYLEN==3
                ISCRBits = 22;
            else
                ISCRBits = 15;
            end
        end
        
        % Add ISSY in Normal Mode
        if STREAM.ISSYI && STREAM.MODE==0 % ISSY and NM
            assert(numPacketsInILFrame>=3); % must have three ISSY variables in each Interleaving Frame
            % Put ISCR everywhere to begin with
            if STREAM.ISSYLEN==3
                packetISSY =[ones(1,numPacketsInILFrame); zeros(1,numPacketsInILFrame)]; % long ISCR starts '10'
            else
                packetISSY =zeros(1,numPacketsInILFrame); % short ISCR starts with '0'
            end
            packetISSY = [packetISSY; de2bi(mod(packetISCRTotal, 2^ISCRBits)',ISCRBits,'left-msb')'];
            % Now insert TTO associated with first transmitted packet
            packetISSY(:,1) = t2_tx_dvbt2blmadapt_makeTTO(TTO, STREAM.ISSYLEN)';
            % and BUFS associated with second transmitted packet
            packetISSY(:,2) = t2_tx_dvbt2blmadapt_makeBUFS(STREAM.BUFFER_SIZE, STREAM.ISSYLEN);
            
            % Now insert it after each packet
            dataAuxBin = [dataAuxBin; packetISSY];
            UPL = UPL + 8*STREAM.ISSYLEN;
        end        
                
        % add CRC8 to each user packet in normal mode
        if ((STREAM.TS_GS == 0 || STREAM.TS_GS == 3) && STREAM.MODE == 0)
            dataAuxBin = [dataAuxBin ; zeros(8,numPacketsInILFrame)]; % add space for CRC at bottom
            for pktIdx = 1: numPacketsInILFrame
                dataAuxBin(UPL+1:end, pktIdx) = t2_tx_dvbt2blmadapt_crc8(dataAuxBin(1:UPL, pktIdx)')';        
            end
            UPL = UPL + 8;
        end

        isNull = zeros(1,numPacketsInILFrame);
        dataAuxBin = reshape(dataAuxBin,1,[]);

        % calculate SYNCD for packetised streams 
        if (STREAM.TS_GS == 0 || STREAM.TS_GS == 3) % TS or GFPS
            if (STREAM.MODE == 0) % normal mode
                SYNCD = mod(length(unusedData) - 8, UPL); % SYNCD points at CRC-8 of previous packet
            else
                SYNCD = mod(length(unusedData), UPL); % SYNCD points at first byte of packet
            end
        else
          SYNCD = 0;
        end

        % Add any unused data from the previous run to the beginning
        dataAuxBin = [unusedData dataAuxBin];
        dataStart = 1;

        if STREAM.ISSYI && STREAM.MODE==1
            assert(numBBFrames>=3); % Must have at least 3 ISSY variables per Interleaving Frame
        end
                
        for bbFrameIdx = 1:numBBFrames                        
            inBandField = [];
            if bbFrameIdx==1
                if IN_BAND_A_FLAG
                    % It's the first BBFrame of an Interleaving Frame and needs IBS
                    inBandField = [inBandField t2_tx_dvbt2blmadapt_inbandgenA(DVBT2, SCHED, plp, ILFrameIndex)];
                end
                if IN_BAND_B_FLAG
                    inBandField = [inBandField t2_tx_dvbt2blmadapt_inbandgenB(TTO, packetISCRTotal(1), STREAM.BUFFER_SIZE, TS_RATE)];
                end
                assert(length(inBandField)==IN_BAND_LEN);
            end

            numDataFieldBits = numDataFieldBitsMax - length(inBandField);
            dflList(bbFrameIdx) = numDataFieldBits;

            dataEnd = dataStart + numDataFieldBits - 1;
            dataField = dataAuxBin(dataStart:dataEnd);

            %fprintf(FidLogFile,'\t\t%3d::\tpacketPos: %5d;\tSYNCD %5d;\tdataStart: %9d;\tdataEnd: %9d\n', bbFrameIdx, packetPos, SYNCD, dataStart, dataEnd);

            if (SYNCD >= numDataFieldBits) % No UP begins in the data field - use special value 65535
                 SYNCDb = de2bi(65535,16,'left-msb');
            else
                 SYNCDb = de2bi(SYNCD,16,'left-msb');
            end

            % Generate DFL header field
            DFLb = de2bi(numDataFieldBits, 16, 'left-msb');

            % Generate ISSY
            if STREAM.ISSYI && STREAM.MODE==1
                firstPacketIndex = ceil((dataStart-length(unusedData)-1)/UPL)+1; % Calculate which packet the ISSY applies to
                if bbFrameIdx==1 % TTO
                    ISSYb = t2_tx_dvbt2blmadapt_makeTTO(TTO, STREAM.ISSYLEN);
                elseif bbFrameIdx == 2
                    ISSYb = t2_tx_dvbt2blmadapt_makeBUFS(STREAM.BUFFER_SIZE, STREAM.ISSYLEN);
                elseif SYNCD >= numDataFieldBits % no packet starts in the data field - send BUFs
                    ISSYb = t2_tx_dvbt2blmadapt_makeBUFS(STREAM.BUFFER_SIZE, STREAM.ISSYLEN);
                else
                    ISSYb = t2_tx_dvbt2blmadapt_makeISCR(mod(packetISCRTotal(firstPacketIndex),2^ISCRBits), STREAM.ISSYLEN);
                end
            end

            % Generate UPL and SYNC header fields
            if (STREAM.MODE == 1) % HEM - UPL and SYNC fields used for ISSY if enabled
                if STREAM.ISSYI
                    UPLb = ISSYb(1:16);
                    SYNCb = ISSYb(17:24);
                else
                    UPLb = de2bi(0, 16, 'left-msb');
                    SYNCb = de2bi(0, 8, 'left-msb');
                end
            else
                UPLb = de2bi(UPL, 16, 'left-msb'); % user packet length
                SYNCb = de2bi(STREAM.SYNC, 8, 'left-msb'); % user packet sync byte                               
            end

            % Construct header, less CRC8 (this will be different for each BBFrame
            % because of the SYNCD field)

            bbHeader = [MATYPE1b MATYPE2b UPLb DFLb SYNCb SYNCDb];

            % Append CRC8 (different each BBFrame because of SYNCD field)

            CRC8b = xor(t2_tx_dvbt2blmadapt_crc8(bbHeader), MODEb);
            bbHeader = [bbHeader CRC8b];

            bbFrame = [bbHeader, dataField, inBandField];

            % separate array to keep the BBFrames prior to scrambling for V&V
            % output point 3
            bbFramedDataPreScrambling((bbFrameCount-1)*K_BCH/8+1:bbFrameCount*K_BCH/8) = bi2de(reshape(bbFrame, 8, []).', 'left-msb').';
            bbFrameCount = bbFrameCount + 1;

            % calculate new SYNCD for packetised streams 
            if (STREAM.TS_GS == 0 || STREAM.TS_GS == 3) % TS or GFPS
                SYNCD = mod(SYNCD - numDataFieldBits, UPL);
            end

            % calculate new dataStart position
            dataStart = dataStart + numDataFieldBits;
        end
        unusedData = dataAuxBin(dataStart:end);

        % Save information for DJB model
        t2_tx_dvbt2blmadapt_SaveDJBInfo(isNull, dflList, plp, ILFrameIndex, DVBT2); % Save info used by the DJB model
    end

    % keep the remaining data for next run
    DVBT2_STATE.MADAPT.PLP(plp).UNUSED_DATA = unusedData;
    DVBT2_STATE.MADAPT.PLP(plp).UNUSED_PACKETS = unusedPackets;
    DVBT2_STATE.MADAPT.PLP(plp).ISCRTotal = ISCRTotal;

    write_vv_test_point(bbFramedDataPreScrambling, K_BCH/8, NBLOCKS, vv_fname('03', plp, DVBT2), 'byte', DVBT2, 1, DVBT2.START_T2_FRAME+1)
    write_bbf_file(FidLogFile, bbFramedDataPreScrambling, DVBT2.SIM.PLP(plp).OUTPUT_BBF_FILENAME, DVBT2.START_T2_FRAME==0);

    DataOut.data{plp} = bbFramedDataPreScrambling';
end

% Save schedule and DVBT2 parameter structure for DJB model
t2_tx_dvbt2blmadapt_SaveDJBParamsSched(SCHED, DVBT2);


DataOut.sched = SCHED;
