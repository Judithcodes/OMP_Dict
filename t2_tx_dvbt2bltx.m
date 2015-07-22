function t2_tx_dvbt2bltx(DVBT2, FidLogFile)


%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_tx_dvbt2bltx SYNTAX');
end

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

% Random Transport Stream Generator
t2_tx_datagen_wr(DVBT2, FidLogFile);

% Mode adaptor
t2_tx_madapt_wr(DVBT2, FidLogFile);

% L1 generation
t2_tx_l1gen_wr(DVBT2, FidLogFile);

% BB scrambler
t2_tx_bbscramble_wr(DVBT2, FidLogFile);

% Outer Coder (BCH) 
t2_tx_ocod_wr(DVBT2, FidLogFile);

% Coder 0LDPCs)
t2_tx_icod_wr(DVBT2, FidLogFile); 

% Bit Interleaver
t2_tx_bint_wr(DVBT2, FidLogFile);

% Bit mapping into constellation
t2_tx_bmap_wr(DVBT2, FidLogFile);

% Mapper
t2_tx_map_wr(DVBT2, FidLogFile);

% Constellation rotation & shift
t2_tx_conrot_wr(DVBT2, FidLogFile);

% Cell interleaver
t2_tx_cint_wr(DVBT2, FidLogFile);

% Time interleaver
t2_tx_tint_wr(DVBT2, FidLogFile);

% Dummy Cells insertion
t2_tx_dmcells_wr(DVBT2, FidLogFile);

% Tx-SIG aux stream generation
t2_tx_txsigauxgen_wr(DVBT2, FidLogFile);

% Frame Builder (includes Dummy Cell insertion)
t2_tx_fbuild_wr(DVBT2, FidLogFile);

% Frequency interleaver
t2_tx_freqint_wr(DVBT2, FidLogFile)

% Miso processing
t2_tx_miso_wr(DVBT2, FidLogFile)

% Frame adaptation (pilot insertion)
t2_tx_fadapt_wr(DVBT2, FidLogFile);

% FFT
t2_tx_ofdm_wr(DVBT2, FidLogFile);

% Tone reservation
t2_tx_paprtr_wr(DVBT2, FidLogFile);

% Guard interval
t2_tx_cp_wr(DVBT2, FidLogFile);

% FEF insertion
t2_tx_fef_wr(DVBT2, FidLogFile);

% P1 premable insertion
t2_tx_p1preamb_wr(DVBT2, FidLogFile);
