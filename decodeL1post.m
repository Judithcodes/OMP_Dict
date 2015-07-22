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
%* Description : decodeL1post DVBT2 L1-post-signalling decoder
%******************************************************************************
function [L1postData nsr_est] = decodeL1post(DVBT2, FidLogFile, L1post, h_est)

% WARNING: Decoding of L1-post with multiple FEC blocks is not yet checked

fprintf (FidLogFile,'\n\t\tL1-Post decoding\n');

%Get parameters
Nldpc = 16200;
K_bch = 7032;
L1mod = DVBT2.L1_CONSTELLATION;
L1postSize = DVBT2.STANDARD.D_L1POST;
N_post = DVBT2.STANDARD.N_POST;
K_sig = DVBT2.STANDARD.K_SIG_POST;
N_punc = DVBT2.STANDARD.N_PUNC_POST;
N_post_FEC_block = DVBT2.STANDARD.N_POST_FEC_BLOCK;
L1_post_info_size = DVBT2.STANDARD.N_POST_INFO_SIZE;
NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES;
minMetric = 1e-45;

if (NUM_SIM_T2_FRAMES ~= 1); error ('Decoding of multiple frames at a time not implemented yet\n'); end

switch L1mod
    case 'BPSK'                       % BPSK
        V        = 1;                 % Bits per cell       
        C        = 1;                 % Normalization factor
        C_DEC    = 0;                 % Decision region
        demux    = 0;
        C_POINTS = [1 -1];
        
    case 'QPSK'                       % QPSK
        V        = 2;
        C        = sqrt(2);
        C_DEC    = 0;
        demux    = [0 1];
        C_POINTS = [1+1i 1-1i -1+1i -1-1i];
        
    case '16-QAM'                       % 16QAM
        V        = 4;
        C        = sqrt(10);
        C_DEC    = [0 2];
        demux    = [7 1 4 2 5 3 6 0];
        C_POINTS = [3+3i 3+1i 1+3i 1+1i 3-3i 3-1i 1-3i 1-1i -3+3i -3+1i -1+3i ...
                    -1+1i -3-3i -3-1i -1-3i -1-1i];
    case '64-QAM'                       % 64QAM
        V        = 6;
        C        = sqrt(42);
        C_DEC    = [0 4 2];
        demux    = [11 7 3 10 6 2 9 5 1 8 4 0];
        C_POINTS = [7+7i 7+5i 5+7i 5+5i 7+1i 7+3i 5+1i 5+3i 1+7i 1+5i 3+7i ...
                    3+5i 1+1i 1+3i 3+1i 3+3i 7-7i 7-5i 5-7i 5-5i 7-1i 7-3i ...
                    5-1i 5-3i 1-7i 1-5i 3-7i 3-5i 1-1i 1-3i 3-1i 3-3i -7+7i ...
                    -7+5i -5+7i -5+5i -7+1i -7+3i -5+1i -5+3i -1+7i -1+5i ... 
                    -3+7i -3+5i -1+1i -1+3i -3+1i -3+3i -7-7i -7-5i -5-7i ...
                    -5-5i -7-1i -7-3i -5-1i -5-3i -1-7i -1-5i -3-7i -3-5i ...
                    -1-1i -1-3i -3-1i -3-3i];

    otherwise
        error ('Unknown L1_mod %s\n', L1mod);
end
BITS_PER_CELL = V;

%De-map to estimate noise
L1post = L1post*C;
L1postData = zeros(V, L1postSize, NUM_SIM_T2_FRAMES);

if V>1
    L1postData(1,:,:) = real(L1post) - C_DEC(1);
    L1postData(2,:,:) = imag(L1post) - C_DEC(1);

    for k = 2:length(C_DEC)
        L1postData(2*k-1,:,:) = abs(L1postData(2*(k-1)-1,:,:)) - C_DEC(k);
        L1postData(2*k,:,:)   = abs(L1postData(2*(k-1),:,:))   - C_DEC(k);
    end
end

% Calculate MER from LSBs
if V==1
    reals=abs(real(L1post))-1;
    imags=imag(L1post);
else
    reals=abs(L1postData(V-1,:,:))-1;
    imags=abs(L1postData(V,:,:))-1;
end
nsr_est=mean(reals(:).^2 + imags(:).^2)/C^2;

%Get LLRs for L1post
csi = abs(h_est).^2;
variance = single(nsr_est*C^2 ./ csi)/2;
s = C_POINTS;

