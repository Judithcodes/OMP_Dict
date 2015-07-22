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
%* Description : T2_TX_DVBT2BLFEF DVBT2 FEF Generator and insertion
%                                 
%******************************************************************************
function DataOut = t2_tx_dvbt2blfef(DVBT2, FidLogFile,DataIn)

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
MISO_ENABLED= DVBT2.MISO_ENABLED;
NFFT        = DVBT2.STANDARD.NFFT; % FFT number of points
GI_FRACTION = DVBT2.GI_FRACTION;
GI          = 1/GI_FRACTION; % Guard interval 
L_F         = DVBT2.STANDARD.L_F;     % Preamble Period (OFDM symbols)

START_T2_FRAME = DVBT2.START_T2_FRAME;
NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES;

FEF_ENABLED = DVBT2.FEF_ENABLED;
FEF_LENGTH  = DVBT2.FEF_LENGTH;
FEF_INTERVAL= DVBT2.FEF_INTERVAL;

P1LEN = DVBT2.STANDARD.P1LEN;
FEF_VARIETY = DVBT2.FEF_VARIETY;
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

% Count how many FEF parts there will be
numFEFParts = sum(mod(1+(START_T2_FRAME:START_T2_FRAME+NUM_SIM_T2_FRAMES-1), FEF_INTERVAL)==0); % FEF is inserted after T2 frame FEF_INTERVAL-1

nCP = fix(NFFT/GI); % Number of samples of cyclic prefix

t2FrameSamples = L_F * (NFFT+nCP);

if (FEF_ENABLED)
    fefPartSamples = FEF_LENGTH - P1LEN;
else
    fefPartSamples = 0;
end

numOutputSamples = NUM_SIM_T2_FRAMES * t2FrameSamples + numFEFParts * fefPartSamples;

numFEFSamples = numFEFParts * fefPartSamples;

if (MISO_ENABLED)
    misoGroups = 2;
else
    misoGroups = 1;
end

DataOut = cell(2,1);

fprintf(FidLogFile,'\t\t%s FEF\n', FEF_VARIETY);

switch FEF_VARIETY
    case 'NULL'
        fefPart = zeros(1, numFEFSamples);
    case 'TXSIG'
        fefPart = t2_tx_dvbt2blfef_maketxsigfef(DVBT2, numFEFParts, FidLogFile);
    case 'PRBS'
        fefPart = t2_tx_dvbt2blfef_makeprbsfef(DVBT2, numFEFSamples, FidLogFile);
    otherwise
        error('Unknown FEF variety %s', FEF_VARIETY);
end

for misoGroup = 1:misoGroups

  DataOut{misoGroup} = zeros(numOutputSamples, 1);
  wrpos = 1;
  rdpos = 1;
  rdposFEF = 1;

  for frame=START_T2_FRAME:START_T2_FRAME+NUM_SIM_T2_FRAMES-1
      DataAux = DataIn{misoGroup}(rdpos:rdpos+t2FrameSamples-1).';

      if (MISO_ENABLED)
          write_vv_test_point(DataAux, NFFT+nCP, L_F, sprintf('18aTx%d',misoGroup), 'complex', DVBT2, 1, frame+1);
      else
          write_vv_test_point(DataAux, NFFT+nCP, L_F, '18a', 'complex', DVBT2, 1, frame+1);
      end

      DataOut{misoGroup}(wrpos:wrpos+t2FrameSamples-1) = DataAux;
      wrpos = wrpos + t2FrameSamples;
      rdpos = rdpos + t2FrameSamples;

      if FEF_ENABLED && mod(frame+1, FEF_INTERVAL) == 0
          % Insert a FEF 
          DataAux = fefPart(rdposFEF:rdposFEF+fefPartSamples-1);

          if (MISO_ENABLED)
              write_vv_test_point(DataAux, fefPartSamples, 1, sprintf('18aTx%d',misoGroup), 'complex', DVBT2, 1, frame+1.5);
          else
              write_vv_test_point(DataAux, fefPartSamples, 1, '18a', 'complex', DVBT2, 1, frame+1.5);
          end

          DataOut{misoGroup}(wrpos:wrpos+fefPartSamples-1)= DataAux(~isnan(DataAux));
          rdposFEF = rdposFEF + fefPartSamples;
          wrpos = wrpos + fefPartSamples;
      end
   end
      


end
