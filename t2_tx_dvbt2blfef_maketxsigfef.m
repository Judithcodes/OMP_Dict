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
%* Description : t2_tx_dvbt2blfef_maketxsigfef DVBT2 TX-SIG FEF generator
%******************************************************************************
function fefData = t2_tx_dvbt2blfef_maketxsigfef(DVBT2, numFEFs, FidLogFile)

FEF_LENGTH = DVBT2.FEF_LENGTH;
P1LEN = DVBT2.STANDARD.P1LEN;
ID1 = DVBT2.TXID.ID1;
ID2 = DVBT2.TXID.ID2;

m=1024; n=8; d=1;
N = m*n*n;

cpSamples = 14546;

% Make the Frank sequence
q=0:m-1;

c=exp(1j*2*pi*floor(q/32).*mod(q,32)/32);

% Make the Hadamard sequence
b = hadamard(n);

% Make the intermediate GO sequences

    % Make matrix A

ii=repmat((0:n-1)', 1, m); % ii is row number (the i in expression for a_i,j)
jj=repmat(0:m-1, n, 1); % jj is column number

A = c(mod(jj*(n+d)+ii+d*floor((ii+1)/n), m) + 1); % Add 1 for matlab indexing

    % Read column-wise (equiv to transpose and read row-wise in ETSI)
u = A(:);

    % Form S'
sdash = repmat(u.', n, 1) .* repmat(b,1,m);

% Make final set of GO sequences
    % Read column-wise. (uu is the new u of 6.4.5)
uu = sdash(:); 

    % Form S
s = repmat(uu.', n, 1) .* repmat(b,1,m*n);

% 64K DFT

V = fft(s.'); % transpose and DFT each column (i.e. each sequence)

Vdash = fftshift(V,1);
kdash = (-N/2:N/2-1)';

% Filtering window
    % Generate window
Kh = 27264;
%W = 0.42+0.5*cos(pi * (kdash/Kh-1)) + 0.08*cos(2*pi*(kdash/Kh-1)); %Original
W = 0.42+0.5*cos(pi * kdash/Kh) + 0.08*cos(2*pi*kdash/Kh);
W(abs(kdash)>Kh) = 0;

    % Apply window
X = repmat(W, 1, n) .* Vdash;

% convert to time domain

coeffScale = 25*sqrt(1+2*Kh)/(1024*sqrt(648798));
overallScale = 1/sqrt(1+2*Kh);

x = N * overallScale * ifft(fftshift(coeffScale*X,1));

% add cyclic prefix
x = [x(end-cpSamples+1:end,:); x];

% generate V&V PRBS FEF data for "other use part"
otherUseLen = FEF_LENGTH-P1LEN-2*(N+cpSamples);
numFEFPartsPerSF = sum(mod(1+(0:DVBT2.N_T2-1), DVBT2.FEF_INTERVAL)==0);
numOtherUseSamplesPerSF = numFEFPartsPerSF*otherUseLen;

otherUseData = t2_tx_dvbt2blfef_makeprbsfefdata(DVBT2, numOtherUseSamplesPerSF, FidLogFile); %Make a superframe of data

numOtherUseSamples = numFEFs * otherUseLen;

%Calculate where we are in the SF - output is rotated, truncated version

startFEFIdx = mod(DVBT2.START_T2_FRAME, DVBT2.N_T2);

otherUseData = circshift(otherUseData, [0, -otherUseLen*startFEFIdx]);
otherUseData = repmat(otherUseData,1,ceil(numOtherUseSamples/numOtherUseSamplesPerSF)); % in case more than a superframe needed
otherUseData = otherUseData(1:numOtherUseSamples);

otherUseData = reshape(otherUseData, otherUseLen, []); %one col per FEF part

% Concatenate "other use period", first sig period and second sig period
%fefData = [zeros(1,otherUseLen) x(:,ID1).' x(:,ID2).']; % null other use period
fefData = [x(:,ID1+1); x(:,ID2+1)];
fefData = repmat(fefData, 1, numFEFs); % TxSig subpart of every FEF part is the same
fefData = [otherUseData; fefData]; % prepend other use period

fefData = fefData(:).';

end
