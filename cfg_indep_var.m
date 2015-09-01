function DVBT2 = cfg_indep_var(DVBT2,Test_Path)
%------------------------------------------------------------------------------
% DVBT2 configuration
%------------------------------------------------------------------------------
% Parameter that controls the length of the simulation (could change to
% NUM_SUPER_FRAMES)
DVBT2.NUM_SIM_T2_FRAMES=         1; % Number of T2-Frames for model to generate (best to make it a multiple of all the P_I x I_JUMP)
DVBT2.START_T2_FRAME =       0; % First T2-frame to generate (to allow generation of large files a frame at a time)

% Specification version
DVBT2.SPEC_VERSION = '1.1.1'; % 1.1.1 is the original blue book, 1.2.1 is with the changes agreed 2008-12-22

% Overall parameters
DVBT2.MODE          =     '8k';  % Mode
DVBT2.EXTENDED      =        0;  % Extended carrier mode: 1=extended 0=normal
DVBT2.GI_FRACTION   =      1/4;
DVBT2.SP_PATTERN    =    'PP1';  % Scattered pilot pattern
DVBT2.L_DATA        =       30;  % Data Symbols per T2-frame
DVBT2.N_T2          =        2;  % Frames per superframe
DVBT2.MISO_ENABLED  =        0;  % 1=MISO enabled 0=MISO disabled
DVBT2.MISO_GROUP    =        1;  % MISO group = 1 or 2
DVBT2.TR_ENABLED    =        0;  % 1=Tone Reservation used, 0=not used
DVBT2.MIXED         =        0;  % mixed frame types
DVBT2.NUM_SUBSLICES =        1;  % subslices per frame
DVBT2.BW            =         8; % Bandwidth in MHz (8, 7, 6 or 5)

DVBT2.L1_CONSTELLATION =  '64-QAM'; % Constellation for L1-post

DVBT2.NETWORK_ID    =     12421; % 0x3085
DVBT2.T2_SYSTEM_ID  =     32769; % 0x8001
DVBT2.FREQUENCY     =     729833333;  % Channel 53, negative offset

DVBT2.NUM_PLPS      =         1;

DVBT2.PLP.BW            =         8; % Bandwidth in MHz (8, 7, 6 or 5)

% per-PLP parameters
DVBT2.PLP(1).CONSTELLATION =  '64-QAM'; % Constellation
DVBT2.PLP(1).CRATE         =     '2/3'; % High priority stream coding rate
DVBT2.PLP(1).FECLEN        =     16200; % either 64800 or 16200
DVBT2.PLP(1).NBLOCKS       =       44; % Number of FEC blocks in one Interleaving Frame 
DVBT2.PLP(1).NUM_BLOCKS_MAX =       44; % Max number of FEC blocks in one Interleaving Frame
DVBT2.PLP(1).NTI           =         3; % Number of TI blocks in Interleaving Frame 
                                        % (if 0 the interleaver is bypassed)
DVBT2.PLP(1).P_I           =         1; % Number of T2-frames to which Interleaving Frame is mapped
DVBT2.PLP(1).I_JUMP        =         1; % Number of T2-frames to skip (not implemented yet)
DVBT2.PLP(1).FIRST_FRAME_IDX =        0; % First frame in which PLP appears (not implemented yet)
DVBT2.PLP(1).ROTCON_BYPASS =         0; % Disable constellation rotation
DVBT2.PLP(1).PLP_ID        =         0;
DVBT2.PLP(1).PLP_GROUP_ID  =         1;
DVBT2.PLP(1).PLP_TYPE      =         1; % 0=common 1=Type 1 2=type 2
DVBT2.PLP(1).IN_BAND_A_FLAG  =         0;
DVBT2.PLP(1).IN_BAND_B_FLAG  =         0;
DVBT2.PLP(1).OTHER_PLP_IN_BAND = []; % List of other PLPs to signal

DVBT2.RX_PLP               =         1; % which PLP to receive (serial number, not PLP_ID)

%------------------------------------------------------------------------------
% Stream Configuration
%------------------------------------------------------------------------------
%DVBT2.PLP(1).STREAM.SIS_MIS =  1; % Single input
%DVBT2.PLP(1).STREAM.CCM_ACM =  1; % CCM (?)
DVBT2.PLP(1).STREAM.ISSYI   =  0; % ISSY active
DVBT2.PLP(1).STREAM.NPD     =  0; % NULL packet deletion active
DVBT2.PLP(1).STREAM.EXT     =  0; % EXT field currently rfu


