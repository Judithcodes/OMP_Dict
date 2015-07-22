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
%* Description : extractL1data DVBT2 L1 data extraction
%******************************************************************************
function L1Data = extractL1data (DVBT2, FidLogFile, data)

nP2 = DVBT2.STANDARD.N_P2;  
cData=DVBT2.STANDARD.C_DATA;
L1preLen=DVBT2.STANDARD.D_L1PRE;
NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES;
lf = DVBT2.STANDARD.L_F;

dataIn = reshape (data.data, cData, []);
h_est = reshape (data.h_est, cData, []);
numSymb = size(dataIn,2);

% Indices for each symbol
symbols = 0:numSymb-1;
symbolIndices = mod(symbols, lf);
P2Symbols = symbolIndices<nP2;

p2Syms=dataIn(:, P2Symbols);
p2_h_est = h_est(:, P2Symbols);

L1pre = p2Syms (1:L1preLen/nP2, 1:nP2); %Read L1-pre from first P2-symbol only
L1pre = reshape (L1pre.',[],1);

L1pre_h_est = p2_h_est (1:L1preLen/nP2, 1:nP2); 
L1pre_h_est = reshape (L1pre_h_est.',[],1);

L1preData = decodeL1pre(DVBT2, FidLogFile, L1pre, L1pre_h_est);

% Read L1 modulation
% L1mod=sprintf('%d',L1preData(25:28));

%Get L1 post cells
L1postSize=bin2dec(sprintf('%d',L1preData(33:50)));
L1postPerSym = L1postSize/nP2;
L1post = p2Syms (L1preLen/nP2+1:L1preLen/nP2+L1postPerSym,:);

L1post_h_est = p2_h_est (L1preLen/nP2+1:L1preLen/nP2+L1postPerSym,:);

%De-interleave and re-arrange L1-post into 1 column for each T2-frame
p2Idx = reshape(1:nP2*NUM_SIM_T2_FRAMES, nP2, NUM_SIM_T2_FRAMES)';
p2Idx = reshape(p2Idx, 1, []);
L1post = L1post (:,p2Idx);
L1post = reshape(L1post, [], nP2).';
L1post=reshape(L1post,[],NUM_SIM_T2_FRAMES);

L1post_h_est = L1post_h_est (:,p2Idx);
L1post_h_est = reshape(L1post_h_est, [], nP2).';
L1post_h_est=reshape(L1post_h_est,[],NUM_SIM_T2_FRAMES);

[L1postData nsr] =decodeL1post(DVBT2, FidLogFile, L1post, L1post_h_est);

fprintf (FidLogFile,'\t\tMER measured from L1-post is %.2f dB\n', -10*log10(nsr));

% Parse data
FEF = L1preData (16); %LSB of S2 field indicates whether FEFs are present
L1Data = parseL1 (L1postData, FEF, NUM_SIM_T2_FRAMES);