%allocate memory for metrics
metrics = single(zeros(length(L1post), length(s)));
for symbol = 1:length(s)
    metrics(:,symbol) = ...
        exp (                                                                    ...
        - (   1./(2.*variance) .* ( ( real(L1post) - real(s(symbol)) ) .^2 )   ) ...
        - (   1./(2.*variance) .* ( ( imag(L1post) - imag(s(symbol)) ) .^2 )   ) ...
        );
end

%Set minimum metric to prevent Inf LLRs
metrics(metrics==0)=minMetric;

% go through and calculate metric for each bit
symbol_values = 0 : (2^BITS_PER_CELL-1);
binary_symbol_values = de2bi(symbol_values,'left-msb')';

%allocate memory for bit metrics
metrics_for_each_bit_being_zero = single(zeros(length(L1post), BITS_PER_CELL));

for bit = 1:BITS_PER_CELL
    ones_cols = binary_symbol_values(bit,:);
    %add one for column indexing (and conveniently we can then remove 0's to weed
    %out columns we want)
    ones_cols = ones_cols .* (symbol_values+1);
    ones_cols = ones_cols(ones_cols ~= 0);
    
    zeros_cols = ~binary_symbol_values(bit,:);
    %add one for column indexing (and conveniently we can then remove 0's to weed
    %out columns we want)
    zeros_cols = zeros_cols .* (symbol_values+1);
    zeros_cols = zeros_cols(zeros_cols ~= 0);
    
    metrics_for_each_bit_being_zero(:,bit) = log( sum(metrics(:,zeros_cols),2) ) - log( sum(metrics(:,ones_cols),2) );
end

