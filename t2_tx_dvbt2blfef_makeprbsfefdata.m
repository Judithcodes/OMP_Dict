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
%* Description : t2_tx_dvbt2blfef_makeprbsfefdata DVBT2 PRBS FEF data generator
%******************************************************************************
function fefData = t2_tx_dvbt2blfef_makeprbsfefdata(DVBT2, numFEFSamples, FidLogFile)

    AC_IDX      = DVBT2.STANDARD.AC_IDX;

    p1Cps   = 853;  % P1 carriers per symbol (1k)
    p1Ac    = 384;  % P1 active carrires
    fefNFFT  = 1024; % P1 NFFT length (A)
    
    numFFTs = ceil(numFEFSamples/fefNFFT);

    numPRBSBits = numFFTs * p1Ac;

    % Scrambler PRBS generation
    Prbs = zeros(1,numPRBSBits); % initialize output
    x = [1 0 0 1 1 1 0 0 1 0 0 0 1 1 0];
    for k = 1:numPRBSBits;
      xNext(1) = xor(x(14),x(15));  
      xNext(2:15) = x(1:14);      % PG (X)=1+X^14+X^15
      x = xNext;
      Prbs(k) = x(1);
    end
    Prbs = double(Prbs);
    Prbs(Prbs==0) = -1;
    Prbs = Prbs.*-1;

    Prbs = reshape(Prbs, p1Ac, numFFTs); % one col per FFT

    fefData = zeros(fefNFFT,numFFTs);

    for i=1:numFFTs


        % Modulate the CDS sequence with the concatenation of MSS sequences
        p1Freq = zeros(1,p1Cps);
        p1Freq(AC_IDX+1) = Prbs(:,i);

        % Padding to 1k symbol
        p1Freq1k = [zeros(1,86) p1Freq zeros(1,85)]; % C_LOC 1k = 87:939

        % Time domain (IFFT)
        p1Time = 1/sqrt(384)*fefNFFT.*ifft(fftshift(p1Freq1k),fefNFFT);

        %fprintf('FEF FFT %d PAPR = %fdB\n', i, 10*log10(max(abs(p1Time)).^2/mean(abs(p1Time).^2)));

        fefData(:,i) = p1Time.';

    end
    
    %truncate to exactly the number of samples required
    fefData = fefData(:);
    fefData = fefData(1:numFEFSamples);

end

