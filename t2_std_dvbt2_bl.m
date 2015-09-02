function STD = t2_std_dvbt2_bl(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_std_dvbt2_bl SYNTAX');
end

% parameters which are now derived from the other DVBT2 fields. These
% should be replaced 

%------------------------------------------------------------------------------
% Standard definitions
%------------------------------------------------------------------------------

% Timing
STD.SF = 2048/224e-6; % Sampling frequency
switch DVBT2.BW
  case 8    
    STD.SF = 64e6/7;
  case 7
    STD.SF = 56e6/7;
  case 6
    STD.SF = 48e6/7;
  case 5  
    STD.SF = 40e6/7;
  otherwise, error('t2_std_config_wr UNKNOWN BANDWIDTH');
end
    
switch DVBT2.MODE 
  case '1k'
    STD.TU = 1024 / STD.SF; % Length in s of the OFDM symbol data part
  case '2k'
    STD.TU = 2048 / STD.SF; % Length in s of the OFDM symbol data part
  case '4k'
    STD.TU = 4096 / STD.SF; % Length in s of the OFDM symbol data part
  case '8k',  
    STD.TU = 8192 / STD.SF; % Length in s of the OFDM symbol data part
  case '16k',  
    STD.TU = 16384 / STD.SF; % Length in s of the OFDM symbol data part
  case '32k',  
    STD.TU = 32768 / STD.SF; % Length in s of the OFDM symbol data part
  otherwise, error('t2_std_config_wr UNKNOWN MODE');
end
STD.TG = STD.TU * DVBT2.GI_FRACTION; % Length in s of the cyclic prefix

STD.TS = STD.TU + STD.TG; % OFDM symbol duration
  
for plp = 1:DVBT2.NUM_PLPS
    % FEC block length
    switch DVBT2.PLP(plp).FECLEN
      case 16200
        switch DVBT2.PLP(plp).CRATE
          case '1/3',
            Q = 30;
            CR = 1/3;
            K_BCH = 5232;
            N_BCH = 5400;
          case '2/5'
            Q = 27;
            CR = 2/5;
            K_BCH = 6312;
            N_BCH = 6480;            
          case '1/2',
            Q = 25;
            CR=4/9;
            K_BCH = 7032;
            N_BCH = 7200;
          case '3/5',
            Q = 18;
            CR=3/5;
            K_BCH = 9552;
            N_BCH = 9720;
          case '2/3',
            Q = 15;
            CR=2/3;
            K_BCH = 10632;
            N_BCH = 10800;
          case '3/4',
            Q = 12;
            CR=11/15;
            K_BCH = 11712;
            N_BCH = 11880;
         case '4/5',
            Q = 10;
            CR=7/9;
            K_BCH = 12432;
            N_BCH = 12600;
          case '5/6',
            Q = 8;
            CR=37/45;
            K_BCH = 13152;
            N_BCH = 13320;             
          otherwise
            error('t2_std_dvbt2_bl UNKNOWN CODING RATE');
        end
      case 64800
        % Coding rate
        switch DVBT2.PLP(plp).CRATE
          case '1/2',
            Q = 90;
            CR=1/2;
            K_BCH = 32208;
            N_BCH = 32400;
          case '3/5',
            Q = 72;
            CR=3/5;
            K_BCH = 38688;
            N_BCH = 38880;
          case '2/3',
            Q = 60;
            CR=2/3;
            K_BCH = 43040;
            N_BCH = 43200;
         case '3/4',
            Q = 45;
            CR=3/4;
            K_BCH = 48408;
            N_BCH = 48600;
         case '4/5',
            Q = 36;
            CR=4/5;
            K_BCH = 51648;
            N_BCH = 51840;
          case '5/6',
            Q = 30;
            CR=5/6;
            K_BCH = 53840;
            N_BCH = 54000;
         otherwise
            error('t2_std_dvbt2_bl UNKNOWN CODING RATE');
        end
      otherwise
        error('t2_std_dvbt2_bl UNKNOWN FEC BLOCK LENGTH');
    end

    % Get NumParityBits
    if DVBT2.PLP(plp).FECLEN == 64800
        switch CR
            case {1/2, 3/5, 3/4, 4/5}
                TErr = 12;
            case {2/3, 5/6}
                TErr = 10;
        end
        NumBCHParityBits = 16 * TErr;
    else
        TErr = 12;
        NumBCHParityBits = 14 * TErr;
    end

    % Define BCH polynomials (Table 6a & 6b)
    if DVBT2.PLP(plp).FECLEN == 64800
        % Non-zero powers (besides 0 and 16)
        nzp = {[2 3 5]                       ... g1
               [1 4 5 6 8]                   ... g2
               [2 3 4 5 7 8 9 10 11]         ... g3
               [2 4 6 9 11 12 14]            ... g4
               [1 2 3 5 8 9 10 11 12]        ... g5
               [2 4 5 7 8 9 10 12 13 14 15]  ... g6
               [2 5 6 8 9 10 11 13 15]       ... g7
               [1 2 5 6 8 9 12 13 14]        ... g8
               [5 7 9 10 11]                 ... g9
               [1 2 5 7 8 10 12 13 14]       ... g10
               [2 3 5 9 11 12 13]            ... g11
               [1 5 6 7 9 11 12]};           ... g12
        g = zeros([12 16+1]);
        for n = 1:12
            g(n,[1 nzp{n}+1 end]) = 1;
        end
    else
        % Non-zero powers (besides 0 and 14)
        nzp = {[1 3 5]                  ... g1
               [6 8 11]                 ... g2
               [1 2 6 9 10]             ... g3
               [4 7 8 10 12]            ... g4
               [2 4 6 8 9 11 13]        ... g5
               [3 7 8 9 13]             ... g6
               [2 5 6 7 10 11 13]       ... g7
               [5 8 9 10 11]            ... g8
               [1 2 3 9 10]             ... g9
               [3 6 9 11 12]            ... g10
               [4 11 12]                ... g11
               [1 2 3 5 6 7 8 10 13]};  ... g12
        g = zeros([12 14+1]);
        for n = 1:12
            g(n,[1 nzp{n}+1 end]) = 1;
        end
    end
    % Compute the generator polynomial by multiplying the first TErr BCH polynomials
    % Polynomial multiplication is a convolution
    Poly = gf(g(1,:),1);
    for n = 2:TErr
        Poly = conv(Poly, gf(g(n,:),1));
    end
    BCH_GEN = fliplr(logical(Poly.x));
    % Check if the degree of the generator polynomial is equal with the number of parity bits
    assert(length(BCH_GEN)-1 == NumBCHParityBits);

    STD.PLP(plp).ICOD.CR = CR;
    STD.PLP(plp).ICOD.Q = Q; % the Q number of the code
    STD.PLP(plp).ICOD.S = 360; % the parallelism of the codes
    STD.PLP(plp).ICOD.H =t2_std_dvbt2_bl_ldpc(CR,DVBT2.PLP(plp).FECLEN, DVBT2.SPEC_VERSION);
    STD.PLP(plp).OCOD.K_BCH = K_BCH;
    STD.PLP(plp).OCOD.N_BCH = N_BCH;
    STD.PLP(plp).OCOD.T_ERR = TErr;
    STD.PLP(plp).OCOD.BCH_GEN = BCH_GEN;  

    % Calculate length of in-band signalling (if used)
    if DVBT2.PLP(plp).IN_BAND_A_FLAG
        IN_BAND_A_LEN = 36 + 77*DVBT2.PLP(plp).P_I + 48*length(DVBT2.PLP(plp).OTHER_PLP_IN_BAND);
    else
        IN_BAND_A_LEN = 0;
    end
    
    if DVBT2.PLP(plp).IN_BAND_B_FLAG
        IN_BAND_B_LEN = 102;
    else
        IN_BAND_B_LEN = 0;
    end
    IN_BAND_LEN = IN_BAND_A_LEN + IN_BAND_B_LEN;
        
    STD.PLP(plp).IN_BAND_A_LEN = IN_BAND_A_LEN;
    STD.PLP(plp).IN_BAND_B_LEN = IN_BAND_B_LEN;
    STD.PLP(plp).IN_BAND_LEN = IN_BAND_LEN;
    
    % Mapper parameters
    switch DVBT2.PLP(plp).CONSTELLATION
      case 'QPSK'
        C_POINTS = [1+1i 1-1i -1+1i -1-1i]; % Constellation points
        C        = sqrt(2);                 % Normalization factor
        V        = 2;                       % Bits per cell       
      case '16-QAM'
        C_POINTS = [3+3i 3+i 1+3i 1+i 3-3i 3-i 1-3i 1-i -3+3i -3+i -1+3i ...
                    -1+i -3-3i -3-i -1-3i -1-i];
        C        = sqrt(10);
        V        = 4;                          
      case '64-QAM'
        C_POINTS = [7+7i 7+5i 5+7i 5+5i 7+1i 7+3i 5+1i 5+3i 1+7i 1+5i 3+7i ...
                    3+5i 1+1i 1+3i 3+1i 3+3i 7-7i 7-5i 5-7i 5-5i 7-1i 7-3i ...
                    5-1i 5-3i 1-7i 1-5i 3-7i 3-5i 1-1i 1-3i 3-1i 3-3i -7+7i ...
                    -7+5i -5+7i -5+5i -7+1i -7+3i -5+1i -5+3i -1+7i -1+5i ... 
                    -3+7i -3+5i -1+1i -1+3i -3+1i -3+3i -7-7i -7-5i -5-7i ...
                    -5-5i -7-1i -7-3i -5-1i -5-3i -1-7i -1-5i -3-7i -3-5i ...
                    -1-1i -1-3i -3-1i -3-3i];
        C        = sqrt(42);
        V        = 6;    
      case '256-QAM'
        C_POINTS = [ +15+15i, +15+13i, +13+15i, +13+13i, +15+9i, +15+11i, +13+9i, +13+11i, ...
                     +9+15i, +9+13i, +11+15i, +11+13i, +9+9i, +9+11i, +11+9i, +11+11i, ...
                     +15+1i, +15+3i, +13+1i, +13+3i, +15+7i, +15+5i, +13+7i, +13+5i, ...
                     +9+1i, +9+3i, +11+1i, +11+3i, +9+7i, +9+5i, +11+7i, +11+5i, ...
                     +1+15i, +1+13i, +3+15i, +3+13i, +1+9i, +1+11i, +3+9i, +3+11i, ...
                     +7+15i, +7+13i, +5+15i, +5+13i, +7+9i, +7+11i, +5+9i, +5+11i, ...
                     +1+1i, +1+3i, +3+1i, +3+3i, +1+7i, +1+5i, +3+7i, +3+5i, ...
                     +7+1i, +7+3i, +5+1i, +5+3i, +7+7i, +7+5i, +5+7i, +5+5i, ...
                     +15-15i, +15-13i, +13-15i, +13-13i, +15-9i, +15-11i, +13-9i, +13-11i, ...
                     +9-15i, +9-13i, +11-15i, +11-13i, +9-9i, +9-11i, +11-9i, +11-11i, ...
                     +15-1i, +15-3i, +13-1i, +13-3i, +15-7i, +15-5i, +13-7i, +13-5i, ...
                     +9-1i, +9-3i, +11-1i, +11-3i, +9-7i, +9-5i, +11-7i, +11-5i, ...
                     +1-15i, +1-13i, +3-15i, +3-13i, +1-9i, +1-11i, +3-9i, +3-11i, ...
                     +7-15i, +7-13i, +5-15i, +5-13i, +7-9i, +7-11i, +5-9i, +5-11i, ...
                     +1-1i, +1-3i, +3-1i, +3-3i, +1-7i, +1-5i, +3-7i, +3-5i, ...
                     +7-1i, +7-3i, +5-1i, +5-3i, +7-7i, +7-5i, +5-7i, +5-5i, ...
                     -15+15i, -15+13i, -13+15i, -13+13i, -15+9i, -15+11i, -13+9i, -13+11i, ...
                     -9+15i, -9+13i, -11+15i, -11+13i, -9+9i, -9+11i, -11+9i, -11+11i, ...
                     -15+1i, -15+3i, -13+1i, -13+3i, -15+7i, -15+5i, -13+7i, -13+5i, ...
                     -9+1i, -9+3i, -11+1i, -11+3i, -9+7i, -9+5i, -11+7i, -11+5i, ...
                     -1+15i, -1+13i, -3+15i, -3+13i, -1+9i, -1+11i, -3+9i, -3+11i, ...
                     -7+15i, -7+13i, -5+15i, -5+13i, -7+9i, -7+11i, -5+9i, -5+11i, ...
                     -1+1i, -1+3i, -3+1i, -3+3i, -1+7i, -1+5i, -3+7i, -3+5i, ...
                     -7+1i, -7+3i, -5+1i, -5+3i, -7+7i, -7+5i, -5+7i, -5+5i, ...
                     -15-15i, -15-13i, -13-15i, -13-13i, -15-9i, -15-11i, -13-9i, -13-11i, ...
                     -9-15i, -9-13i, -11-15i, -11-13i, -9-9i, -9-11i, -11-9i, -11-11i, ...
                     -15-1i, -15-3i, -13-1i, -13-3i, -15-7i, -15-5i, -13-7i, -13-5i, ...
                     -9-1i, -9-3i, -11-1i, -11-3i, -9-7i, -9-5i, -11-7i, -11-5i, ...
                     -1-15i, -1-13i, -3-15i, -3-13i, -1-9i, -1-11i, -3-9i, -3-11i, ...
                     -7-15i, -7-13i, -5-15i, -5-13i, -7-9i, -7-11i, -5-9i, -5-11i, ...
                     -1-1i, -1-3i, -3-1i, -3-3i, -1-7i, -1-5i, -3-7i, -3-5i, ...
                     -7-1i, -7-3i, -5-1i, -5-3i, -7-7i, -7-5i, ...
                     -5-7i, -5-5i ];

        C        = sqrt(170);
        V        = 8;        
      otherwise, error('t2_std_dvbt2_bl UNKNOWN CONSTELLATION');
    end

    STD.PLP(plp).MAP.V        = V;
    STD.PLP(plp).MAP.C_POINTS = C_POINTS/C;
    STD.PLP(plp).MAP.C        = C;

end

% OFDM Symbols
switch DVBT2.MODE
  case '1k'
    C_PS   = 853 - 0*2;        % Number of carriers per symbol
    NFFT   = 1024;       % FFT number of points 
    N_P2   = 16;         % Number of P2 symbols
    K_EXT  = 0;          % extra carriers on each side in ext carrier mode
  case '2k'
    C_PS   = 1705;       % Number of carriers per symbol
    NFFT   = 2048;       % FFT number of points
    N_P2   = 8;          % Number of P2 symbols
    K_EXT  = 0;          % extra carriers on each side in ext carrier mode
  case '4k'
    C_PS   = 3409;       % Number of carriers per symbol
    NFFT   = 4096;       % FFT number of points    
    N_P2   = 4;          % Number of P2 symbols
    K_EXT  = 0;          % extra carriers on each side in ext carrier mode
  case '8k' 
    C_PS   = 6817;       % Number of carriers per symbol
    NFFT   = 8192;       % FFT number of points       
    N_P2   = 2;          % Number of P2 symbols
    K_EXT  = 48;         % extra carriers on each side in ext carrier mode

  case '16k' 
    C_PS   = 13633;      % Number of carriers per symbol
    NFFT   = 16384;      % FFT number of points       
    N_P2   = 1;          % Number of P2 symbols
    K_EXT  = 144;        % extra carriers on each side in ext carrier mode

  case '32k' 
    C_PS   = 27265;      % Number of carriers per symbol
    NFFT   = 32768;      % FFT number of points       
    N_P2   = 1;          % Number of P2 symbols
    K_EXT  = 288;        % extra carriers on each side in ext carrier mode

  otherwise, error('t2_std_dvbt2_bl UNKNOWN MODE');
end

if DVBT2.EXTENDED, C_PS = C_PS + 2*K_EXT; end % add K_EXT carriers on each side in extended mode

C_LOC = NFFT/2-(C_PS-1)/2+1:NFFT/2+(C_PS-1)/2+1; % calculate FFT bins for used carriers

% Number of Frame Closing Symbols, i.e. 0 or 1:
L_FC  = t2_std_dvbt2_bl_fc_use(DVBT2.MODE, DVBT2.GI_FRACTION, DVBT2.SP_PATTERN, DVBT2.MISO_ENABLED);

if ~DVBT2.TX.FBUILD.ENABLE && DVBT2.TX.DMCELLS.ENABLE
  N_P2 = 0;
  L_FC = 0;
end 

STD.C_PS  = C_PS;
STD.C_LOC = C_LOC;  
STD.NFFT  = NFFT;
STD.N_P2  = N_P2;
STD.L_FC  = L_FC;
STD.L_F   = DVBT2.L_DATA + N_P2;
STD.K_EXT = K_EXT;
STD.P1LEN = 2048;

% PN Sequence (Frame level sequence used to modulate
% reference signals)
% This sequence is described in the spec. (Version 0.5.8) in hexadecimal
% form:

PN_SEQ_HEX = [ ...
'4DC2AF7BD8C3C9A1E76C9A090AF1C3114F07FCA2808E9462E9AD7B712D6F4AC8A59BB069CC50BF1', ...
'149927E6BB1C9FC8C18BB949B30CD09DDD749E704F57B41DEC7E7B176E12C5657432B51B0B812DF', ...
'0E14887E24D80C97F09374AD76270E58FE1774B2781D8D3821E393F2EA0FFD4D24DE20C05D0BA170', ...
'3D10E52D61E013D837AA62D007CC2FD76D23A3E125BDE8A9A7C02A98B70251C556F6341EBDECB80', ...
'1AAD5D9FB8CBEA80BB619096527A8C475B3D8DB28AF8543A00EC3480DFF1E2CDA9F985B523B8790', ...
'07AA5D0CE58D21B18631006617F6F769EB947F924EA5161EC2C0488B63ED7993BA8EF4E552FA32FC', ...
'3F1BDB19923902BCBBE5DDABB824126E08459CA6CFA0267E5294A98C632569791E60EF659AEE9518', ...
'CDF08D87833690C1B79183ED127E53360CD86514859A28B5494F51AA4882419A25A2D01A5F47AA273', ...
'01E79A5370CCB3E197F'];

% Convert to a binary array
PN_SEQ = [];

for hexIndex = 1:length(PN_SEQ_HEX)
    
    binString = dec2bin(hex2dec(PN_SEQ_HEX(hexIndex)), 4);
    
    for binIndex = 1:4
        PN_SEQ = [PN_SEQ, str2num(binString(binIndex))];
    end
    
end

STD.PN_SEQ = PN_SEQ;

baseFrameLen = length(PN_SEQ)*4;    % number of symbols in a '1k' frame

%switch DVBT2.MODE
%    case {'1k', '2k', '4k', '8k', '16k', '32k'}
%        S_PF = baseFrameLen/str2num(DVBT2.MODE(1:(length(DVBT2.MODE)-1))); 
        
%    otherwise, error('t2_std_dvbt2_bl UNKNOWN MODE');
%end

%STD.S_PF = S_PF; % Number of symbols per frame

% Tone reservation locations
if strcmp(DVBT2.SP_PATTERN, 'NONE')
    % 'NONE' is not a real DVB-T2 option, but will switch off all pilots
    % and Tone Reservation
    P2_TR_LOC = [];
    NORMAL_TR_LOC = [];
else
    [P2_TR_LOC, NORMAL_TR_LOC] = t2_std_dvbt2_bl_trloc(DVBT2.MODE);
end

STD.P2_TR_LOC = P2_TR_LOC; % always reserved

if DVBT2.TR_ENABLED
    STD.TR_LOC = NORMAL_TR_LOC; % TODO real locations
    STD.FC_TR_LOC = STD.P2_TR_LOC; % Frame Closing symbol uses P2 TR locations
else
    STD.TR_LOC = [];
    STD.FC_TR_LOC = [];
end

if strcmp(DVBT2.SP_PATTERN, 'NONE')
  STD.SP_LOC = [];
  STD.SP_PATTLEN = 0;
  STD.SP_DX = 0;
  STD.CP_LOC=[];
  STD.EDGE_LOC = [];
  
  STD.P2P_LOC = [];
  STD.FCP_LOC = [];
  spLoc = [];
else
  [STD.SP_LOC, STD.SP_PATTLEN, STD.SP_DX] = t2_std_dvbt2_bl_scatloc(STD.C_PS, DVBT2.SP_PATTERN, DVBT2.EXTENDED, STD.K_EXT);
  STD.CP_LOC = t2_std_dvbt2_bl_contloc(DVBT2.MODE, DVBT2.EXTENDED, DVBT2.SP_PATTERN);
  STD.EDGE_LOC = t2_std_dvbt2_bl_edgeloc(STD.C_PS);

  STD.P2P_LOC = t2_std_dvbt2_bl_p2ploc(DVBT2.MODE, STD.C_PS, STD.K_EXT, STD.P2_TR_LOC, DVBT2.SP_PATTERN, DVBT2.EXTENDED, DVBT2.MISO_ENABLED); % also depends on MISO
  STD.FCP_LOC = t2_std_dvbt2_bl_fcploc(DVBT2.MODE, STD.C_PS, DVBT2.SP_PATTERN, DVBT2.EXTENDED);
  spLoc = STD.SP_LOC(1, find(STD.SP_LOC(1,:)));
end

% Calculate number of data carriers per symbol
    % P2 symbols
symbol = zeros(1, C_PS);
symbol(STD.P2P_LOC) = 1;
if (DVBT2.EXTENDED)
    symbol(STD.P2_TR_LOC + STD.K_EXT) = 1;
else
    symbol(STD.P2_TR_LOC) = 1;
end
STD.C_P2 = length(find(symbol==0));

if DVBT2.NoP2Data == 1
    STD.C_P2 = 1045;     %%% Number symbols used for L1 signaling in each frame. May depend on factors Confirm
end

    % Normal symbols
symbol = zeros(1, C_PS);
symbol(spLoc) = 1;
%{
         spLocLeft = spLoc-1;
         spLocLeft = spLocLeft(2:length(spLocLeft));
         spLocRight = spLoc+1;
         spLocRight = spLocRight(1:length(spLocRight)-1);
         symbol(spLocLeft) = 1;
         symbol(spLocRight) = 1;
%}
symbol(STD.CP_LOC) = 1;
symbol(STD.EDGE_LOC) = 1;
symbol(STD.TR_LOC) = 1;
dcLoc = find(symbol==0);
STD.C_DATA = length(dcLoc)-1;

    % Frame closing symbols
symbol = zeros(1, C_PS);
symbol(STD.FCP_LOC) = 1;
%{
         FCP_LOCLeft = STD.FCP_LOC-1;
         FCP_LOCLeft = FCP_LOCLeft(2:length(FCP_LOCLeft));
         FCP_LOCRight = STD.FCP_LOC+1;
         FCP_LOCRight = FCP_LOCRight(1:length(FCP_LOCRight)-1);
         symbol(FCP_LOCLeft) = 1;
         symbol(FCP_LOCRight) = 1;
%}
symbol(STD.EDGE_LOC) = 1;
symbol(STD.FC_TR_LOC) = 1;
STD.N_FC = length(find(symbol==0));

if (strcmp(DVBT2.SP_PATTERN, 'NONE'))
    STD.C_FC = STD.N_FC;
else
    STD.C_FC = t2_std_dvbt2_bl_c_fc(DVBT2.MODE, DVBT2.EXTENDED, DVBT2.SP_PATTERN, STD.FC_TR_LOC); % number of active cells in FCS (excluding thinning cells) N_FC>C_FC
end

% Calculations for L1 data length - this duplicates some calculations done
% in the L1 generation block
L1ConfigLength = 35 + 1*35 + DVBT2.FEF_ENABLED*34 + 89*DVBT2.NUM_PLPS + 32 + DVBT2.NUM_AUX*32;
L1DynamicLength = 71 + 48*DVBT2.NUM_PLPS + 8 + DVBT2.NUM_AUX*48;

if (DVBT2.L1_REPETITION_FLAG == 1)
    L1DynamicRepetitionLength = L1DynamicLength;
else
    L1DynamicRepetitionLength = 0;
end

L1ExtensionLength = DVBT2.L1_EXT_PADDING_LEN;
post_info_size = L1ConfigLength + L1DynamicLength + L1DynamicRepetitionLength + L1ExtensionLength;

switch DVBT2.L1_CONSTELLATION
    case 'BPSK'
        eta_mod = 1;
    case 'QPSK'
        eta_mod = 2;
    case '16-QAM'
        eta_mod = 4;
    case '64-QAM'
        eta_mod = 6;
end
        
L1.pre.L1_POST_INFO_SIZE = dec2bin(post_info_size,18);
K_bch = 7032;
K_post_ex_pad = post_info_size + 32;
N_post_FEC_block = ceil(K_post_ex_pad / K_bch);
K_L1_PADDING = ceil(K_post_ex_pad / N_post_FEC_block) * N_post_FEC_block - K_post_ex_pad;
K_post = K_post_ex_pad + K_L1_PADDING;
K_sig = K_post / N_post_FEC_block;
N_punc_temp = floor(6 / 5 * (K_bch - K_sig));
N_bch_parity = 168;
N_post_temp = K_sig + N_bch_parity + 9000 - N_punc_temp;

if N_P2 == 1
    N_post = ceil(N_post_temp / (2*eta_mod)) * 2*eta_mod;
else
    N_post = ceil(N_post_temp / (eta_mod * N_P2)) * eta_mod * N_P2;
end

N_punc = N_punc_temp - (N_post - N_post_temp);
N_mod_per_block = N_post / eta_mod;
N_mod_total = N_mod_per_block * N_post_FEC_block;
STD.D_L1PRE = 1840; % Number of L1-pre signalling cells per T2 frame
STD.D_L1POST = N_mod_total; % Number of L1-post signalling cells per T2 frame TODO: calculate correct number
STD.N_POST_FEC_BLOCK = N_post_FEC_block;
STD.N_POST = N_post;
STD.N_PUNC_POST = N_punc;
STD.N_POST_INFO_SIZE = post_info_size;
STD.K_SIG_POST = K_sig;



% P1 tables

% CDS LUT
% active carriers index (range 0:852)
STD.AC_IDX = [44 45 47 51 54 59 62 64 65 66 70 75 78 80 81 82 84 85 87 ...
              88 89 90 94 96 97 98 102 107 110 112 113 114 116 117 119 ...
              120 121 122 124 125 127 131 132 133 135 136 137 138 142 ...
              144 145 146 148 149 151 152 153 154 158 160 161 162 166 ...
              171 172 173 175 179 182 187 190 192 193 194 198 203 206 ...
              208 209 210 212 213 215 216 217 218 222 224 225 226 230 ...
              235 238 240 241 242 244 245 247 248 249 250 252 253 255 ...
              259 260 261 263 264 265 266 270 272 273 274 276 277 279 ...
              280 281 282 286 288 289 290 294 299 300 301 303 307 310 ...
              315 318 320 321 322 326 331 334 336 337 338 340 341 343 ...
              344 345 346 350 352 353 354 358 363 364 365 367 371 374 ...
              379 382 384 385 386 390 395 396 397 399 403 406 411 412 ...
              413 415 419 420 421 423 424 425 426 428 429 431 435 438 ...
              443 446 448 449 450 454 459 462 464 465 466 468 469 471 ...
              472 473 474 478 480 481 482 486 491 494 496 497 498 500 ...
              501 503 504 505 506 508 509 511 515 516 517 519 520 521 ...
              522 526 528 529 530 532 533 535 536 537 538 542 544 545 ...
              546 550 555 558 560 561 562 564 565 567 568 569 570 572 ...
              573 575 579 580 581 583 584 585 586 588 589 591 595 598 ...
              603 604 605 607 611 612 613 615 616 617 618 622 624 625 ...
              626 628 629 631 632 633 634 636 637 639 643 644 645 647 ...
              648 649 650 654 656 657 658 660 661 663 664 665 666 670 ...
              672 673 674 678 683 684 689 692 696 698 699 701 702 703 ...
              704 706 707 708 712 714 715 717 718 719 720 722 723 725 ...
              726 727 729 733 734 735 736 738 739 740 744 746 747 748 ...
              753 756 760 762 763 765 766 767 768 770 771 772 776 778 ...
              779 780 785 788 792 794 795 796 801 805 806 807 809];

% MSS LUTs (Hex format)
STD.MSS1_HEX = ['124721741D482E7B';  % 000
                '47127421481D7B2E';  % 001
                '217412472E7B1D48';  % 010
                '742147127B2E481D';  % 011
                '1D482E7B12472174';  % 100
                '481D7B2E47127421';  % 101
                '2E7B1D4821741247';  % 110
                '7B2E481D74214712']; % 111

STD.MSS2_HEX = ['121D4748212E747B1D1248472E217B7412E247B721D174841DED48B82EDE7B8B';  % 0000
                '4748121D747B212E48471D127B742E2147B712E2748421D148B81DED7B8B2EDE';  % 0001
                '212E747B121D47482E217B741D12484721D1748412E247B72EDE7B8B1DED48B8';  % 0010
                '747B212E4748121D7B742E2148471D12748421D147B712E27B8B2EDE48B81DED';  % 0011
                '1D1248472E217B74121D4748212E747B1DED48B82EDE7B8B12E247B721D17484';  % 0100
                '48471D127B742E214748121D747B212E48B81DED7B8B2EDE47B712E2748421D1';  % 0101
                '2E217B741D124847212E747B121D47482EDE7B8B1DED48B821D1748412E247B7';  % 0110
                '7B742E2148471D12747B212E4748121D7B8B2EDE48B81DED748421D147B712E2';  % 0111
                '12E247B721D174841DED48B82EDE7B8B121D4748212E747B1D1248472E217B74';  % 1000
                '47B712E2748421D148B81DED7B8B2EDE4748121D747B212E48471D127B742E21';  % 1001
                '21D1748412E247B72EDE7B8B1DED48B8212E747B121D47482E217B741D124847';  % 1010
                '748421D147B712E27B8B2EDE48B81DED747B212E4748121D7B742E2148471D12';  % 1011
                '1DED48B82EDE7B8B12E247B721D174841D1248472E217B74121D4748212E747B';  % 1100
                '48B81DED7B8B2EDE47B712E2748421D148471D127B742E214748121D747B212E';  % 1101
                '2EDE7B8B1DED48B821D1748412E247B72E217B741D124847212E747B121D4748';  % 1110
                '7B8B2EDE48B81DED748421D147B712E27B742E2148471D12747B212E4748121D']; % 1111

% Calculations related to Interleaving Frames for each PLP in the input processing and BICM part to avoid doing
% this in every module

NUM_PLPS = DVBT2.NUM_PLPS;
NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES;
START_T2_FRAME = DVBT2.START_T2_FRAME;

for plp=1:NUM_PLPS
    FIRST_FRAME_IDX = DVBT2.PLP(plp).FIRST_FRAME_IDX;
    P_I = DVBT2.PLP(plp).P_I;
    I_JUMP = DVBT2.PLP(plp).I_JUMP;
        
    % Work out the first Interleaving Frame index for this PLP, and the
    % number of Interleaving Frames to generate.
    % An interleaving frame is only generated if the simulation run includes the 
    % first T2-frame to which it is mapped. Otherwise it is assumed that
    % the Interleaving Frame was already generated and the unused cells stored in the Frame
    % Builder's state
    
    startILFrame = ceil((START_T2_FRAME-FIRST_FRAME_IDX)/(P_I*I_JUMP));
    endILFrame = floor((START_T2_FRAME + NUM_SIM_T2_FRAMES - 1 - FIRST_FRAME_IDX)/(P_I*I_JUMP));
    
    STD.PLP(plp).START_INT_FRAME = startILFrame;
    STD.PLP(plp).NUM_INT_FRAMES = endILFrame-startILFrame+1;
    

end

% Work out how many T2-frames we need to process to get enough scheduling
% data

% First work out how many T2 frames the scheduling needs to be calculated
% for, taking into account IBS:
startT2FrameSig = calcT2FramesToSignal(DVBT2, START_T2_FRAME);
endT2FrameSig = calcT2FramesToSignal(DVBT2, START_T2_FRAME+NUM_SIM_T2_FRAMES)-1; % sub 1 because frame numbers start from 0 so to make 1 frame, last frame=0
STD.START_T2_FRAME_SIG = startT2FrameSig;
STD.END_T2_FRAME_SIG = endT2FrameSig;

% taking into account L1-repetition@
if DVBT2.L1_REPETITION_FLAG
    endT2FrameSig = max(endT2FrameSig, (START_T2_FRAME+NUM_SIM_T2_FRAMES-1)+1);
end

for plp=1:NUM_PLPS
    % Total number of interleaving frames for which scheduling is needed to generate
    % enough scheduling data
    %plpStartIntFrameSig = ceil((startT2FrameSig-FIRST_FRAME_IDX) / (P_I * I_JUMP)); 
    FIRST_FRAME_IDX = DVBT2.PLP(plp).FIRST_FRAME_IDX;
    P_I = DVBT2.PLP(plp).P_I;
    I_JUMP = DVBT2.PLP(plp).I_JUMP;
    plpTotalIntFramesSig = ceil((endT2FrameSig+1-FIRST_FRAME_IDX) / (P_I * I_JUMP)); % make enough T2-frames for other PLPs' signalling

    STD.PLP(plp).TOTAL_INT_FRAMES_SIG = plpTotalIntFramesSig; 
    
end

% Calculate T2-frames to mute output for (to achieve valid output following
% any compensating delays), starting at super-frame boundary
maxCompDelay = 0;
for plp=1:NUM_PLPS
    compDelay = DVBT2.PLP(plp).COMP_DELAY * DVBT2.PLP(plp).P_I * DVBT2.PLP(plp).I_JUMP;
    if compDelay > maxCompDelay; maxCompDelay = compDelay; end
end
STD.OUTPUT_START_FRAME = ceil (maxCompDelay / DVBT2.N_T2) * DVBT2.N_T2 + 1; % Counting in T2-frames from 1

%P2 bias cell calculations
D_L1 = STD.D_L1PRE + STD.D_L1POST;
N_biasCellsTotalMax = (STD.C_P2 * STD.N_P2 - D_L1);

if (DVBT2.NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2 > 0)
    NUM_DUMMY_L1_BIAS_BALANCING_CELLS_PER_P2 = (N_biasCellsTotalMax / N_P2) - DVBT2.NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2;
else
    NUM_DUMMY_L1_BIAS_BALANCING_CELLS_PER_P2 = 0;
end

NUM_TOTAL_L1_BIAS_BALANCING_CELLS = (N_P2-1) * NUM_DUMMY_L1_BIAS_BALANCING_CELLS_PER_P2 + (N_P2*DVBT2.NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2);    

STD.NUM_DUMMY_L1_BIAS_BALANCING_CELLS_PER_P2 = NUM_DUMMY_L1_BIAS_BALANCING_CELLS_PER_P2;
STD.NUM_TOTAL_L1_BIAS_BALANCING_CELLS = NUM_TOTAL_L1_BIAS_BALANCING_CELLS;

end

function T2FramesToSignal = calcT2FramesToSignal(DVBT2, numT2Frames)
% Calculates how many T2 frames need to be fully scheduled in order to
% generate the signalling carried in numT2Frames frames.

NUM_PLPS = DVBT2.NUM_PLPS;

T2FramesToSignal = numT2Frames;

for plp=1:NUM_PLPS
    FIRST_FRAME_IDX = DVBT2.PLP(plp).FIRST_FRAME_IDX;
    P_I = DVBT2.PLP(plp).P_I;
    I_JUMP = DVBT2.PLP(plp).I_JUMP;
    
    % Number of full or partial interleaving frames in numT2Frames
    numInterleavingFrames = ceil((numT2Frames-FIRST_FRAME_IDX) / (P_I * I_JUMP));
    if DVBT2.PLP(plp).IN_BAND_A_FLAG
        plpT2FramesToSignal = numInterleavingFrames * P_I * I_JUMP + FIRST_FRAME_IDX+1 + (P_I-1)*I_JUMP;
    else
        plpT2FramesToSignal = numT2Frames;
    end
    if (plpT2FramesToSignal>T2FramesToSignal)
        T2FramesToSignal = plpT2FramesToSignal;
    end
    
end

end