% Settings for V&V test case
%DVBT2.PLP(1).STREAM.TS_GS   =  3; %TS
%DVBT2.PLP(1).STREAM.UPL     = 188*8; % user packet length: MPEG TS
%DVBT2.PLP(1).STREAM.SYNC    = hex2dec('47'); % user packet sync byte: MPEG TS
%DVBT2.PLP(1).STREAM.MODE    = 1; % high efficiency

% Use these settings for the original PRBS (GCS mode)
DVBT2.PLP(1).STREAM.TS_GS   =  1; %GCS - for the original PRBS
DVBT2.PLP(1).STREAM.UPL     = 0; % user packet length: MPEG TS
DVBT2.PLP(1).STREAM.SYNC    = 0; % user packet sync byte: MPEG TS
DVBT2.PLP(1).STREAM.MODE    = 0; % normal mode
%------------------------------------------------------------------------------
% I/O Configuration
%------------------------------------------------------------------------------

DVBT2.SIM.CSP_VERSION = '019001'; % 1.1.1 is the original blue book, 1.2.1 is with the changes agreed 2008-12-22
DVBT2.SIM.EN_FIGS    = 0;    % Enable figure plotting
DVBT2.SIM.EN_PAUSES  = 1;    % Enable pauses during execution
DVBT2.SIM.SAVE_FIGS  = 0;    % Enable figure saving
DVBT2.SIM.CLOSE_FIGS = 1;    % Close figures after plotting
DVBT2.SIM.SIMDIR     = Test_Path; % Saving directory

DVBT2.SIM.EN_MEX     = 1;    % Enable optimized function

DVBT2.SIM.EN_VV_FILES= 0;
DVBT2.SIM.VV_CONFIG_NAME = '';
DVBT2.SIM_VV_PATH = '';

DVBT2.SIM.OUTPUT_IQ_FILENAME = '';

DVBT2.SIM.PLP(1).RX_BBF_FILENAME = '';  % received BB frame file
DVBT2.SIM.PLP(1).OUTPUT_BBF_FILENAME = ''; % output BB frames
DVBT2.SIM.PLP(1).INPUT_BBF_FILENAME = ''; % output BB frames
DVBT2.SIM.PLP(1).INPUT_TS_FILENAME = '';  % input TS file

%------------------------------------------------------------------------------
% Transmitter parameters
%------------------------------------------------------------------------------

% Enables
DVBT2.TX.ENABLE         = 1; % TX enable
DVBT2.TX.DATAGEN.ENABLE = 1; % Enable/Disable data generation
DVBT2.TX.MADAPT.ENABLE  = 1; % Enable/Disable mode adaption
DVBT2.TX.BBSCRAMBLE.ENABLE  = 1; % Enable/Disable BB scrambler
DVBT2.TX.OCOD.ENABLE    = 1; % Enable/Disable outer-coder block
DVBT2.TX.ICOD.ENABLE    = 1; % Enable/Disable inner-coder block
DVBT2.TX.BINT.ENABLE    = 1; % Enable/Disable bit interleaver
DVBT2.TX.BMAP.ENABLE    = 1; % Enable/Disable bit mapping
DVBT2.TX.MAP.ENABLE     = 1; % Enable/Disable mapper block
DVBT2.TX.CONROT.ENABLE  = 1; % Enable/Disable constellation rotation
DVBT2.TX.CINT.ENABLE    = 1; % Enable/Disable cell interleaver
DVBT2.TX.TINT.ENABLE    = 1; % Enable/Disable time interleaver
DVBT2.TX.DMCELLS.ENABLE = 1; % Enable/Disable dummycell insertion
DVBT2.TX.L1GEN.ENABLE   = 0; % Enable/Disable L1 generation
DVBT2.TX.FBUILD.ENABLE  = 0; % Enable/Disable frame builder
DVBT2.TX.FINT.ENABLE    = 1; % Enable/Disable frequency interleaver
DVBT2.TX.MISO.ENABLE    = 1; % Enable/Disable MISO processing
DVBT2.TX.FADAPT.ENABLE  = 1; % Enable/Disable frame adaptation  block
DVBT2.TX.OFDM.ENABLE    = 1; % Enable/Disable fft block
DVBT2.TX.CP.ENABLE      = 1; % Enable/Disable CP insertion block
DVBT2.TX.P1.ENABLE      = 0; % Enable/Disable P1 insertion block

