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
%* Description : T2_RX_DVBT2BLP1PREAMB DVBT2 P1 PREAMBLE EXTRACTION
%******************************************************************************
function DataOut = t2_rx_dvbt2blp1preamb(DVBT2,FidLogFile,DataIn)


%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_rx_dvbt2blp1preamb SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
NFFT       = DVBT2.STANDARD.NFFT; % FFT number of points
GI         = 1/DVBT2.GI_FRACTION; % Guard interval 
FRAME_LEN  = DVBT2.STANDARD.L_F;           % Frame length in symbols
START_T2_FRAME = DVBT2.START_T2_FRAME;
NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES; % number of T2 Frames
FEF_ENABLED = DVBT2.FEF_ENABLED;
FEF_LENGTH  = DVBT2.FEF_LENGTH;
FEF_INTERVAL= DVBT2.FEF_INTERVAL;
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
%numofdmsymb = floor(NUM_FBLOCK*NLDPC/(V*DCPS));

% OPH: I may have removed too much! It now assumes that whole T2Frames are
% present at the input.

p1Length = 2048;

if ~FEF_ENABLED
    FEF_LENGTH = 0;
    FEF_INTERVAL = 1;
end

nCP = NFFT / GI;
samplesPerT2Frame = p1Length+FRAME_LEN*(NFFT+nCP);

% If FRAME_LEN=0 only premables are tx
if (FRAME_LEN == 0)
  DataOut = [];
  
else
  % Remove the FEFs
  DataAux = zeros(samplesPerT2Frame * NUM_SIM_T2_FRAMES, 1);
  
  rdIdx = 1;
  wrIdx = 1;
  for m = START_T2_FRAME:START_T2_FRAME+NUM_SIM_T2_FRAMES-1
      DataAux(wrIdx:wrIdx+samplesPerT2Frame-1) = DataIn.data(rdIdx:rdIdx+samplesPerT2Frame-1);
      rdIdx = rdIdx + samplesPerT2Frame;
      wrIdx = wrIdx + samplesPerT2Frame;
      if mod(1+m, FEF_INTERVAL)==0
          rdIdx = rdIdx + FEF_LENGTH;
      end
  end
  
  numPreamb = NUM_SIM_T2_FRAMES;
  
  DataAux = reshape(DataAux, samplesPerT2Frame, numPreamb).';

  % Extract preambles to the rx data
  DataAux = DataAux(:,p1Length+1:end);
  
  % Output format
  DataOut.data = reshape(DataAux.',size(DataAux,1)*size(DataAux,2),1);
end


