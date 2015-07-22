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
%* Description : T2_TX_DVBT2DYNDATAGEN DVB V&V dynamic multiple PLP model
%*               DOUT = T2_TX_DVBT2DYNVVDATAGEN(DVBT2) generates a set of input TSs 
%*               according to the dynamic multiple PLP model 
%*               DOUT = T2_TX_DVBT2DYNVVTSDATAGEN(DVBT2, FID) specifies the file 
%*               identifier in FID where any debug message is sent.
%******************************************************************************

function DataOut = t2_tx_dvbt2dynvvdatagen(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_tx_dvbt2dynvvdatagen SYNTAX');
end

global DVBT2_STATE;

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------


NUM_GROUPS = DVBT2.NUM_GROUPS;
NUM_PLPS = DVBT2.NUM_PLPS;

%------------------------------------
%  State
%------------------------------------
if DVBT2.START_T2_FRAME==0
    DVBT2_STATE.DATAGEN.NEXT_INT_FRAME = zeros(NUM_PLPS,1); % Indicate the next interleaving frame to generate, to keep track of ones generated previously
end

%----------------------------------
% Procedure
%----------------------------------

if DVBT2.SIM.EN_DJB_SHORTCUTS
    warning('CSP:DJB_SHORTCUTS','Shortcuts enabled for DJB simulation: data generated will not be V&V or DVB compliant');
    assert (~DVBT2.SIM.EN_VV_FILES);
end

DataOut = cell(NUM_PLPS,1);

for group = 1:NUM_GROUPS

    % Group params
    DATA_PLPS = DVBT2.GROUP(group).DATA_PLPS;
    COMMON_PLP = DVBT2.GROUP(group).COMMON_PLP;
    DEF = DVBT2.SIM.GROUP(group).INPUT_STREAMS_DEFINITION;
    TS_RATE = DEF.TS_RATE;
    
    %------------------------------------------------------------------------------
    % Procedure
    %------------------------------------------------------------------------------
    
    M = DEF.M; % common slot interval
    N_EIT = DEF.N_EIT; % number of EITs in a row
    NumRepsList = DEF.NUM_REPS;
    L = length(NumRepsList); % number of chapters
    RunLengthTable = DEF.RUN_LENGTH; % row is TS, col is chapter
    N = size(RunLengthTable, 1); % number of TSs
    if isfield (DEF, 'NULL_CHAPTERS')
        isNullChapter = DEF.NULL_CHAPTERS;
    else
        isNullChapter = zeros (1, L);
    end

    RepUnitSlots = sum(RunLengthTable, 1); % slots in each repeating unit
    ChapterSlots = RepUnitSlots .* NumRepsList; % slots in each chapter
    TotalNormalSlots = sum(ChapterSlots); % Total number of normal slots to generate

    fprintf(FidLogFile,'Making sequence\n');

    % Make a matrix describing the sequence

    % Normal slots
    NormalSequence = zeros(TotalNormalSlots, 1); % TS index for each slot

    chapPos = 1;
    for chapter = 1:L;
        RepUnit = zeros(RepUnitSlots(chapter),1);
        pos = 1;
        for i=1:N;
            if isNullChapter(chapter)
                RepUnit(pos:pos+RunLengthTable(i,chapter)-1) = -1; %Flag as a null chapter - it will be kept as null packets
            else
                RepUnit(pos:pos+RunLengthTable(i,chapter)-1) = i;
            end
            pos = pos+RunLengthTable(i,chapter);
        end
        NormalSequence(chapPos:chapPos+ChapterSlots(chapter)-1) = repmat(RepUnit, NumRepsList(chapter),1);
        chapPos = chapPos + ChapterSlots(chapter);
    end

        % Now make common repeating unit
    commonRepUnitSlots = 1+N*(2+N_EIT); % one cat-1, one cat-2 per TS, N_EIT cat-3 schedules per TS and one cat-3 now/next per TS
    CommonRepUnit = zeros(commonRepUnitSlots,2);

            % One cat-1
    CommonRepUnit(1,1) = 1; % Cat-1

            % One cat-2 for each
    CommonRepUnit(2:2+N-1,1) = 2; % cat-2
    CommonRepUnit(2:2+N-1,2) = DATA_PLPS(1:N)'; % TS index

            % N_EIT cat-3 for each
    for i=0:N-1
        CommonRepUnit(2+N+i*N_EIT:2+N+i*N_EIT+N_EIT-1,:) = repmat([3 DATA_PLPS(i+1)],N_EIT,1);
    end

            % One cat-4 for each
    CommonRepUnit(2+N+N*N_EIT : 2+N+N*N_EIT+N-1,1) = 4;
    CommonRepUnit(2+N+N*N_EIT : 2+N+N*N_EIT+N-1,2) = DATA_PLPS(1:N)';

    % Calculate how many packets to generate

    for ts=1:N
        %------------------------------------------------------------------------------
        % PLP-specific Parameters Definition
        %------------------------------------------------------------------------------
        plp = DATA_PLPS(ts);
        STREAM     = DVBT2.PLP(plp).STREAM;
        START_INT_FRAME_SIG = DVBT2_STATE.DATAGEN.NEXT_INT_FRAME(plp); % First Interleaving Frame to generate
        NUM_INT_FRAMES_SIG = DVBT2.STANDARD.PLP(plp).TOTAL_INT_FRAMES_SIG-START_INT_FRAME_SIG; % Number of Interleving Frames to generate (may be zero)
        O_UPL = STREAM.UPL;

        Sequence = MakeSequence(DVBT2, DVBT2_STATE, plp, TS_RATE, M, NormalSequence, CommonRepUnit);
                
        init = (START_INT_FRAME_SIG==0);
        % Generate data
        data = zeros(O_UPL/8, size(Sequence,1));

        % Make them all Null Packets to begin with
        data(1,:) = hex2dec('47');
        data(2,:) = hex2dec('1f');
        data(3,:) = hex2dec('ff');
        data(4,:) = hex2dec('10'); % 0001 then 4 zeros
        data(5:end,:) = hex2dec('00');

        pktHeaderLen = 32;

        positions = Sequence(:,1)==0 & Sequence(:,2)==ts;
        numPackets = sum(positions);

        % Insert normal data packets for this PLP
        fprintf(FidLogFile,'Making %d normal packets for PLP %d\n',numPackets, plp);
 
        data(:,positions) = t2_tx_dvbt2itudatagen_normalpackets(numPackets, plp, DVBT2, init);

        % Insert cat-1 common packets 

        positions = Sequence(:,1)==1;
        numPackets = sum(positions);

        fprintf(FidLogFile,'Making %d cat-1 packets for PLP %d\n',numPackets, plp);

        data(:,positions) = t2_tx_dvbt2itudatagen_normalpackets(numPackets, plp, DVBT2, init, COMMON_PLP);

        % Insert cat-2 common packets
        positions = find(Sequence(:,1)==2); % Both actual and other
        numPackets = length(positions);
        fprintf(FidLogFile,'Making %d cat-2 packets for PLP %d\n',numPackets, plp);
        data(:,positions) = t2_tx_dvbt2dynvvdatagen_cat2packets(numPackets, Sequence(positions,2)==plp, plp, Sequence(positions,2), DVBT2, init, COMMON_PLP);

        % Insert cat-3 common packets
        positions = find(Sequence(:,1)==3 | Sequence(:,1)==4); % Both actual and other, schedule and present/following
        numPackets = length(positions);
        fprintf(FidLogFile,'Making %d cat-3 packets for PLP %d\n',numPackets, plp);
        data(:,positions) = t2_tx_dvbt2dynvvdatagen_cat3packets(numPackets, Sequence(positions,2)==plp, Sequence(positions,1)==4, plp, Sequence(positions,2), DVBT2, init, COMMON_PLP);

        write_vv_test_point(data, O_UPL/8, inf, vv_fname('00', plp, DVBT2), 'byte', DVBT2, 1, DVBT2.START_T2_FRAME+1)
        write_TS_file(FidLogFile, data(:), tsin_fname(plp, DVBT2), DVBT2.START_T2_FRAME==0)

        fprintf(FidLogFile, 'Splitting packets for plp %d\n',plp);
        % Now apply the splitting model (semi-cheat because we know which types
        % of slot are where)
        nullPositions = Sequence(:,1)==1; % category 1 common packets all get transferred
        nullPositions = nullPositions | (Sequence(:,1)==2 & Sequence(:,2)~=plp); % category 2 (SDT) gets transferred if it's other
        nullPositions = nullPositions | (Sequence(:,1)==3 | Sequence(:,1)==4); % cat 3 and 4 always get transferred

        data(1,nullPositions) = hex2dec('47'); % null packet in data PLP
        data(2,nullPositions) = hex2dec('1f');
        data(3,nullPositions) = hex2dec('ff');
        data(4,nullPositions) = hex2dec('10'); % 0001 then 4 zeros
        data(5:end,nullPositions) = 0; % null packet in data PLP

        write_vv_test_point(data, O_UPL/8, inf, vv_fname('01', plp, DVBT2), 'byte', DVBT2, 1, DVBT2.START_T2_FRAME+1)

        data = data(:);
        DataOut{plp} = data;    

    end

    % Now make the common PLP
    plp = COMMON_PLP;
    
    Sequence = MakeSequence(DVBT2, DVBT2_STATE, plp, TS_RATE, M, NormalSequence, CommonRepUnit);
        
    STREAM     = DVBT2.PLP(plp).STREAM;
    O_UPL = STREAM.UPL;
    START_INT_FRAME_SIG = DVBT2_STATE.DATAGEN.NEXT_INT_FRAME(plp); % First Interleaving Frame to generate
    
    data = zeros(O_UPL/8, size(Sequence,1)); % This will hold the common PLP's packets
    
   
    init = (START_INT_FRAME_SIG==0);
    % Make them all Null Packets to begin with
    data(1,:) = hex2dec('47');
    data(2,:) = hex2dec('1f');
    data(3,:) = hex2dec('ff');
    data(4,:) = hex2dec('10'); % 0001 then 4 zeros
    
    % Insert cat-1 common packets 
    positions = Sequence(:,1)==1;
    numPackets = sum(positions);
    fprintf(FidLogFile,'Making %d cat-1 packets for common PLP %d\n',numPackets, plp);

    data(:,positions) = t2_tx_dvbt2itudatagen_normalpackets(numPackets, plp, DVBT2, init, plp);

    % Insert cat-2 common packets
    positions = find(Sequence(:,1)==2); % Both actual and other
    numPackets = length(positions);
    fprintf(FidLogFile,'Making %d cat-2 packets for common PLP %d\n',numPackets, plp);
    data(:,positions) = t2_tx_dvbt2dynvvdatagen_cat2packets(numPackets, false(numPackets,1), plp, Sequence(positions,2), DVBT2, init);

    % Insert cat-3 common packets
    positions = find(Sequence(:,1)==3 | Sequence(:,1)==4); % Both actual and other, schedule and present/following
    numPackets = length(positions);
    fprintf(FidLogFile,'Making %d cat-3 packets for common PLP %d\n',numPackets, plp);
    data(:,positions) = t2_tx_dvbt2dynvvdatagen_cat3packets(numPackets, false(numPackets,1), Sequence(positions,1)==4, plp, Sequence(positions,2), DVBT2, init);
        
    % Write TP01 for the common
    plp = COMMON_PLP;
    write_vv_test_point(data, O_UPL/8, inf, vv_fname('01', plp, DVBT2), 'byte', DVBT2, 1, DVBT2.START_T2_FRAME+1)
    DataOut{plp} = data(:);
end

for plp=1:NUM_PLPS
    % Keep track of which interleaving frames' data have already been generated
    DVBT2_STATE.DATAGEN.NEXT_INT_FRAME(plp) = DVBT2.STANDARD.PLP(plp).TOTAL_INT_FRAMES_SIG;
end

end

function Sequence = MakeSequence(DVBT2, DVBT2_STATE, plp, TS_RATE, M, NormalSequence, CommonRepUnit)
SF = DVBT2.STANDARD.SF; % sampling frequency
L_F = DVBT2.STANDARD.L_F; % symbols per frame
FEF_LENGTH = DVBT2.FEF_LENGTH;
I_FEF = DVBT2.FEF_INTERVAL;
FEF_ENABLED = DVBT2.FEF_ENABLED;

P_I = DVBT2.PLP(plp).P_I;
I_JUMP = DVBT2.PLP(plp).I_JUMP;
START_INT_FRAME_SIG = DVBT2_STATE.DATAGEN.NEXT_INT_FRAME(plp); % First Interleaving Frame to generate
NUM_INT_FRAMES_SIG = DVBT2.STANDARD.PLP(plp).TOTAL_INT_FRAMES_SIG-START_INT_FRAME_SIG; % Number of Interleving Frames to generate (may be zero)
STREAM = DVBT2.PLP(plp).STREAM;

Tcw = round(1e6*(DVBT2.STANDARD.NFFT * (1 + DVBT2.GI_FRACTION) * L_F + 2048)/SF); % time in us should be exact
Tcw = Tcw * P_I * I_JUMP;
if FEF_ENABLED
    Tcw = Tcw + (P_I * I_JUMP) * FEF_LENGTH /(SF/1e6 * I_FEF);
end

bitsPerCollectionWindow = Tcw * (TS_RATE/1000000); % Input TS Bits per collection window

slotsPerCollectionWindow = ceil(bitsPerCollectionWindow/STREAM.UPL);
startSlot = START_INT_FRAME_SIG*slotsPerCollectionWindow+1;
endSlot = startSlot + NUM_INT_FRAMES_SIG * slotsPerCollectionWindow - 1;

TotalNormalSlots = size(NormalSequence, 1);
commonRepUnitSlots = size(CommonRepUnit, 1);

% Make common/data sequence, allowing for it to repeat
slotIndices = (startSlot:endSlot)-1;
isCommon = mod(slotIndices, M)==0;
dataSlotIndices = (M-1)*floor(slotIndices/M)+mod(slotIndices,M)-1;
dataSlotIndices = mod(dataSlotIndices, TotalNormalSlots);

commonSlotIndices = floor(slotIndices/M);
commonSlotIndices = mod(commonSlotIndices, commonRepUnitSlots);

Sequence = zeros(slotsPerCollectionWindow * NUM_INT_FRAMES_SIG,2);

% Insert the data in the full sequence
Sequence(~isCommon,2) = NormalSequence(dataSlotIndices(~isCommon)+1);

% Insert the data in the full sequence
Sequence(isCommon,:) = CommonRepUnit(commonSlotIndices(isCommon)+1,:);

end


function fname = tsin_fname(plp, DVBT2)
if isempty(DVBT2.SIM.DATAGEN_TS_DIR)
    fname = '';
else
    fname = strcat(DVBT2.SIM.DATAGEN_TS_DIR,filesep,DVBT2.SIM.VV_CONFIG_NAME,'_PLP',int2str(plp),'.ts');
end
end