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
%* Description : t2_tx_dvbt2blp1preamb_p1gen DVBT2 P1 generator
%******************************************************************************
function p1Preamb = t2_tx_dvbt2blp1preamb_p1gen(s1, s2, DVBT2, FidLogFile)

AC_IDX      = DVBT2.STANDARD.AC_IDX;
MSS1_HEX    = DVBT2.STANDARD.MSS1_HEX;
MSS2_HEX    = DVBT2.STANDARD.MSS2_HEX;

p1Cps   = 853;  % P1 carriers per symbol (1k)
p1Ac    = 384;  % P1 active carrires
p1NFFT  = 1024; % P1 NFFT length (A)
p1CBLen = 512;  % P1 GIs (C & B) length
p1k     = 30;   % K length (samples)
fsh     = 1;    % Frequency shift (carriers)
mss1Len = 64;   % Length of the mss-1 (baseband samples)
mss2Len = 256;  % Length of the mss-2 (baseband samples)

p1Len = p1NFFT + 2*p1CBLen;

% Scrambler PRBS generation
Prbs = zeros(1,p1Ac); % initialize output
x = [1 0 0 1 1 1 0 0 1 0 0 0 1 1 0];
for k = 1:p1Ac 
  xNext(1) = xor(x(14),x(15));  
  xNext(2:15) = x(1:14);      % PG (X)=1+X^14+X^15
  x = xNext;
  Prbs(k) = x(1);
end
Prbs = double(Prbs);
Prbs(Prbs==0) = -1;
Prbs = Prbs.*-1;
 
% MSS hex2bin
mss1Hex = MSS1_HEX(s1+1,:);
mss2Hex = MSS2_HEX(s2+1,:);

mss1 = strcat(dec2bin(hex2dec(mss1Hex(1:8)),32),dec2bin(hex2dec(mss1Hex(9:16)),32));

mss2 = [];
for k=1:8:64
  mss2 = strcat(mss2,dec2bin(hex2dec(mss2Hex(k:k+7)),32));
end


% Sequences concatenation
mssConcat = double([mss1=='1' mss2=='1' mss1=='1']);

% DBPSK modulation
mssDBPSK=[1 zeros(1,length(mssConcat))];
for k=2:length(mssDBPSK)
  if mssConcat(k-1)==1
    mssDBPSK(k)= -mssDBPSK(k-1);
  else
    mssDBPSK(k)= mssDBPSK(k-1);
  end
end
mssDBPSK=mssDBPSK(2:end);

% Scrambler
mssDBPSK = mssDBPSK.*Prbs;

% Modulate the CDS sequence with the concatenation of MSS sequences
p1Freq = zeros(1,p1Cps);
p1Freq(AC_IDX+1) = mssDBPSK;

% Padding to 1k symbol
p1Freq1k = [zeros(1,86) p1Freq zeros(1,85)]; % C_LOC 1k = 87:939

% Time domain (IFFT)
p1Time = 1/sqrt(384)*p1NFFT.*ifft(fftshift(p1Freq1k),p1NFFT);

% Frequency shift
p1TimeCB = circshift(p1Freq1k,[0,fsh]);
p1TimeCB = 1/sqrt(384)*p1NFFT.*ifft(fftshift(p1TimeCB),p1NFFT);

% Generate the CAB structure
p1Preamb = [p1TimeCB(1:p1CBLen+p1k) p1Time p1TimeCB(p1CBLen+p1k+1:end)];

fprintf(FidLogFile,'\t\tP1 Preamb type: CAB-K structure. K = %d\n',p1k);
fprintf(FidLogFile,'\t\tP1 Scrambling after DBPSK\n');
fprintf(FidLogFile,'\t\tCB Fsh: %d carriers\n',fsh);


end
