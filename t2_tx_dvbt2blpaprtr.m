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
%* Description : T2_TX_DVBT2BLPAPRTR DVBT Tone-reservation PAPR
%*               DOUT = T2_TX_DVBT2BLPAPRTR(DVBT2, FID, DIN) takes
%*               time-domain symbols without GIs, and applies the tone
%*               reservation technique. FID specifies
%*               the file where any debug message is sent.  
%******************************************************************************

function DataOut = t2_tx_dvbt2blpaprtr(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2blpaprtr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
	MODE        = DVBT2.MODE;                % Mode
	NFFT        = DVBT2.STANDARD.NFFT;       % FFT size
	EXTENDED    = DVBT2.EXTENDED;            % Extended BW mode
	K_EXT       = DVBT2.STANDARD.K_EXT;      % Extra carriers each side in ext BW mode
	C_LOC    = DVBT2.STANDARD.C_LOC;         % Carriers location
	SP_PATTERN  = DVBT2.SP_PATTERN;          % Scattered pilot pattern
	C_DATA      = DVBT2.STANDARD.C_DATA;     % Data carriers per symbol
	N_FC        = DVBT2.STANDARD.N_FC;       % Data carriers per FC symbol
	C_P2        = DVBT2.STANDARD.C_P2;       % Data carriers per P2 symbol
	C_PS        = DVBT2.STANDARD.C_PS;       % Carriers per symbol
	L_F         = DVBT2.STANDARD.L_F;                 % Symbols per frame
	N_P2        = DVBT2.STANDARD.N_P2;       % P2 symbols per frame
	L_FC        = DVBT2.STANDARD.L_FC;       % P2 symbols per frame
	PN_SEQ      = DVBT2.STANDARD.PN_SEQ;     % PN sequence
	SP_LOC      = DVBT2.STANDARD.SP_LOC;     % Scattared pilots locations
	SP_PATTLEN  = DVBT2.STANDARD.SP_PATTLEN; % Scattered pilots pattern length
	SP_DX       = DVBT2.STANDARD.SP_DX;      % Scattered pilots SP-bearing carrier spacing (x)
	CP_LOC      = DVBT2.STANDARD.CP_LOC;     % Continual pilots locations
	EDGE_LOC    = DVBT2.STANDARD.EDGE_LOC;   % Edge pilots locations
	P2P_LOC     = DVBT2.STANDARD.P2P_LOC;    % P2 pilots locations
	FCP_LOC     = DVBT2.STANDARD.FCP_LOC;    % FC pilots locations

	P2_TR_LOC   = DVBT2.STANDARD.P2_TR_LOC;  % P2 reserved tones locations
	NORM_TR_LOC = DVBT2.STANDARD.TR_LOC;     % normal symbol reserved tones locations
	FC_TR_LOC   = DVBT2.STANDARD.FC_TR_LOC;  % Frame closing symbol reserved tones locations

	MISO_ENABLED = DVBT2.MISO_ENABLED;       % Is MISO being used?

	TR_ENABLED    = DVBT2.TR_ENABLED; % is tone reservation used?
	TR_ITERATIONS = DVBT2.TR_ITERATIONS; % Number of iterations of tone reservation technique
	TR_V_CLIP        = DVBT2.TR_V_CLIP; % Clipping level for tone reservation technique

	SPEC_VERSION = DVBT2.SPEC_VERSION; % version of spec determines whether P2 PAPR is done
	%------------------------------------------------------------------------------
	% Procedure
	%------------------------------------------------------------------------------

	peakTolerance = 0; %0.001;

	if (MISO_ENABLED)
	    misoGroups = 2;
	else
	    misoGroups = 1;
	end

	if (strcmp(SPEC_VERSION, '1.0.1') || strcmp(SPEC_VERSION, '1.1.1'))
	    P2Only = false;
	elseif ~TR_ENABLED
	    P2Only = true; % From version 1.2.1 onwards do TR in P2 even if TR disabled
	    TR_ENABLED = true;
	else
	    P2Only = false;
	end

fprintf(FidLogFile,'\t\tMode=%s\n', MODE);

for misoGroup = 1:misoGroups
    % Process the relevant input vector
    dataAux = DataIn{misoGroup}.';
    dataAux = dataAux(:);

    % Transmit only complete symbols
    numSymb   = floor(length(dataAux)/NFFT); 
    dataAux   = dataAux(1:numSymb*NFFT);
    numFrames = floor(length(dataAux)/(L_F*NFFT));
    numP2Symb = numFrames*N_P2;
    p2MeanPower = 0;
    dataMeanPower = 0;

    dataAux   = reshape(dataAux, NFFT, numSymb).';

    fprintf(FidLogFile,'\t\tNumber of complete frames: %d (%d symbols per frame)\n', numFrames, L_F);
    fprintf(FidLogFile,'\t\tNumber of transmitted symbols: %d\n', numSymb);
    fprintf(FidLogFile,'\t\tScattered pilots pattern: %s\n', SP_PATTERN);

    if TR_ENABLED
      if P2Only
        fprintf(FidLogFile,'\t\tP2 only TR\n');
      end

      % Initialise output
      symbols = dataAux;
      
      % Initialise statistics
      paprAchievedCount=0; paprMaxIterationsReachedCount=0; paprMaxCarrierPowerReachedCount=0; maxPAPR=0; maxReservedCarrierPower=0;paprNotProcessedCount=0;

      for symbIdx=1:numSymb   % for each symbol
         symbInFrame = mod(symbIdx-1, L_F);

         % Calculate the TR locations
         if (symbInFrame<N_P2) % It's a P2 symbol
             currTRLoc = P2_TR_LOC; % Set tone reservation locations
             if (EXTENDED)
                 currTRLoc = currTRLoc + K_EXT;
             end

         elseif (symbInFrame == L_F-L_FC)
             currTRLoc= FC_TR_LOC; % Set tone reservation locations
             if (EXTENDED)
                 currTRLoc = currTRLoc + K_EXT;
             end

         else
             if EXTENDED
                 currTRLoc = NORM_TR_LOC + SP_DX*mod(symbInFrame+K_EXT/SP_DX, SP_PATTLEN); % Set tone reservation locations
             else
                 currTRLoc = NORM_TR_LOC + SP_DX*mod(symbInFrame, SP_PATTLEN); % Set tone reservation locations
             end
         end

        %Define reserved carriers & set data to zero at these positions(using first specified pilot phase of PP1)

        NTR = length(currTRLoc);
        %currTRPhysCarriers = (currTRLoc-1)-(C_PS-1)/2; % k' values for carriers

        %zero data at reserved tone positions

        %Define kernel

        oneTR=zeros(C_PS,1);
        oneTR(currTRLoc) = 1;

        %re-arrange & pad signal and oneTR signals for ifft
        oneTR_pad=zeros(NFFT,1);
        oneTR_pad(C_LOC)=oneTR;
        oneTR_pad = fftshift(oneTR_pad);

        p=NFFT/NTR*ifft(oneTR_pad);
        time_unproc=symbols(symbIdx,:).';    %   nfft*ifft(freq_pad)/sqrt(C_PS-NTR);

        %For reference, IFFT was DataOut{misoGroup} = 5/sqrt(27*C_PS)*NFFT*ifft(fftDI, NFFT, 2);
         if (symbInFrame<N_P2 && P2Only)
             numIterations=1; % only do 1 iteration if doing P2-only TR
             flag = 0;
         elseif (P2Only)
             numIterations = 0; % don't do any iterations if it's not a P2 symbol and we are doing P2-only PAPR
             flag = 3;
         else
             numIterations = TR_ITERATIONS;
             flag = 0;
         end

        %Peak reduction loop

        c=zeros(NFFT,1);  %peak reduction signal
        r=zeros(NTR,1);  % reserved tones vector


        %fprintf(FidLogFile, 'Tone reservation: initial max peak = %f dB\n',20*log10(max(abs(time_unproc))));

        for k=1:numIterations

            [y,m1]=max(abs(time_unproc+c));
            m = m1-1; % m as defined in spec is zero-based
            
            %fprintf(FidLogFile, 'Iteration %d: max peak = %f dB\n',k, 20*log10(y));

            %if y<1.01*TR_V_CLIP
            if y<(1+peakTolerance)*TR_V_CLIP

                %fprintf(FidLogFile,'Convergence to within %f%% of Vclip after %d iterations\n',peakTolerance*100,k);
                flag=1;
                break
            end

            u=(time_unproc(m+1)+c(m+1))/y; % unit vector in direction of peak
            alpha = (y-TR_V_CLIP); % magnitude of peak above clipping level
            
            % Calc new F.D. coefficients   
            centreTRLoc = (C_PS-1)/2+1; % 1-based location of centre (DC) carrier
            v = u * exp(-j*2*pi*m*(currTRLoc.'-centreTRLoc)/NFFT);
            
            rNew = r - alpha * v;          
            
            aMax = 5*NTR*sqrt(10/(27*C_PS));

            %alphaLimit = sqrt(aMax^2-imag(conj(v).*r).^2)-real(conj(v).*r); 
            alphaLimit = sqrt(aMax^2-imag(conj(v).*r).^2)+real(conj(v).*r); 
            alphaLimit = alphaLimit(abs(rNew)>aMax); % calculation only applies to carriers whose magnitude exceeded the limit
            
            if ~isempty(alphaLimit)
                alpha = min(alphaLimit);
                rNew = r - alpha * v;
            end
            
            if (flag==2 && alpha>0)
                fprintf(FidLogFile,'Doing another iteration with alpha=%e despite limiting in a previous it\n',alpha);
            end
            % update peak reduction vector
            c=c-(u*alpha)*circshift(p,m);
            
            % update F.D. coefficients
            r = rNew;
            
            if ~isempty(alphaLimit)
                fprintf(FidLogFile,'%d TR carrier(s) reached peak amplitude after %d its\n',length(alphaLimit), k);
                flag=2;
                %break; % terminate once any TR coefficient reaches the maximum amplitude.
            end
        end

        symbols(symbIdx,:) = time_unproc+c;
        
        if flag==0
            %paprAchievedCount=0; paprMaxIterationsReachedCount=0; paprMaxCarrierPowerReachedCount=0; maxPAPR=0; maxReservedCarrierPower=0;
            paprMaxIterationsReachedCount=paprMaxIterationsReachedCount+1;
        elseif flag==1
            paprAchievedCount=paprAchievedCount+1;
        elseif flag==2
            paprMaxCarrierPowerReachedCount=paprMaxCarrierPowerReachedCount+1;
        elseif flag==3
            paprNotProcessedCount=paprNotProcessedCount+1;
            %fprintf(FidLogFile,'No convergence after %d iterations\n',k);
        end
        %fprintf(FidLogFile, 'Tone reservation: final max peak = %f dB\n',20*log10(max(abs(time_unproc+c))));
        maxPAPR=max(maxPAPR, 20*log10(max(abs(time_unproc+c))));

        % Check on max magnitude of TR cells
        %cFreqDomain = 1/sqrt(NFFT)*fft(c);
        %cFreqDomain = 1/sqrt(NFFT)*fft(c);
        cFreqDomain =(sqrt(27*C_PS)/(5*NFFT))*fft(c);
        %fprintf(FidLogFile, 'Max reserved tone power = %f\n', max(abs(cFreqDomain).^2));
        maxReservedCarrierPower=max(maxReservedCarrierPower, max(abs(cFreqDomain).^2));

        if (symbInFrame<N_P2) % It's a P2 symbol
            p2MeanPower = p2MeanPower + mean(abs(symbols(symbIdx,:)).^2);
        else
            dataMeanPower = dataMeanPower + mean(abs(symbols(symbIdx,:)).^2);
        end
      end
      p2MeanPower = p2MeanPower / numP2Symb;
      dataMeanPower = dataMeanPower / (numSymb - numP2Symb);
      fprintf(FidLogFile, '%d symbols, %d achieved target, %d reached max iterations, %d reached max tone power %d were not processed\n',numSymb, paprAchievedCount, paprMaxIterationsReachedCount, paprMaxCarrierPowerReachedCount,paprNotProcessedCount);
      fprintf(FidLogFile, 'Final max peak = %f dB, max reserved tone power = %d\n', maxPAPR, maxReservedCarrierPower);
      fprintf(FidLogFile, 'Power of P2 symbols wrt rest of data is %.2f (dB)\n',10*log10(p2MeanPower/dataMeanPower));
    else
      symbols = dataAux;
    end
           
    % Write V&V point
    if (MISO_ENABLED)
        write_vv_test_point(symbols.', NFFT, L_F, sprintf('17Tx%d',misoGroup), 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)
    else
        write_vv_test_point(symbols.', NFFT, L_F, '17', 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)
    end

    DataOut{misoGroup} = symbols;
end