% I/O Filenames
DVBT2.TX.DATAGEN_FDO = '';     % O: random data generator
DVBT2.TX.MADAPT_FDI  = '';     % I: stream adaptor
DVBT2.TX.MADAPT_FDO  = 'madapt_tx_do';      % O: mode adaptor
DVBT2.TX.BBSCRAMBLE_FDI  = 'madapt_tx_do';      % I: BB scrambler
DVBT2.TX.BBSCRAMBLE_FDO  = '';      % O: BB scrambler
DVBT2.TX.OCOD_FDI    = '';      % I: outer coder
DVBT2.TX.OCOD_FDO    = 'ocoder_tx_do';      % O: outer coder
DVBT2.TX.ICOD_FDI    = 'ocoder_tx_do';      % I: inner coder
DVBT2.TX.ICOD_FDO    = '';  % O: inner coder
DVBT2.TX.BINT_FDI    = '';  % I: bit interleaver
DVBT2.TX.BINT_FDO    = '';        % O: bit interleaver
DVBT2.TX.BMAP_FDI    = '';        % I: bit mapping
DVBT2.TX.BMAP_FDO    = 'bmap_tx_do';        % O: bit mapping
DVBT2.TX.MAP_FDI     = 'bmap_tx_do';        % I: mapper
DVBT2.TX.MAP_FDO     = '';      % O: mapper
DVBT2.TX.CONROT_FDI  = '';      % I: constellation rotation
DVBT2.TX.CONROT_FDO  = '';      % O: constellation rotation
DVBT2.TX.CINT_FDI    = '';      % I: cell interleaver
DVBT2.TX.CINT_FDO    = '';        % O: cell interleaver
DVBT2.TX.TINT_FDI    = '';        % I: time interleaver
DVBT2.TX.TINT_FDO    = '';        % O: time interleaver
DVBT2.TX.DMCELLS_FDI = '';        % I: Dummy Cells Insertion
DVBT2.TX.DMCELLS_FDO = '';     % O: Dummy Cells Insertion 
DVBT2.TX.L1GEN_FDI   = '';                  % I: L1 generator
DVBT2.TX.L1GEN_FDO   = '';                  % O: L1 generator
DVBT2.TX.TXSIGAUXGEN_FDI  = '';       % I: Tx sig aux gen
DVBT2.TX.TXSIGAUXGEN_FDO  = '';      % O: Tx sig aux gen
DVBT2.TX.FBUILD_FDI  = '';                  % I: Frame Builder
DVBT2.TX.FBUILD_FDO  = '';                  % O: Frame Builder
DVBT2.TX.FINT_FDI    = '';     % I: Frequency interleaver
DVBT2.TX.FINT_FDO    = '';        % O: Frequency interleaver 
DVBT2.TX.MISO_FDI    = '';        % I: MISO
DVBT2.TX.MISO_FDO    = '';        % O: MISO
DVBT2.TX.FADAPT_FDI  = '';        % I: frame builder
DVBT2.TX.FADAPT_FDO  = '';      % O: frame builder
DVBT2.TX.OFDM_FDI    = '';      % I: fft
DVBT2.TX.OFDM_FDO    = '';        % O: fft
DVBT2.TX.PAPRTR_FDI  = '';        % I: Tone reservation
DVBT2.TX.PAPRTR_FDO  = '';      % O: Tone reservation
DVBT2.TX.CP_FDI      = '';        % I: CP adder
DVBT2.TX.CP_FDO      = '';             % O: CP adder
DVBT2.TX.FEF_FDI     = '';          % I: FEF inserter
DVBT2.TX.FEF_FDO     = '';         % O: FEF inserter
DVBT2.TX.TX_FDO      = '';             % O: transmitter
DVBT2.TX.P1_FDI      = '';                  % I: P1
DVBT2.TX.P1_FDO      = '';                  % O: P1

