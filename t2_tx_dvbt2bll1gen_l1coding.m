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
%* Description : t2_tx_dvbt2bll1gen_l1coding DVBT2 L1 coding and modulation
%******************************************************************************
function [L1_pre_const, L1_post_const, l1test] = t2_tx_dvbt2bll1gen_l1coding(L1_pre_bits, L1_post_bits, DVBT2)

N_P2 = DVBT2.STANDARD.N_P2;
nBiasCellsActive = DVBT2.NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2;
L1_BIAS_BALANCING_CELLS_MAX_AMPLITUDE = DVBT2.L1_BIAS_BALANCING_CELLS_MAX_AMPLITUDE;

post_info_size = length(L1_post_bits);

% Do all the L1-post calculations to get the intermediate parameters
[N_post_FEC_block, K_sig, K_bch, N_post, N_punc, N_mod_total, N_mod_per_block, K_L1_PADDING] = t2_tx_dvbt2bll1gen_l1calcs(DVBT2, post_info_size);

% Calculate CRC_32 for L1 pre
crc=dvb_crc32(L1_pre_bits);
L1_pre_bits = [L1_pre_bits; de2bi(crc, 32, 'left-msb')'];

% Calculate CRC_32 for L1 post - This is for both configurable and dynamic
crc = dvb_crc32(L1_post_bits);
L1_post_bits = [L1_post_bits; de2bi(crc, 32, 'left-msb')'];

% Add padding bits to L1-post
L1_post_bits = [L1_post_bits;zeros(K_L1_PADDING,1)];

l1test.pre.bits = L1_pre_bits;
l1test.post.bits = L1_post_bits;

% ---------------------------- L1 pre ----------------------------------

% BCH padding - This is only valid up to 360 bits
K_BCH_PRE = 3072;
if length(L1_pre_bits) >360
    error('t2_tx_dvbt2bll1gen_l1_coding: Ksig>360 not supported\n');
end

if DVBT2.L1_PRE_SCRAMBLED
    switch DVBT2.L1_SCRAMBLING_TYPE
        case 'BASIC'
            bchin = [L1_pre_bits;zeros(K_BCH_PRE-length(L1_pre_bits),1)];
            bchin = t2_tx_dvbt2bll1gen_l1scramble(bchin.').';
        case 'ZERO_REINSERTION'
            bchin = [L1_pre_bits;zeros(K_BCH_PRE-length(L1_pre_bits),1)];
            bchin = t2_tx_dvbt2bll1gen_l1scramble(bchin.').';
            bchin(length(L1_pre_bits)+1:end)=0;
        case 'KSIG_ONLY'
            L1_pre_bits = t2_tx_dvbt2bll1gen_l1scramble(L1_pre_bits.').';
            bchin = [L1_pre_bits;zeros(K_BCH_PRE-length(L1_pre_bits),1)];
        otherwise
            error('t2_tx_dvbt2bll1gen_l1_coding: unknown scrambling type %s\n', DVBT2.L1_SCRAMBLING_TYPE)
    end
else
    bchin = [L1_pre_bits;zeros(K_BCH_PRE-length(L1_pre_bits),1)];
end    

l1test.pre.padded = bchin;

% BCH encoding
% 1 + x^2 + x^5 + x^7 + x^8 + x^10 ... + x^168
bchgen = [1 0 1 0 0 1 0 1 1 0 1 0 0 0 0 0 1 0 0 1 1 0 0 0 1 0 0 0 1 0 1 1 1 1 1 0 1 0 1 1 1 1 1 0 0 1 1 1 1 1 1 1 0 0 0 1 0 1 0 0 1 0 1 0 1 0 0 1 0 1 1 0 0 0 0 0 1 0 0 1 1 1 0 0 0 1 0 1 1 1 0 0 0 1 0 0 1 0 1 1 0 0 1 1 0 1 0 0 0 1 1 0 0 1 0 0 1 1 0 1 1 0 0 1 0 1 1 0 0 0 0 1 1 0 0 1 0 1 0 1 0 1 1 1 1 1 0 1 1 0 1 1 0 1 0 0 0 1 1 0 0 0 0 0 0 0 1 0 1];
lfsr = zeros(168,1);
for n = 1:3072
    f = bitxor(bchin(n),lfsr(168));
    for m = 166:-1:0
        lfsr(m+2) = bitxor(lfsr(m+1),bitand(bchgen(m+2),f));
    end
    lfsr(1) = f;
end


bchout = [bchin;flipud(lfsr)];

l1test.pre.bchout = bchout;

clear bchgen bchin f lfsr m n


% LDPC encoding
nldpc = 16200;
kldpc = 3240;
q = 36;
i = bchout;
d = nldpc - kldpc;
p = zeros(d,1);


% Table B1
r1 = [6295 9626 304 7695 4839 4936 1660 144 11203 5567 6347 12557];
r2 = [10691 4988 3859 3734 3071 3494 7687 10313 5964 8069 8296 11090];
r3 = [10774 3613 5208 11177 7676 3549 8746 6583 7239 12265 2674 4292];
r4 = [11869 3708 5981 8718 4908 10650 6805 3334 2627 10461 9285 11120];
r5 = [7844 3079 10773];
r6 = [3385 10854 5747];
r7 = [1360 12010 12202];
r8 = [6189 4241 2343];
r9 = [9840 12726 4977];


for m = 0:359
    for r = 1:length(r1)
        o = mod((r1(r) + mod(m,360) * q),d);
        p(o+1) = bitxor(p(o+1),i(m+1));
    end
end
for m = 360:719
    for r = 1:length(r2)
        o = mod((r2(r) + mod(m,360) * q),d);
        p(o+1) = bitxor(p(o+1),i(m+1));
    end
end
for m = 720:1079
    for r = 1:length(r3)
        o = mod((r3(r) + mod(m,360) * q),d);
        p(o+1) = bitxor(p(o+1),i(m+1));
    end
end
for m = 1080:1439
    for r = 1:length(r4)
        o = mod((r4(r) + mod(m,360) * q),d);
        p(o+1) = bitxor(p(o+1),i(m+1));
    end
end
for m = 1440:1799
    for r = 1:length(r5)
        o = mod((r5(r) + mod(m,360) * q),d);
        p(o+1) = bitxor(p(o+1),i(m+1));
    end
end
for m = 1800:2159
    for r = 1:length(r6)
        o = mod((r6(r) + mod(m,360) * q),d);
        p(o+1) = bitxor(p(o+1),i(m+1));
    end
end
for m = 2160:2519
    for r = 1:length(r7)
        o = mod((r7(r) + mod(m,360) * q),d);
        p(o+1) = bitxor(p(o+1),i(m+1));
    end
end
for m = 2520:2879
    for r = 1:length(r8)
        o = mod((r8(r) + mod(m,360) * q),d);
        p(o+1) = bitxor(p(o+1),i(m+1));
    end
end
for m = 2880:3239
    for r = 1:length(r9)
        o = mod((r9(r) + mod(m,360) * q),d);
        p(o+1) = bitxor(p(o+1),i(m+1));
    end
end


for m = 2:d
    p(m) = bitxor(p(m),p(m-1));
end


ldpcout = [i;p];

l1test.pre.ldpcout = ldpcout;

punctureout = ldpcout;


clear d i kldpc m nldpc o p r q r1 r2 r3 r4 r5 r6 r7 r8 r9


% Puncturing
p = [27 13 29 32 5 0 11 21 33 20 25 28 18 35 8 3 9 31 22 24 7 14 17 4 2 26 16 34 19 10 12 23 1 6 30 15];


% Puncture first 31 groups
q = 36;
m = 31;
for c = 1:m
    g = p(c);
    for c2 = 0:359
        o = (c2 * q) + g + 3241;
        punctureout(o) = -1;
    end
end


% Puncture 328 bits in group 32
g = p(32);
for c2 = 0:327
    o = (c2 * q) + g + 3241;
    punctureout(o) = -1;
end


% Puncture all BCH padding bits
punctureout(201:200+2872) = -1;
punctureout = punctureout(punctureout ~= -1);
clear c c2 g m o p q

l1test.pre.punctureout = punctureout;

% Map to 1840 BPSK constellation points
L1_pre_const = ones(1840,1);
for n = 1:1840
    if punctureout(n) == 1
        L1_pre_const(n) = -1;
    end
end

clear n bchout ldpcout punctureout
% ---------------------------- L1 post ----------------------------------
 
% Shortening of BCH information Bits
bitPerGroup = 360;
bitsLastGroup = 192;
nBch = 7200;

% P2 Permutation sequence of parity group to be shortened/punctured
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

dataL1Post = reshape(L1_post_bits,K_sig,N_post_FEC_block).';

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

dataSort = zeros(N_post_FEC_block,K_bch);

if DVBT2.L1_POST_SCRAMBLED
    switch DVBT2.L1_SCRAMBLING_TYPE
        case 'BASIC'
            dataSort(:,dataIdx) = dataL1Post;
            dataSort = t2_tx_dvbt2bll1gen_l1scramble(dataSort);
        case 'ZERO_REINSERTION'
            padding = zeros(1,K_bch);
            padding (1,dataIdx) = 1;
            zeroLoc = padding ~= 1;

            dataSort(:,dataIdx) = dataL1Post;
            dataSort = t2_tx_dvbt2bll1gen_l1scramble(dataSort);
            dataSort(:,zeroLoc) = 0;
        case 'KSIG_ONLY'
            dataL1Post = t2_tx_dvbt2bll1gen_l1scramble(dataL1Post);
            dataSort(:,dataIdx) = dataL1Post;
        otherwise
            error('t2_tx_dvbt2bll1gen_l1_coding: unknown scrambling type %s\n', DVBT2.L1_SCRAMBLING_TYPE)
    end
else
    dataSort(:,dataIdx) = dataL1Post;
end

bchin = dataSort;

l1test.post.padded = bchin.';

% BCH encoding
bchgen = [1 0 1 0 0 1 0 1 1 0 1 0 0 0 0 0 1 0 0 1 1 0 0 0 1 0 0 0 1 0 1 1 1 1 1 0 1 0 1 1 1 1 1 0 0 1 1 1 1 1 1 1 0 0 0 1 0 1 0 0 1 0 1 0 1 0 0 1 0 1 1 0 0 0 0 0 1 0 0 1 1 1 0 0 0 1 0 1 1 1 0 0 0 1 0 0 1 0 1 1 0 0 1 1 0 1 0 0 0 1 1 0 0 1 0 0 1 1 0 1 1 0 0 1 0 1 1 0 0 0 0 1 1 0 0 1 0 1 0 1 0 1 1 1 1 1 0 1 1 0 1 1 0 1 0 0 0 1 1 0 0 0 0 0 0 0 1 0 1];

bchout = zeros(nBch,N_post_FEC_block);
for kk = 1:N_post_FEC_block
  lfsr = zeros(168,1);
  for n = 1:7032
    f = bitxor(bchin(kk,n),lfsr(168));
    for m = 166:-1:0
      lfsr(m+2) = bitxor(lfsr(m+1),bitand(bchgen(m+2),f));
    end
    lfsr(1) = f;
  end

  bchout(:,kk) = [bchin(kk,:).';flipud(lfsr)];

end
l1test.post.bchout = bchout;

clear bchgen bchin f lfsr m n dataSort

% LDPC encoding
nldpc = 16200;
kldpc = 7200;
q = 25;
d = nldpc - kldpc;



% Table B2
r1 = [20 712 2386 6354 4061 1062 5045 5158];
r2 = [21 2543 5748 4822 2348 3089 6328 5876];
r3 = [22 926 5701 269 3693 2438 3190 3507];
r4 = [23 2802 4520 3577 5324 1091 4667 4449];
r5 = [24 5140 2003 1263 4742 6497 1185 6202];
r6 = [0 4046 6934];
r7 = [1 2855 66];
r8 = [2 6694 212];
r9 = [3 3439 1158];
r10 = [4 3850 4422];
r11 = [5 5924 290];
r12 = [6 1467 4049];
r13 = [7 7820 2242];
r14 = [8 4606 3080];
r15 = [9 4633 7877];
r16 = [10 3884 6868];
r17 = [11 8935 4996];
r18 = [12 3028 764];
r19 = [13 5988 1057];
r20 = [14 7411 3450];

ldpcout = zeros(nldpc,N_post_FEC_block);
for kk = 1:N_post_FEC_block
  i = bchout(:,kk);
  p = zeros(d,1);
  o = 0;

  for m = 0:359
    for r = 1:length(r1)
      o = mod((r1(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 360:719
    for r = 1:length(r2)
      o = mod((r2(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 720:1079
    for r = 1:length(r3)
      o = mod((r3(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 1080:1439
    for r = 1:length(r4)
      o = mod((r4(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 1440:1799
    for r = 1:length(r5)
      o = mod((r5(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 1800:2159
    for r = 1:length(r6)
      o = mod((r6(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 2160:2519
    for r = 1:length(r7)
      o = mod((r7(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 2520:2879
    for r = 1:length(r8)
      o = mod((r8(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 2880:3239
    for r = 1:length(r9)
      o = mod((r9(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 3240:3599
    for r = 1:length(r10)
      o = mod((r10(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 3600:3959
    for r = 1:length(r11)
      o = mod((r11(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 3960:4319
    for r = 1:length(r12)
      o = mod((r12(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 4320:4679
    for r = 1:length(r13)
      o = mod((r13(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 4680:5039
    for r = 1:length(r14)
      o = mod((r14(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 5040:5399
    for r = 1:length(r15)
      o = mod((r15(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 5400:5759
    for r = 1:length(r16)
      o = mod((r16(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 5760:6119
    for r = 1:length(r17)
      o = mod((r17(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 6120:6479
    for r = 1:length(r18)
      o = mod((r18(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 6480:6839
    for r = 1:length(r19)
      o = mod((r19(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end
  for m = 6840:7199
    for r = 1:length(r20)
      o = mod((r20(r) + mod(m,360) * q),d);
      p(o+1) = bitxor(p(o+1),i(m+1));
    end
  end

  
  for m = 2:d
    p(m) = bitxor(p(m),p(m-1));
  end
  

  ldpcout(:,kk) = [i;p];

end

l1test.post.ldpcout = ldpcout;

punctureout = ldpcout;
clear d i kldpc m nldpc o p r q r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 r13 r14 r15 r16 r17 r18 r19 r20


% Puncturing
p = piPPost;

N_punc_groups = floor(N_punc / 360);
N_punc_last = N_punc - 360 * N_punc_groups;


% Puncture first N_punc_groups groups (22 here)
q = 25;
m = N_punc_groups;
for c = 1:m
    g = p(c);
    for c2 = 0:359
        o = (c2 * q) + g + 7201;
        punctureout(o,1) = -1;
    end
end


% Puncture N_punc_last bits in last group (group 23 here)
g = p(N_punc_groups + 1);
for c2 = 0:(N_punc_last - 1)
    o = (c2 * q) + g + 7201;
    punctureout(o,1) = -1;
end


% Puncture all BCH padding bits
aux = punctureout(dataIdx,:);
punctureout(1:7032,1) = -1;
punctureout = [aux; punctureout(punctureout(:,1) ~= -1,:)];
clear c c2 g m o p q

l1test.post.punctureout = punctureout;


% Bit Interleaving
if strcmp(DVBT2.L1_CONSTELLATION,'16-QAM')
  nc = 8;
  nr = N_post/nc;
  aux = 1:N_post;
  biPostW = reshape(aux,nr,nc);
  biPostR = reshape(biPostW.',1,nr*nc);
  bitout  = punctureout(biPostR,:);  
elseif strcmp(DVBT2.L1_CONSTELLATION,'64-QAM')
  nc = 12;
  nr = N_post/nc;
  aux = 1:N_post;
  biPostW = reshape(aux,nr,nc);
  biPostR = reshape(biPostW.',1,nr*nc);
  bitout  = punctureout(biPostR,:);  
else
  bitout = punctureout;
end

%bitout = reshape(bitout,1,nPostFecBlock*nPost);

l1test.post.bitout = bitout;

clear bitint punctureout aux biPostW biPostR

% Demultiplexer and mapper for 64-QAM (121 blocks of 12 bits in 1452)

switch DVBT2.L1_CONSTELLATION
    case '64-QAM'
        N_substreams = 12;
        split = 2;
        cpmap = [7 5 1 3 -7 -5 -1 -3];
        demux = [11 8 5 2 10 7 4 1 9 6 3 0]; %NB defines where given output comes from in input - opposite to table 12a
        realWeights = [4 0 2 0 1 0];
        imagWeights = [0 4 0 2 0 1];
        scale = 1/sqrt(42);
    case '16-QAM'
        N_substreams = 8;
        split = 2;
        cpmap = [3 1 -3 -1];
        demux = [7 1 3 5 2 4 6 0];
        realWeights = [2 0 1 0]; 
        imagWeights = [0 2 0 1];
        scale = 1/sqrt(10);
    case 'QPSK'
        N_substreams = 2;
        split = 1;
        cpmap = [1 -1];
        demux = [0 1];
        realWeights = [1 0];
        imagWeights = [0 1];
        scale = 1/sqrt(2);

    case 'BPSK'
        N_substreams = 1;
        split = 1;
        cpmap = [1 -1];
        demux = [0];
        realWeights = [1];
        imagWeights = [0];
        scale = 1;
        
end


L1_post_const = complex(zeros(N_mod_per_block,N_post_FEC_block));
bpc = N_substreams/split; % bits per cell

for kk = 1:N_post_FEC_block
  for n = 0:((N_post / N_substreams) - 1)
    s = bitout(n*N_substreams+1:n*N_substreams+N_substreams,kk);
    s2 = s(demux+1);
    
    for i = 0:split-1
      vr = s2(i*bpc + (1:bpc))' * realWeights';
      vi = s2(i*bpc + (1:bpc))' * imagWeights';
      if (N_substreams==1) % BPSK
        cp = cpmap(vr+1); % imaginary = 0
      else
        cp = cpmap(vr+1) + j * cpmap(vi+1);
      end
      L1_post_const(n*split+i+1,kk) = cp;
    end
  end
end


L1_post_const = L1_post_const(:);

%Apply L1-ACE correction to remove bias
if DVBT2.L1_ACE_MAX > 0
    bias = sum([L1_pre_const; L1_post_const * scale]);
    if abs (bias) > N_P2 * nBiasCellsActive * L1_BIAS_BALANCING_CELLS_MAX_AMPLITUDE;
        bias = bias - N_P2 * nBiasCellsActive * bias/abs(bias) * L1_BIAS_BALANCING_CELLS_MAX_AMPLITUDE ;
        Cr = real(bias); Ci = imag(bias);
        if (Cr<0)
            L_pre = 1;
            Lr = max(cpmap);
        else
            L_pre = -1;
            Lr = min(cpmap);
        end
        if (Ci<0); Li = max(cpmap); else Li = min(cpmap); end
        
        preACE = find((L1_pre_const == L_pre));
        postACEr = find((real(L1_post_const) == Lr));
        postACEi = find((imag(L1_post_const) == Li));
        N_pre = length(preACE);
        Nr_post = length(postACEr);
        Nr = N_pre + Nr_post;
        Ni = length(postACEi);
    
        cACEpre = min(abs(Cr/Nr),DVBT2.L1_ACE_MAX)*sign(L_pre) + L_pre;
        cACEr = min(abs(Cr/Nr),DVBT2.L1_ACE_MAX)*sign(Lr)/scale + Lr;
        cACEi = min(abs(Ci/Ni),DVBT2.L1_ACE_MAX)*sign(Li)/scale + Li;
        
        L1_pre_const(preACE) = cACEpre;
        
        L1_post_real = real(L1_post_const);
        L1_post_imag = imag(L1_post_const);
        
        L1_post_real(postACEr) = cACEr;
        L1_post_imag(postACEi) = cACEi;
        
        L1_post_const = L1_post_real + 1i*L1_post_imag;
    end
end

% Scale constellation
L1_post_const = L1_post_const * scale;