%Apply demux
if V==4 || V==6
    softDecisions = reshape(metrics_for_each_bit_being_zero',2*V,[])';
else
    softDecisions = metrics_for_each_bit_being_zero;
end
softDecisions = softDecisions(:,demux+1);
softDecisions = reshape(softDecisions', [], N_post_FEC_block );

% Bit De-Interleaving
if strcmp(DVBT2.L1_CONSTELLATION,'16-QAM')
  nc = 8;
  nr = N_post/nc;
  aux = 1:N_post;
  biPostW = reshape(aux,nc,nr); % Sounds wrong, but it's just the mirror of the interleaving
  biPostR = reshape(biPostW.',1,nr*nc);
  softDecisions = softDecisions(biPostR,:);
elseif strcmp(DVBT2.L1_CONSTELLATION,'64-QAM')
  nc = 12;
  nr = N_post/nc;
  aux = 1:N_post;
  biPostW = reshape(aux,nc,nr);
  biPostR = reshape(biPostW.',1,nr*nc);
  softDecisions = softDecisions(biPostR,:);
end

% P2 Permutation sequence of information/parity group to be shortened/punctured
switch DVBT2.L1_CONSTELLATION
 case {'BPSK','QPSK'}
  piSPost = [18 17 16 15 14 13 12 11 4 10 9 8 3 2 7 6 5 1 19 0];
  piPPost = [6 4 18 9 13 8 15 20 5 17 2 24 10 22 12 3 16 23 1 14 0 ...
             21 19 7 11];
 case '16-QAM'
  piSPost = [18 17 16 15 14 13 12 11 4 10 9 8 7 3 2 1 6 5 19 0];
  piPPost = [6 4 13 9 18 8 15 20 5 17 2 22 24 7 12 1 16 23 14 0 21 ...
             10 19 11 3];
 case '64-QAM'
  piSPost = [18 17 16 4 15 14 13 12 3 11 10 9 2 8 7 1 6 5 19 0];
  piPPost = [6 15 13 10 3 17 21 8 5 19 2 23 16 24 7 18 1 12 20 0 4 ...
             14 9 11 22];
end

% Set up shortening of BCH information Bits
bitPerGroup = 360;
bitsLastGroup = 192;
nBch = 7200;
nGroup = nBch/bitPerGroup;
  
if (K_sig <= bitPerGroup)
  m = nGroup - 1;
  lastGroupPad = bitPerGroup - K_sig;
else
  m = floor((K_bch - K_sig)/bitPerGroup);
  lastGroupPad = K_bch - K_sig - bitPerGroup*m;
end

lastGroup = find(piSPost==nGroup-1);

groupIdx = zeros(length(piSPost),2);

groupIdx(:,1) = ((piSPost.*bitPerGroup)+1).';
groupIdx(:,2) = ((piSPost+1).*bitPerGroup).';
groupIdx(lastGroup,2) = groupIdx(lastGroup,1)+bitsLastGroup-1;

dataIdx = [];
for l =m+1:nGroup
  if (l == m+1)
    dataIdx = [dataIdx groupIdx(l,1):groupIdx(l,2)-lastGroupPad];
  else
    dataIdx = [dataIdx groupIdx(l,1):groupIdx(l,2)];
  end
end

dataIdx = sort(dataIdx,'ascend');

% Puncturing
p = piPPost;

N_punc_groups = floor(N_punc / 360);
N_punc_last = N_punc - 360 * N_punc_groups;
puncturePattern = zeros(Nldpc,1);

% Puncture first N_punc_groups groups (22 here)
q = 25;
m = N_punc_groups;
for c = 1:m
    g = p(c);
    for c2 = 0:359
        o = (c2 * q) + g + 7201;
        puncturePattern(o,1) = -1;
    end
end


% Puncture N_punc_last bits in last group (group 23 here)
g = p(N_punc_groups + 1);
for c2 = 0:(N_punc_last - 1)
    o = (c2 * q) + g + 7201;
    puncturePattern(o,1) = -1;
end


% Puncture all BCH padding bits
bchPadding (1:7032) = -1;
bchPadding (dataIdx) = 0; %Don't puncture the information bits!
puncturePattern(1:7032,1) = bchPadding;

% Set up LDPC blocks for decoding
ldpcBlocks = zeros(Nldpc,N_post_FEC_block);
if sum(puncturePattern(:,1) ~= -1)*N_post_FEC_block ~= numel(softDecisions); error ('Incorrect number of L1-post bits %d\n', length(softDecisions)); end
softDecisions = reshape (softDecisions,[],N_post_FEC_block);
ldpcBlocks (puncturePattern(:,1) ~= -1,:) = softDecisions;

if DVBT2.L1_POST_SCRAMBLED
    % Get BB scrambling sequence
    bbPrbs = t2_tx_dvbt2blbbscramble_bbprbsseq(K_bch).';
    bbPrbs = repmat (bbPrbs, 1, N_post_FEC_block);
    if strcmp (DVBT2.L1_SCRAMBLING_TYPE, 'BASIC')
        % Convert to +-1's
        bbPrbsMult = bbPrbs*2-1;
        % Set all BCH padding bits to maximum confidence 0/1's according to scrambling sequence (i.e. insert scrambled 0's)
        ldpcBlocks ((bchPadding==-1), :) = bbPrbsMult((bchPadding==-1), :).*log(minMetric);
    else %Insert maximum confidence 0's
        ldpcBlocks ((bchPadding==-1), :) = -log(minMetric);
    end
else %Insert maximum confidence 0's
    ldpcBlocks ((bchPadding==-1), :) = -log(minMetric);
end

L1postData = zeros (nBch/8, N_post_FEC_block);
for block = 1:N_post_FEC_block
    L1postData(:,block) = l1_ldpc_decoder (DVBT2, FidLogFile, ldpcBlocks(:,block), false);
end

L1postData=reshape(L1postData, 1, []);
L1postBits=reshape(de2bi(L1postData,8,'left-msb')',[],N_post_FEC_block);

if DVBT2.L1_POST_SCRAMBLED
    switch DVBT2.L1_SCRAMBLING_TYPE
        case {'BASIC', 'ZERO_REINSERTION'}
            L1postBits = bitxor(L1postBits(1:K_bch,:),bbPrbs);
            L1postData = L1postBits(dataIdx,:);
        case 'KSIG_ONLY'
            L1postData = L1postBits(dataIdx,:);
            L1postData = bitxor (L1postData, bbPrbs(1:K_sig,:));
        otherwise
            error('t2_tx_dvbt2bll1gen_l1_coding: unknown scrambling type %s\n', DVBT2.L1_SCRAMBLING_TYPE)
    end
else
    L1postData = L1postBits(dataIdx,:);
end

L1postData = reshape(L1postData,1,[]);

% Check CRC_32 for L1 post
crc = dvb_crc32(L1postData(1:end-32));
if sum(bitxor (L1postData(end-31:end), de2bi(crc, 32, 'left-msb'))) ~= 0
    error ('L1-post CRC check failed\n')
end

end