% Block type
DVBT2.TX.TYPE         = 'DVBT2BL';   % Transmiter type
DVBT2.TX.DATAGEN.TYPE = 'DVBT2BL';   % Transport stream generator type
DVBT2.TX.MADAPT.TYPE  = 'DVBT2BL';   % Mode adaptor type
DVBT2.TX.BBSCRAMBLE.TYPE  = 'DVBT2BL';   % BB scramble type
DVBT2.TX.OCOD.TYPE    = 'DVBT2BL';   % Outer coder type
DVBT2.TX.ICOD.TYPE    = 'DVBT2BL';   % Inner coder type
DVBT2.TX.BINT.TYPE    = 'DVBT2BL';   % Bit interleaver type
DVBT2.TX.BMAP.TYPE    = 'DVBT2BL';   % Bit mapping type
DVBT2.TX.CONROT.TYPE  = 'DVBT2BL';   % constellation rotation type
DVBT2.TX.CINT.TYPE    = 'DVBT2BL';   % Cell interleaver type
DVBT2.TX.TINT.TYPE    = 'DVBT2BL';   % Time interleaver type
DVBT2.TX.DMCELLS.TYPE = 'DVBT2BL';   % Dummy Cells type
DVBT2.TX.FBUILD.TYPE  = 'DVBT2BL';   % Frame Builder type
DVBT2.TX.L1GEN.TYPE   = 'DVBT2BL';   % L1 generator type
DVBT2.TX.FINT.TYPE    = 'DVBT2BL';   % Frequency interleaver type
DVBT2.TX.MISO.TYPE    = 'DVBT2BL';   % MISO type
DVBT2.TX.MAP.TYPE     = 'DVBT2BL';   % Mapper type
DVBT2.TX.FADAPT.TYPE  = 'DVBT2BL';   % Frame adaptation type
DVBT2.TX.OFDM.TYPE    = 'DVBT2BL';   % OFDM modulator type
DVBT2.TX.CP.TYPE      = 'DVBT2BL';   % Cyclic prefix type
DVBT2.TX.P1.TYPE      = 'DVBT2BL';   % Preamble type

DVBT2.TX.DATAGEN.SEED = 0; % Random number generator seed

% Constellation rotation options
DVBT2.TX.CONROT.EN_CONST_A = 1;                % Enable constellation rot plot
DVBT2.TX.CONROT.CONSTA_FNAME = '_con_rot_a.fig'; % Figure name if saved

%------------------------------------------------------------------------------
% Channel parameters
%------------------------------------------------------------------------------

% Ch Enable
DVBT2.CH.ENABLE       = 1;  % Channel enable
DVBT2.CH.PSCEN.ENABLE = 1;  % Enable/Disable channel convolution
DVBT2.CH.NOISE.ENABLE = 1;  % Enable/Disable noise

% I/O Filenames
DVBT2.CH.CH_FDI    = '';       % I: channel
DVBT2.CH.PSCEN_FDI = '';       % I: propagation scenario
DVBT2.CH.PSCEN_FDO = 'pscen_ch_do'; % O: propagation scenario
DVBT2.CH.NOISE_FDI = 'pscen_ch_do'; % I: noise adder
DVBT2.CH.NOISE_FDO = 'ch_do';       % O: noise adder
DVBT2.CH.CH_FDO    = 'ch_do';       % O channel

% Ch type
DVBT2.CH.TYPE       = 'DVBT'; % Channel type
DVBT2.CH.PSCEN.TYPE = 'DVBT'; % Type of the propagation scenario
DVBT2.CH.NOISE.TYPE = 'DVBT'; % Noise type

% Propagation scenario configuration
DVBT2.CH.PSCEN.SEED        = 1;         % Seed (if 0, random seeds will be used)
DVBT2.CH.PSCEN.CHSTR.TYPE  = 'AWGN';    % AWGN
%DVBT2.CH.PSCEN.CHSTR.TYPE  = 'DVBT-F'; % DVB-T Fixed channel
%DVBT2.CH.PSCEN.CHSTR.TYPE  = 'DVBT-P'; % DVB-T portable channel
%DVBT2.CH.PSCEN.CHSTR.TYPE  = '0DBECHO';
DVBT2.CH.PSCEN.CHSTR.FDMAX = 0;         % Maximum doppler frequency (Hz)

% Noise configuration
DVBT2.CH.NOISE.SNR    = 100;  % SNR (dB) (>100 == without noise)
DVBT2.CH.NOISE.SEED   = 1;    % Seed (if 0, random seeds will be used)

%------------------------------------------------------------------------------
% Receiver parameters
%------------------------------------------------------------------------------

