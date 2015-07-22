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
%* Description : decodeL1pre DVBT2 L1-pre decoder
%******************************************************************************
function L1preData = decodeL1pre(DVBT2, FidLogFile, L1pre, h_est)

fprintf (FidLogFile,'\t\tL1-Pre decoding\n');

%Get parameters
L1preLen = DVBT2.STANDARD.D_L1PRE;
BITS_PER_CELL = 1;
K_BCH_PRE = 3072;
K_SIG_PRE = 200;
Nldpc = 16200;
minMetric = 1e-45;

%Get LLRs for L1pre
csi = abs(h_est).^2;
reals = abs(real(L1pre))-1;
imags = imag(L1pre);
nsr_est = mean(reals.^2 + imags.^2);
variance = single(nsr_est ./ csi)/2;
s = [1 -1];

%allocate memory for metrics
metrics = single(zeros(length(L1pre), length(s)));
for symbol = 1:length(s)
    metrics(:,symbol) = ...
        exp (                                                                    ...
        - (   1./(2.*variance) .* ( ( real(L1pre) - real(s(symbol)) ) .^2 )   ) ...
        - (   1./(2.*variance) .* ( ( imag(L1pre) - imag(s(symbol)) ) .^2 )   ) ...
        );
end

%Set minimum metric to prevent Inf LLRs
metrics(metrics==0)=minMetric;

% go through and calculate metric for each bit
symbol_values = 0 : (2^BITS_PER_CELL-1);
binary_symbol_values = de2bi(symbol_values,'left-msb')';

%allocate memory for bit metrics
metrics_for_each_bit_being_zero = single(zeros(length(L1pre), BITS_PER_CELL));

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

% Set up L1-pre Puncturing
p = [27 13 29 32 5 0 11 21 33 20 25 28 18 35 8 3 9 31 22 24 7 14 17 4 2 26 16 34 19 10 12 23 1 6 30 15];

puncturePattern = zeros(Nldpc,1);

% Puncture first 31 groups
q = 36;
m = 31;
for c = 1:m
    g = p(c);
    for c2 = 0:359
        o = (c2 * q) + g + 3241;
        puncturePattern(o) = -1;
    end
end

% Puncture 328 bits in group 32
g = p(32);
for c2 = 0:327
    o = (c2 * q) + g + 3241;
    puncturePattern(o) = -1;
end

% Puncture all BCH padding bits 
puncturePattern(K_SIG_PRE+1:K_BCH_PRE) = -1;

ldpcBlock = zeros(Nldpc,1);
softDecisions = reshape (metrics_for_each_bit_being_zero,[],1);
if sum(puncturePattern ~= -1) ~= length(softDecisions); error ('Incorrect number of L1-pre bits %d\n', length(softDecisions)); end
ldpcBlock (puncturePattern ~= -1) = softDecisions;

if DVBT2.L1_PRE_SCRAMBLED
    % Get BB scrambling sequence
    bbPrbs = t2_tx_dvbt2blbbscramble_bbprbsseq(K_BCH_PRE);
    if strcmp (DVBT2.L1_SCRAMBLING_TYPE, 'BASIC')
        % Convert to +-1's
        bbPrbsMult = bbPrbs*2-1;
        % Set all BCH padding bits to maximum confidence 0/1's according to scrambling sequence (i.e. insert scrambled 0's)
        ldpcBlock (K_SIG_PRE+1:K_BCH_PRE) = bbPrbsMult(K_SIG_PRE+1:K_BCH_PRE).*log(minMetric);
    else %Insert maximum confidence 0's
        ldpcBlock (K_SIG_PRE+1:K_BCH_PRE) = -log(minMetric);
    end
else %Insert maximum confidence 0's
    ldpcBlock (K_SIG_PRE+1:K_BCH_PRE) = -log(minMetric);
end

L1preData = l1_ldpc_decoder (DVBT2, FidLogFile, ldpcBlock, true);

L1preBits=reshape(de2bi(L1preData,8,'left-msb')',1,[]);

L1preData=L1preBits(1:200);

if DVBT2.L1_PRE_SCRAMBLED
    L1preData = bitxor(L1preData,bbPrbs(1:200));
end    

% Check CRC_32 for L1 pre
crc=dvb_crc32(L1preData(1:end-32));
if sum(bitxor (L1preData(end-31:end), de2bi(crc, 32, 'left-msb'))) ~= 0
    error ('L1-pre CRC check failed\n')
end

end
