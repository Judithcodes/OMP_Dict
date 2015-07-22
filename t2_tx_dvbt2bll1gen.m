function DataOut = t2_tx_dvbt2bll1gen(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2bll1gen SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------

NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES;

N_T2  = DVBT2.N_T2; % Number of T2 frames per superframe

NUM_PLPS = DVBT2.NUM_PLPS;
START_T2_FRAME = DVBT2.START_T2_FRAME;

SPEC_VERSION = DVBT2.SPEC_VERSION;
L1_REPETITION_FLAG = DVBT2.L1_REPETITION_FLAG;

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
data = DataIn.data;
SCHED = DataIn.sched;

switch SPEC_VERSION
    case '1.0.1'
        specVersionCode = 0; % this version (the original Blue Book) did not have an official ETSI number
    case '1.1.1'
        specVersionCode = 0; 
    case '1.2.1'
        specVersionCode = 1; 
    case '1.3.1'
        specVersionCode = 2;
end

% TODO - Work out whether T2_BASE_LITE bit can be set (is it T2-base with an allowed
% profile)
%if strcmp(DVBT2.PROFILE, 'T2-BASE')
%    T2MFlag = 0; % TODO: work it out
%else
%    T2MFlag = 0;
%end
% for now just take it from DVBT2 structure
T2BLFlag = DVBT2.L1_T2_BASE_LITE;

%--------------------------------------------------------------------------
% Generate signalling from DVB structure
%--------------------------------------------------------------------------

% ------------- L1 pre-signalling ----------------

numTS = 0;
numGS = 0;
for plp=1:DVBT2.NUM_PLPS
    if (DVBT2.PLP(plp).STREAM.TS_GS == 3) % TS
        numTS = numTS + 1;
    else
        numGS = numGS + 1;
    end
end

if (numGS==0) % TS only
    L1.pre.TYPE = dec2bin(0,8);
elseif (numTS==0)% GS only
    L1.pre.TYPE = dec2bin(1,8);
else % Both TS and GS present
    L1.pre.TYPE = dec2bin(2,8);
end

L1.pre.BWT_EXT = dec2bin(DVBT2.EXTENDED,1);

[S1,S2] = GenerateS1S2(DVBT2);

L1.pre.S1 = dec2bin(S1,3);
L1.pre.S2 = dec2bin(S2, 4);

L1.pre.L1_REPETITION_FLAG = dec2bin(L1_REPETITION_FLAG,1);

GI = find([1/32 1/16 1/8 1/4 1/128 19/128 19/256] == DVBT2.GI_FRACTION, 1, 'first')-1;
L1.pre.GUARD_INTERVAL = dec2bin(GI, 3);
if DVBT2.TR_ENABLED
    L1.pre.PAPR = '0010';
else
    L1.pre.PAPR = '0000';
end

switch(DVBT2.L1_CONSTELLATION)
    case 'BPSK'
        L1.pre.L1_MOD = '0000';
    case 'QPSK'
        L1.pre.L1_MOD = '0001';
    case '16-QAM'
        L1.pre.L1_MOD = '0010';
    case '64-QAM'
        L1.pre.L1_MOD = '0011';
end

L1.pre.L1_COD = dec2bin(0,2);

L1.pre.L1_FEC_TYPE = dec2bin(0,2);
L1.pre.L1_POST_SIZE = dec2bin(250,18); % This will be automatically updated
L1.pre.L1_POST_INFO_SIZE = dec2bin(318,18); % This will be automatically updated

if strcmp(DVBT2.SP_PATTERN, 'NONE') % Just for simulation purposes
  L1.pre.PILOT_PATTERN = dec2bin(0, 4);
else
  L1.pre.PILOT_PATTERN = dec2bin(str2double(DVBT2.SP_PATTERN(3))-1, 4);
end

L1.pre.TX_ID_AVAILABILITY = dec2bin(0,8);
L1.pre.CELL_ID = dec2bin(0,16);
L1.pre.NETWORK_ID = dec2bin(DVBT2.NETWORK_ID,16); 
L1.pre.T2_SYSTEM_ID = dec2bin(DVBT2.T2_SYSTEM_ID,16); 
L1.pre.NUM_T2_FRAMES = dec2bin(DVBT2.N_T2,8);
L1.pre.NUM_DATA_SYMBOLS = dec2bin(DVBT2.L_DATA,12);
L1.pre.REGEN_FLAG = dec2bin(0,3);
if DVBT2.L1_EXT_PADDING_LEN>0
    L1.pre.L1_POST_EXTENSION = '1';
else
    L1.pre.L1_POST_EXTENSION = '0';
end
L1.pre.NUM_RF = dec2bin(1,3);
L1.pre.CURRENT_RF_IDX = dec2bin(0,3);
L1.pre.T2_VERSION = dec2bin(specVersionCode,4);

if (specVersionCode>=2)
    L1.pre.L1_POST_SCRAMBLED = dec2bin(DVBT2.L1_POST_SCRAMBLED,1);
    L1.pre.T2_BASE_LITE = dec2bin(T2BLFlag,1);
else
    L1.pre.L1_POST_SCRAMBLED = 'x';
    L1.pre.T2_BASE_LITE = 'x';
end

L1.pre.RESERVED = 'xxxx';
L1.pre.CRC_32 = dec2bin(0,32);


% ------------- L1 configurable ----------------
L1.config.SUB_SLICES_PER_FRAME = dec2bin(DVBT2.NUM_SUBSLICES,15);
L1.config.NUM_PLP = dec2bin(DVBT2.NUM_PLPS,8);
L1.config.NUM_AUX = dec2bin(DVBT2.NUM_AUX,4);
if (DVBT2.NUM_AUX > 0)
    L1.config.AUX_CONFIG_RFU = DVBT2.AUX_CONFIG_RFU; %Implicit assumption this will exist when NUM_AUX > 0
else
    L1.config.AUX_CONFIG_RFU = dec2bin(0,8);
end


% For each frequency
L1.config.RF_IDX(1,:) = dec2bin(0,3);
L1.config.FREQUENCY(1,:) = dec2bin(DVBT2.FREQUENCY, 32);

% FEFs
if DVBT2.FEF_ENABLED
    L1.config.FEF_TYPE = dec2bin(DVBT2.FEF_TYPE, 4);
    fefLengthBits = dec2bin(DVBT2.FEF_LENGTH, 24);
    L1.config.FEF_LENGTH = fefLengthBits(3:end);
    L1.config.FEF_INTERVAL = dec2bin(DVBT2.FEF_INTERVAL, 8);
else % Fields are absent
    L1.config.FEF_TYPE = '';
    L1.config.FEF_LENGTH = '';
    L1.config.FEF_INTERVAL = '';    
end

% For each PLP
for plp = 1:DVBT2.NUM_PLPS
    L1.config.PLP_ID(plp,:) = dec2bin(DVBT2.PLP(plp).PLP_ID,8);
    L1.config.PLP_TYPE(plp,:) = dec2bin(DVBT2.PLP(plp).PLP_TYPE, 3);

    L1.config.PLP_PAYLOAD_TYPE(plp,:) = dec2bin(DVBT2.PLP(plp).STREAM.TS_GS, 5); % same coding as BBHeader

    L1.config.FF_FLAG(plp,:) = dec2bin(0,1);
    L1.config.FIRST_RF_IDX(plp,:) = dec2bin(0,3);
    L1.config.FIRST_FRAME_IDX(plp,:) = dec2bin(DVBT2.PLP(plp).FIRST_FRAME_IDX,8);
    L1.config.PLP_GROUP_ID(plp,:) = dec2bin(DVBT2.PLP(plp).PLP_GROUP_ID,8);

    switch(DVBT2.PLP(plp).CRATE)
        case '1/2'
            L1.config.PLP_COD(plp,:) = '000'; 
        case '3/5'
            L1.config.PLP_COD(plp,:) = '001'; 
        case '2/3'
            L1.config.PLP_COD(plp,:) = '010'; 
        case '3/4'
            L1.config.PLP_COD(plp,:) = '011'; 
        case '4/5'
            L1.config.PLP_COD(plp,:) = '100'; 
        case '5/6'
            L1.config.PLP_COD(plp,:) = '101'; 
            
            % T2-Lite code rates
        case '1/3'
            L1.config.PLP_COD(plp,:) = '110';
        case '2/5'
            L1.config.PLP_COD(plp,:) = '111';
    end

    switch DVBT2.PLP(plp).CONSTELLATION 
        case 'QPSK'
            L1.config.PLP_MOD(plp,:) = '000';
        case '16-QAM'
            L1.config.PLP_MOD(plp,:) = '001';
        case '64-QAM'
            L1.config.PLP_MOD(plp,:) = '010';
        case '256-QAM'
            L1.config.PLP_MOD(plp,:) = '011';
    end

    L1.config.PLP_ROTATION(plp,:) = dec2bin(~DVBT2.PLP(plp).ROTCON_BYPASS,1);

    if DVBT2.PLP(plp).FECLEN==64800
        L1.config.PLP_FEC_TYPE(plp,:) = dec2bin(1,2);
    else
        L1.config.PLP_FEC_TYPE(plp,:) = dec2bin(0,2);
    end

    L1.config.PLP_NUM_BLOCKS_MAX(plp,:) = dec2bin(DVBT2.PLP(plp).NUM_BLOCKS_MAX,10);
    L1.config.FRAME_INTERVAL(plp,:) = dec2bin(DVBT2.PLP(plp).I_JUMP,8);

    if (DVBT2.PLP(plp).P_I>1)
        L1.config.TIME_IL_LENGTH(plp,:) = dec2bin(DVBT2.PLP(plp).P_I,8);
        L1.config.TIME_IL_TYPE(plp,:) = dec2bin(1,1);
    else
        L1.config.TIME_IL_LENGTH(plp,:) = dec2bin(DVBT2.PLP(plp).NTI,8);
        L1.config.TIME_IL_TYPE(plp,:) = dec2bin(0,1);
    end

    L1.config.IN_BAND_A_FLAG(plp,:) = dec2bin(DVBT2.PLP(plp).IN_BAND_A_FLAG,1);
    L1.config.IN_BAND_B_FLAG(plp,:) = dec2bin(DVBT2.PLP(plp).IN_BAND_B_FLAG,1);
    
    L1.config.RESERVED_1(plp,:) = 'xxxxxxxxxxx';

    if (specVersionCode==0)
        L1.config.PLP_MODE(plp,:) = '00';
    elseif DVBT2.PLP(plp).STREAM.MODE==0
        L1.config.PLP_MODE(plp,:) = '01';
    else
        L1.config.PLP_MODE(plp,:) = '10';
    end
    
    % TODO: is this a good enough check for static scheduling?
    if (specVersionCode>0 && strcmp(DVBT2.TX.MADAPT.TYPE, 'DVBT2BL') && all(diff(DVBT2.PLP(plp).NBLOCKS)==0))
        L1.config.STATIC_FLAG(plp,:) = '1';
    else
        L1.config.STATIC_FLAG(plp,:) = '0';
    end
    
    if (specVersionCode>0 && strcmp(DVBT2.TX.MADAPT.TYPE, 'DVBT2BL')) %TODO: is this a good enough check?
        L1.config.STATIC_PADDING_FLAG(plp,:) = '1';
    else
        L1.config.STATIC_PADDING_FLAG(plp,:) = '0';
    end
    
end

if (specVersionCode >= 2) % 1.3.1 or higher
    if DVBT2.FEF_ENABLED        
        fefLengthBits = dec2bin(DVBT2.FEF_LENGTH, 24);
        L1.config.FEF_LENGTH_MSB = fefLengthBits(1:2); 
    else
        L1.config.FEF_LENGTH_MSB = '00';
    end
else
    L1.config.FEF_LENGTH_MSB = 'xx';
end
L1.config.RESERVED_2 = repmat('x',1,30);

for aux = 1:DVBT2.NUM_AUX
    L1.config.AUX_STREAM_TYPE(aux,:) = dec2bin(DVBT2.AUX(aux).AUX_STREAM_TYPE,4);
    switch DVBT2.AUX(aux).AUX_STREAM_TYPE
        case 0 % TX-SIG aux stream
            AUX_P = dec2bin(DVBT2.AUX(aux).P, 10);
            AUX_Q = dec2bin(DVBT2.AUX(aux).Q, 4);
            AUX_R = dec2bin(DVBT2.AUX(aux).R, 8);
            STATIC_AUX_STREAM_FLAG = dec2bin(DVBT2.AUX(aux).STATIC_AUX_STREAM_FLAG,1);
            RESERVED = dec2bin(0,5);
            L1.config.AUX_PRIVATE_CONF(aux,:) = [AUX_P AUX_Q AUX_R STATIC_AUX_STREAM_FLAG RESERVED];
        otherwise
            L1.config.AUX_PRIVATE_CONF(aux,:) = DVBT2.AUX(aux).AUX_PRIVATE_CONF;
    end
end

%--------------------------------------------------------------------------
%
%--------------------------------------------------------------------------

L1pre = [];
L1post = [];

% matrices for the intermediate testpoints.
L1prebits = [];
L1prepadded = [];
L1prebchout = [];
L1preldpcout = [];
L1prepunctureout = [];
L1postbits = [];
L1postpadded = [];
L1postbchout = [];
L1postldpcout = [];
L1postpunctureout = [];
L1postbitout = [];


for m = START_T2_FRAME:START_T2_FRAME+NUM_SIM_T2_FRAMES-1

    L1.dynamic = makeDynamicBlock(DVBT2,SCHED,m);
    
    if L1_REPETITION_FLAG
        L1.dynamic_next_frame = makeDynamicBlock(DVBT2,SCHED,m+1);
    end
    
    % L1 extension
    if DVBT2.L1_EXT_PADDING_LEN > 0
        fprintf(FidLogFile,'\t\tL1 Extension Padding Enabled (%d bits)\n', DVBT2.L1_EXT_PADDING_LEN); 
        blockDataLen = DVBT2.L1_EXT_PADDING_LEN - 24; % subtract length of block type and block length fields
        assert(blockDataLen>=0);
        L1.extension.block(1).l1_ext_block_type = '11111111';
        L1.extension.block(1).l1_ext_block_len = dec2bin(blockDataLen,16);
        L1.extension.block(1).l1_ext_block_data = repmat('x',1,blockDataLen); % All bits of block data used for bias balancing
    else
        L1.extension.block = [];
    end
        
    % Generate the bit sequences for pre and post
    [L1_pre_bits, L1_post_bits] = t2_tx_dvbt2bll1gen_l1bitgen(L1, DVBT2);

    % encode and modulate it
    if DVBT2.L1_ACE_MAX > 0
        fprintf(FidLogFile,'\t\tL1 ACE Enabled (L1_ACE_MAX=%d)\n', DVBT2.L1_ACE_MAX);
    end
    [frameL1pre, frameL1post, frameL1test] = t2_tx_dvbt2bll1gen_l1coding(L1_pre_bits, L1_post_bits, DVBT2);
    L1pre = [L1pre frameL1pre];
    L1post = [L1post frameL1post];
  
    % Concatenate the intermediate points
    L1prebits = [L1prebits frameL1test.pre.bits];
    L1prepadded = [L1prepadded frameL1test.pre.padded];
    L1prebchout = [L1prebchout frameL1test.pre.bchout];
    L1preldpcout = [L1preldpcout frameL1test.pre.ldpcout];
    L1prepunctureout = [L1prepunctureout frameL1test.pre.punctureout];

    L1postbits = [L1postbits frameL1test.post.bits];
    L1postpadded = [L1postpadded frameL1test.post.padded];
    L1postbchout = [L1postbchout frameL1test.post.bchout];
    L1postldpcout = [L1postldpcout frameL1test.post.ldpcout];
    L1postpunctureout = [L1postpunctureout frameL1test.post.punctureout];
    L1postbitout = [L1postbitout frameL1test.post.bitout];

    fprintf(FidLogFile,'\t\tFrame %d Sum of uncoded L1 bits = %d (of %d bits)\n', ...
        m+1, sum(frameL1test.pre.bits)+sum(frameL1test.post.bits), ...
        length(frameL1test.pre.bits)+length(frameL1test.post.bits));
    fprintf(FidLogFile,'\t\tFrame %d Sum of coded L1 bits = %d (of %d bits)\n', ...
        m+1, sum(frameL1test.pre.punctureout)+sum(frameL1test.post.bitout(:)), ...
        length(frameL1test.pre.punctureout)+length(frameL1test.post.bitout(:)));
    fprintf(FidLogFile,'\t\tFrame %d Sum of modulated L1 cells = %f + %fi (of %d cells)\n', ...
        m+1, real(sum([frameL1pre; frameL1post])), imag(sum([frameL1pre; frameL1post])), ...
        length([frameL1pre; frameL1post]));
        
end

fprintf(FidLogFile,'\t\tT2 Frames of L1 generated = %d frames\n', NUM_SIM_T2_FRAMES);

% Write all the test points
write_vv_test_point(L1prebits, size(L1prebits,1), 1, '20', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1prepadded, size(L1prepadded,1), 1, '21', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1prebchout, size(L1prebchout,1), 1, '22', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1preldpcout, size(L1preldpcout,1), 1, '23', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1prepunctureout, size(L1prepunctureout,1), 1, '24', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1pre, size(L1pre,1), 1, '25', 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1);

write_vv_test_point(L1postbits, size(L1postbits,1), 1, '26', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1postpadded, size(L1postpadded,1), 1, '27', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1postbchout, size(L1postbchout,1), 1, '28', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1postldpcout, size(L1postldpcout,1), 1, '29', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1postpunctureout, size(L1postpunctureout,1), 1, '30', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1postbitout, size(L1postbitout,1), 1, '31', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1post, size(L1post,1), 1, '32', 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1);

DataOut.data = data;
DataOut.l1.pre = L1pre;
DataOut.l1.post = L1post;
DataOut.sched = SCHED;

end

function L1dynamic = makeDynamicBlock(DVBT2,SCHED,m)

    N_T2 = DVBT2.N_T2;
    NUM_PLPS = DVBT2.NUM_PLPS;
    
    L1dynamic.L1_CHANGE_COUNTER = dec2bin(0,8);
    L1dynamic.START_RF_IDX = dec2bin(0,3);
    L1dynamic.RESERVED_1 = 'xxxxxxxx';
    L1dynamic.RESERVED_3 = 'xxxxxxxx';
    for aux = 1:DVBT2.NUM_AUX
        switch DVBT2.AUX(aux).AUX_STREAM_TYPE
            case 0  % TX-SIG Aux Stream
                L = DVBT2.AUX(aux).R+1;
                TX_SIG_FRAME_INDEX = dec2bin(mod(m, L), 8);
                AUX_STREAM_START = dec2bin(SCHED.AUX(aux).START(m+1), 22);
                RESERVED = dec2bin(0,18);
                
                L1dynamic.AUX_PRIVATE_DYN(aux,:) = [TX_SIG_FRAME_INDEX AUX_STREAM_START RESERVED];
                
            otherwise
                L1dynamic.AUX_PRIVATE_DYN(aux,:) = DVBT2.AUX(aux).AUX_PRIVATE_DYN;
        end
    end
        
    % Generate the dynamic fields
    FRAME_IDX = mod(m, N_T2);
    L1dynamic.FRAME_IDX = dec2bin(FRAME_IDX, 8);
    L1dynamic.SUB_SLICE_INTERVAL = dec2bin(SCHED.subsliceIntervals(m+1),22);

    if SCHED.subsliceIntervals(m+1)==0 % no cells in this frame for type 2 PLPs
        type2Start = 0;
    else
        type2Start = SCHED.type2Starts(m+1);
    end
    L1dynamic.TYPE_2_START = dec2bin(type2Start,22);
    
    % Generate the dynamic PLP loop fields
    for plp=1:NUM_PLPS
        FIRST_FRAME_IDX = DVBT2.PLP(plp).FIRST_FRAME_IDX;
        P_I = DVBT2.PLP(plp).P_I;
        I_JUMP = DVBT2.PLP(plp).I_JUMP;

        % current frame
        if mod((m-FIRST_FRAME_IDX), I_JUMP) == 0 % PLP is mapped to this frame
            n = floor((m-FIRST_FRAME_IDX)/(I_JUMP * P_I)); % Interleaving frame index
            start = SCHED.startAddresses(plp,m+1);
            nblocks = SCHED.NBLOCKS{plp}(n+1);
            if (nblocks == 0)
                start = 0;
            end
        else
            start = 0;
            nblocks = 0;
        end
        L1dynamic.PLP_ID(plp,:) = dec2bin(DVBT2.PLP(plp).PLP_ID,8);
        L1dynamic.RESERVED_2(plp,:) = 'xxxxxxxx';
        L1dynamic.PLP_START(plp,:) = dec2bin(start,22);
        L1dynamic.PLP_NUM_BLOCKS(plp,:) = dec2bin(nblocks,10);
    end
end