% Enables
DVBT2.RX.ENABLE          = 1; % RX enable
DVBT2.RX.P1.ENABLE       = 0; % Enable/Disable P1
DVBT2.RX.CP.ENABLE       = 1; % Enable/Disable CP remove block
DVBT2.RX.OFDM.ENABLE     = 1; % Enable/Disable fft block
DVBT2.RX.CHE.ENABLE      = 1; % Enable/Disable che block
DVBT2.RX.FADAPT.ENABLE   = 1; % Enable/Disable frame de-adaptation block
DVBT2.RX.MISO.ENABLE     = 1; % Enable/Disable MISO equalisation block
DVBT2.RX.FDINT.ENABLE    = 1; % Enable/Disable frequency de-interleaver
DVBT2.RX.DMCELLS.ENABLE  = 1; % Enable/Disable dummycell extraction
DVBT2.RX.L1DECODE.ENABLE = 1;
DVBT2.RX.FEXTRACT.ENABLE = 0; % Enable/Disable frame extraction
DVBT2.RX.TDINT.ENABLE    = 1; % Enable/Disable bit de-interleaver
DVBT2.RX.CDINT.ENABLE    = 1; % Enable/Disable cell de-interleaver
DVBT2.RX.ROTCON.ENABLE   = 1; % Enable/Disable rot constell de-mapper block
DVBT2.RX.BDMAP.ENABLE    = 1; % Enable/Disable bit de-mapping
DVBT2.RX.BDINT.ENABLE    = 1; % Enable/Disable bit de-interleaver
DVBT2.RX.IDCOD.ENABLE    = 1; % Enable/Disable inner-decoder block
DVBT2.RX.ODCOD.ENABLE    = 0; % Enable/Disable outer-decoder block
DVBT2.RX.SADAPT.ENABLE   = 0; % Enable/Disable stream adaption
DVBT2.RX.BMPALG.ENABLE   = 1; % Enable/Disable BMP algorithm 

% BER enables
DVBT2.RX.BER.DMAP_EN    = 1; % Enable/Disable BER after demaper 
DVBT2.RX.BER.BDINT_EN   = 1; % Enable/Disable BER after bit de-interleaver 
DVBT2.RX.BER.IDCOD_EN   = 1; % Enable/Disable BER after inner decoder
DVBT2.RX.BER.ODCOD_EN   = 0; % Enable/Disable BER after outer decoder
DVBT2.RX.BER.SADAPT_EN  = 0; % Enable/Disable BER after stream adaption

% I/O Filenames
DVBT2.RX.P1_FDI       = '';              % Input file for P1 extraction
DVBT2.RX.P1_FDO       = '';              % Output file for P1 rxtraction
DVBT2.RX.CP_FDI       = 'ch_do';         % I: CP removal block
DVBT2.RX.CP_FDO       = '';      % O: CP removal block
DVBT2.RX.OFDM_FDI     = '';      % I: fft
DVBT2.RX.OFDM_FDO     = '';    % O: fft
DVBT2.RX.CHE_FDI      = '';    % I: Channel estimator
DVBT2.RX.CHE_FDO      = '';     % O: Channel estimator
DVBT2.RX.CHE_FCH      = 'pscen_ch_do';   % ideal Estimation file name
DVBT2.RX.FADAPT_FDI   = '';     % O: frame demodulator
DVBT2.RX.FADAPT_FDO   = '';  % I: frame demodulator
DVBT2.RX.MISO_FDI     = '';  % I: MISO equaliser
DVBT2.RX.MISO_FDO     = '';    % O: MISO equaliser
DVBT2.RX.FDINT_FDI    = '';    % I: frequency de-interleaver
DVBT2.RX.FDINT_FDO    = '';   % O: frequency de-interleaver
DVBT2.RX.DMCELLS_FDI  = '';   % I: Dummy Cells Extraction
DVBT2.RX.DMCELLS_FDO  = ''; % O: Dummy Cells Extraction
DVBT2.RX.L1DECODE_FDI = '';    % I: L1 decode
DVBT2.RX.L1DECODE_FDO = ''; % O:  L1 decode    
DVBT2.RX.FEXTRACT_FDI = '';              % I: Frame Extraction
DVBT2.RX.FEXTRACT_FDO = '';             % O: Frame Extraction
DVBT2.RX.TDINT_FDI    = ''; % I: time deinterleaver
DVBT2.RX.TDINT_FDO    = '';   % O: time deinterleaver
DVBT2.RX.CDINT_FDI    = '';   % I: cell deinterleaver
DVBT2.RX.CDINT_FDO    = '';   % O: cell deinterleaver
DVBT2.RX.ROTCON_FDI   = '';   % I: rot con de-mapper
DVBT2.RX.ROTCON_FDO   = '';  % O: rot con de-mapper
DVBT2.RX.BDMAP_FDI    = '';  % I: bit de-mapper
DVBT2.RX.BDMAP_FDO    = '';   % O: bit de-mapper
DVBT2.RX.BDINT_FDI    = '';   % I: bit de-interleaver
DVBT2.RX.BDINT_FDO    = '';   % O: bit de-interleaver
DVBT2.RX.IDCOD_FDI    = '';   % I: inner-decoder
DVBT2.RX.IDCOD_FDO    = '';   % O: inner-decoder
DVBT2.RX.ODCOD_FDI    = '';   % I: outer-decoder
DVBT2.RX.ODCOD_FDO    = '';   % O: outer-decoder
DVBT2.RX.SADAPT_FDI   = '';   % I: stream adaptor
DVBT2.RX.SADAPT_FDO   = '';         % O: stream adaptor

