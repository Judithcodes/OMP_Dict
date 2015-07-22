function Result = t2_rx_dvbt2blrx(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_rx_dvbt2blrx SYNTAX');
end

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

% Initialize output
Result.BER.DMAP  = NaN;
Result.BER.BDI   = NaN;
Result.BER.IDCOD = NaN;

% P1 extraction
t2_rx_p1preamb_wr(DVBT2, FidLogFile);

% Guard interval
t2_rx_cp_wr(DVBT2, FidLogFile);
  
% FFT
t2_rx_ofdm_wr(DVBT2, FidLogFile);
  
% Channel estimator
t2_rx_che_wr(DVBT2, FidLogFile);
  
% Frame builder
t2_rx_fadapt_wr(DVBT2, FidLogFile);
  
% MISO equalisation
t2_rx_miso_wr(DVBT2, FidLogFile);

% Frequency de-interleaver
t2_rx_freqdint_wr(DVBT2, FidLogFile);

% Dummy Cells Extraction
t2_rx_dmcells_wr(DVBT2, FidLogFile);

% L1 decoding
t2_rx_l1decode_wr(DVBT2, FidLogFile)

% Frame Extraction
t2_rx_fextract_wr(DVBT2, FidLogFile);

% Time deinterleaver
t2_rx_tdint_wr(DVBT2, FidLogFile);

% Cell deinterleaver
t2_rx_cdint_wr(DVBT2, FidLogFile);

% Rotated constellation DeMapper
t2_rx_rotcondmap_wr(DVBT2, FidLogFile);
 
% BER post demaper
Result.BER.DMAP = t2_rx_dvbt2blrx_dmapber(DVBT2, FidLogFile);
%{
% Bit mapping into constellation
t2_rx_bdmap_wr(DVBT2, FidLogFile)

% Bit de-Interleaver
t2_rx_bdint_wr(DVBT2, FidLogFile)

% BER post bit deinterleaver
[Result.BER.BDI] = t2_rx_dvbt2blrx_bdintber(DVBT2, FidLogFile);

% Inner decoder
t2_rx_idcod_wr(DVBT2, FidLogFile); 

% BER post inner decoder
[Result.BER.IDCOD Result.BER.IDCOD_NUMERR Result.BER.IDCOD_NUMERRFECS Result.BER.IDCOD_NUMERRPERFEC] = ...
  t2_rx_dvbt2blrx_idcodber(DVBT2, FidLogFile);

% Outer decoder
t2_rx_odcod_wr(DVBT2, FidLogFile); 

% BER post outer decoder
[Result.BER.ODCOD] = t2_rx_dvbt2blrx_odcodber(DVBT2, FidLogFile);

% Stream adaptor
t2_rx_sadapt_wr(DVBT2, FidLogFile); 
%}
% BER post stream adaptor
Result.BER.SADAPT=[];
[Result.BER.SADAPT] = t2_rx_dvbt2blrx_sadaptber(DVBT2, FidLogFile);

