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
%* Description : T2_TX_DVBT2BLP1PREAMB DVBT2 P1 Preamble Generator and insertion
%                                 
%******************************************************************************
function DataOut = t2_tx_dvbt2blp1preamb(DVBT2, FidLogFile,DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ; 
  otherwise,
    error('t2_tx_dvbt2blp1preamb SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
MODE        = DVBT2.MODE;          % Mode
MISO_ENABLED= DVBT2.MISO_ENABLED;
NFFT        = DVBT2.STANDARD.NFFT; % FFT number of points
GI_FRACTION = DVBT2.GI_FRACTION;
GI          = 1/GI_FRACTION; % Guard interval 
L_F         = DVBT2.STANDARD.L_F;     % Preamble Period (OFDM symbols)
SPEC_VERSION = DVBT2.SPEC_VERSION;

START_T2_FRAME = DVBT2.START_T2_FRAME;
NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES;

FEF_ENABLED = DVBT2.FEF_ENABLED;
FEF_S1      = DVBT2.FEF_S1; % S1 field for FEFs
FEF_S2      = DVBT2.FEF_S2; % S2 field for FEFs
FEF_LENGTH  = DVBT2.FEF_LENGTH;
FEF_INTERVAL= DVBT2.FEF_INTERVAL;
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

% Generate the S1 and S2 fields for the T2-frames
[t2s1 t2s2] = GenerateS1S2(DVBT2);

% Generate the p1 waveform for the T2-frames

p1Preamb = t2_tx_dvbt2blp1preamb_p1gen(t2s1, t2s2, DVBT2, FidLogFile);

% Generate the P1 waveform for the FEFs (if any)
if FEF_ENABLED
    p1PreambFEF = t2_tx_dvbt2blp1preamb_p1gen(FEF_S1, FEF_S2, DVBT2, FidLogFile);
end

% Preamble insertion

% Count how many FEF parts there will be
numFEFParts = sum(mod(1+(START_T2_FRAME:START_T2_FRAME+NUM_SIM_T2_FRAMES-1), FEF_INTERVAL)==0); % FEF is inserted after T2 frame FEF_INTERVAL-1

nCP = fix(NFFT/GI); % Number of samples of cyclic prefix

p1Len = length(p1Preamb);

t2FrameInputSamples = L_F * (NFFT+nCP);
t2FrameOutputSamples = t2FrameInputSamples + p1Len;
fefPartInputSamples = FEF_LENGTH - p1Len;
fefPartOutputSamples = FEF_LENGTH;

numOutputSamples = NUM_SIM_T2_FRAMES * t2FrameOutputSamples + numFEFParts * fefPartOutputSamples;

if (MISO_ENABLED)
    misoGroups = 2;
else
    misoGroups = 1;
end

DataOut = cell(2,1);

for misoGroup = 1:misoGroups

    
    % If FRAME_LEN=0 only premables are tx
    if (L_F == 0)
      numPreamb = NUM_SIM_T2_FRAMES;
      p1Preambs = repmat (p1Preamb.',numPreamb,1);
      DataOut{misoGroup} = p1Preambs;

    else
      DataOut{misoGroup} = zeros(numOutputSamples, 1);
      wrpos = 1;
      rdpos = 1;
      
      for frame=START_T2_FRAME:START_T2_FRAME+NUM_SIM_T2_FRAMES-1
          DataAux = DataIn{misoGroup}(rdpos:rdpos+t2FrameInputSamples-1).';
          if p1Len>NFFT+nCP
              DataAux = reshape(DataAux, NFFT+nCP, []); % one col per symbol
              DataAux = [DataAux; repmat(NaN, p1Len-(NFFT+nCP), size(DataAux,2))];
              DataAux = reshape(DataAux,1,[]);
              blockLen = p1Len;
          else
              blockLen = NFFT+nCP;
          end
          % Insert P1 preamble into the tx data, padded with NaNs to make 
          % the P1 the same length as the other symbols - these will be removed
          % after writing the V&V vector

          DataAux = [p1Preamb repmat(NaN, 1, blockLen-p1Len) DataAux];
          
          if (MISO_ENABLED)
              write_vv_test_point(DataAux, blockLen, L_F+1, sprintf('19Tx%d',misoGroup), 'complex', DVBT2, 1, frame+1);
          else
              write_vv_test_point(DataAux, blockLen, L_F+1, '19', 'complex', DVBT2, 1, frame+1);
          end
          
          DataOut{misoGroup}(wrpos:wrpos+t2FrameOutputSamples-1) = DataAux(~isnan(DataAux));
          wrpos = wrpos + t2FrameOutputSamples;
          rdpos = rdpos + t2FrameInputSamples;                    
          
          if FEF_ENABLED && mod(frame+1, FEF_INTERVAL) == 0
              % Insert a FEF and a FEF preamble. One or the other will be padded with NaNs
              % as we don't know which will be longer
              blockLen = max(p1Len, FEF_LENGTH-p1Len);
              DataAux = DataIn{misoGroup}(rdpos:rdpos+fefPartInputSamples-1).';
              DataAux = [p1PreambFEF repmat(NaN, 1, blockLen - p1Len) DataAux repmat(NaN, 1, blockLen-FEF_LENGTH)];
              
              if (MISO_ENABLED)
                  write_vv_test_point(DataAux, blockLen, 2, sprintf('19Tx%d',misoGroup), 'complex', DVBT2, 1, frame+1.5);
              else
                  write_vv_test_point(DataAux, blockLen, 2, '19', 'complex', DVBT2, 1, frame+1.5);
              end

              DataOut{misoGroup}(wrpos:wrpos+fefPartOutputSamples-1)= DataAux(~isnan(DataAux));
              wrpos = wrpos + fefPartOutputSamples;
              rdpos = rdpos + fefPartInputSamples;
          end
      end
    end
      

    % Report info
    % Power information calculation and reporting
    pData = mean(DataIn{misoGroup}.*conj(DataIn{misoGroup}));
    pPreamb = mean(abs(p1Preamb).^2);
    parPreamb = 10*log10(max(abs(p1Preamb).^2)/pPreamb);
    parData = 10*log10(max(abs(DataIn{misoGroup}).^2)/pData);

    fprintf(FidLogFile,'\t\tFrame Length: %d (OFDM symbols)\n',L_F);
    fprintf(FidLogFile,'\t\tP1 Average Power: %1.3e\n',pPreamb);
    fprintf(FidLogFile,'\t\tData Average Power: %1.3e\n',pData);
    fprintf(FidLogFile,'\t\tP1/Data Power: %.2f\n',(pPreamb/pData));
    fprintf(FidLogFile,'\t\tP1 PAPR: %.2f dB\n',parPreamb);
    fprintf(FidLogFile,'\t\tData PAPR: %.2f dB\n',parData);
    fprintf(FidLogFile,'\t\tP1-Data PAPR: %.2f dB\n',(parPreamb-parData));
end

%Write IQ file (if enabled)
write_iq_file(FidLogFile, DataOut{1}, DVBT2);