DVBT2.RX.TYPE          = 'DVBT2BL'; % Receiver type
DVBT2.RX.P1.TYPE       = 'DVBT2BL'; % P1 extraction type
DVBT2.RX.CP.TYPE       = 'DVBT2BL'; % Cyclic prefix removal type
DVBT2.RX.OFDM.TYPE     = 'DVBT2BL'; % OFDM demodulator type
DVBT2.RX.CHE.TYPE      = 'IDEAL';   % Channel estimator type 
DVBT2.RX.FADAPT.TYPE   = 'DVBT2BL'; % Frame adaptation type 
DVBT2.RX.MISO.TYPE     = 'DVBT2BL'; % MISO eq type
DVBT2.RX.FDINT.TYPE    = 'DVBT2BL'; % Frequency de-interleaver type 
DVBT2.RX.DMCELLS.TYPE  = 'DVBT2BL'; % Time deinterleaver type
DVBT2.RX.L1DECODE.TYPE = 'DVBT2BLCHEAT'; % L1 decoder type 
DVBT2.RX.FEXTRACT.TYPE = 'DVBT2BL'; % Frame extract type
DVBT2.RX.TDINT.TYPE    = 'DVBT2BL'; % Time deinterleaver type
DVBT2.RX.CDINT.TYPE    = 'DVBT2BL'; % Cell deinterleaver type
DVBT2.RX.ROTCON.TYPE   = 'DVBT2BL'; % Constellation de-rotation type
DVBT2.RX.BDMAP.TYPE    = 'DVBT2BL'; % Bit demapping type 
DVBT2.RX.BDINT.TYPE    = 'DVBT2BL'; % Bit deinterleaver type 
DVBT2.RX.IDCOD.TYPE    = 'DVBT2BL'; % Inner decoder type
DVBT2.RX.ODCOD.TYPE    = 'DVBT2BL'; % Outer decoder type
DVBT2.RX.SADAPT.TYPE   = 'DVBT2BL'; % Stream adaptor type

% Constellation de-rotation options
DVBT2.RX.ROTCON.EN_CONST_A   = 1;            % Enable constellation rot plot
DVBT2.RX.ROTCON.CONSTA_FNAME = '_con_drot_a.fig'; % Figure name if saved
DVBT2.RX.ROTCON.GA           = 1;            % Enable Genie-Aided Demapper

% Channel estimator options
DVBT2.RX.CHE.EN_HPLOT     = 1;               % Enable channel estimation plot
DVBT2.RX.CHE.HPLOT_FNAME  = '_estim_ch.fig'; % Figure file name if saved
DVBT2.RX.CHE.EN_CONST_B   = 1;               % Enable constellation plot 
                                             % before equalization
DVBT2.RX.CHE.CONSTB_FNAME = '_const_b.fig';  % Figure file name if saved
DVBT2.RX.CHE.EN_CONST_A   = 1;               % Enable constellation plot 
                                             % after equalization
DVBT2.RX.CHE.SYMBS        = [8 10];          % Symbols to be plotted
DVBT2.RX.CHE.CONSTA_FNAME = '_const_a.fig';  % Figure file name if saved

% Decoder options
DVBT2.RX.IDCOD.LDPC_MAXNIT = 50; % max number of iterations 
