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
%* Description : T2_TX_DVBT2BLMADAPT_INBANDGEN
%*
%******************************************************************************

function inBandField = t2_tx_dvbt2blmadapt_inbandgenA(DVBT2, SCHED, plp, ILFrameIndex)

P_I = DVBT2.PLP(plp).P_I;
I_JUMP = DVBT2.PLP(plp).I_JUMP;
FIRST_FRAME_IDX = DVBT2.PLP(plp).FIRST_FRAME_IDX;
OTHER_PLP_IN_BAND = DVBT2.PLP(plp).OTHER_PLP_IN_BAND;

NBLOCKS      = SCHED.NBLOCKS{plp};       % Number of FEC blocks per Interleaving Frame

PADDING_TYPE = de2bi(0,2, 'left-msb');
PLP_L1_CHANGE_COUNTER = de2bi(0,8, 'left-msb');
RESERVED_1 = de2bi(0,8, 'left-msb');

inBandField = [PADDING_TYPE PLP_L1_CHANGE_COUNTER RESERVED_1];

PLPNumBlocks = NBLOCKS(ILFrameIndex+1+1);

for j=0:P_I-1 
  T2FrameIndex = (ILFrameIndex+1)*P_I*I_JUMP + FIRST_FRAME_IDX + j*I_JUMP; % Signal next Interleaving Frame
  SUB_SLICE_INTERVAL = de2bi(SCHED.subsliceIntervals(T2FrameIndex+1),22, 'left-msb');
  START_RF_IDX = de2bi(0,3, 'left-msb');
  if (PLPNumBlocks>0)
    PLPStart = SCHED.startAddresses(plp,T2FrameIndex+1);
  else
    PLPStart = 0;
  end
  CURRENT_PLP_START = de2bi(PLPStart, 22, 'left-msb');
  RESERVED_2 = de2bi(0,8, 'left-msb');
  inBandField = [inBandField SUB_SLICE_INTERVAL START_RF_IDX CURRENT_PLP_START RESERVED_2]; 
end

CURRENT_PLP_NUM_BLOCKS = de2bi(PLPNumBlocks, 10, 'left-msb');
NUM_OTHER_PLP_IN_BAND = de2bi(length(OTHER_PLP_IN_BAND),8, 'left-msb');

inBandField = [inBandField CURRENT_PLP_NUM_BLOCKS NUM_OTHER_PLP_IN_BAND];

for p = OTHER_PLP_IN_BAND
  assert (P_I == 1 && I_JUMP == 1);
  T2FrameIndex = ILFrameIndex+1; % Only signal other PLPs if P_I=I_JUMP=1, so T2 frame index same as interleaving frame index. But signalling is for next T2-frame so add 1

  PLP_ID = de2bi(DVBT2.PLP(p).PLP_ID, 8, 'left-msb');
  otherPLPNBlocks = DVBT2.PLP(p).NBLOCKS;
  otherPLPP_I = DVBT2.PLP(p).P_I;
  otherPLPIJump = DVBT2.PLP(p).I_JUMP;
  otherPLPFirstFrame = DVBT2.PLP(p).FIRST_FRAME_IDX;
  otherPLPStart = SCHED.startAddresses(p,T2FrameIndex+1);
  if length(otherPLPNBlocks) > 1 % Find the right frame to signal
    otherPLPNBlocks = otherPLPNBlocks(1+floor(T2FrameIndex/(otherPLPP_I*otherPLPIJump)));
  end
  if mod(T2FrameIndex-otherPLPFirstFrame, otherPLPIJump) ~= 0 % Set to 0 if it isn't mapped to the frame
    otherPLPNBlocks = 0;
    otherPLPStart = 0;
  end
  PLP_START = de2bi(otherPLPStart,22, 'left-msb');
  PLP_NUM_BLOCKS = de2bi(otherPLPNBlocks, 10,'left-msb');
  RESERVED_2 = de2bi(0,8,'left-msb');
  
  inBandField = [inBandField PLP_ID PLP_START PLP_NUM_BLOCKS RESERVED_2];
end

% Assume we need to add a loop for TYPE_2_START (currently there is only
% one entry
for j=0:P_I-1 
  T2FrameIndex = (ILFrameIndex+1)*P_I*I_JUMP + FIRST_FRAME_IDX + j*I_JUMP; % Signal next Interleaving Frame
  if SCHED.subsliceIntervals(T2FrameIndex+1)==0 % no cells in this frame for type 2 PLPs
        type2Start = 0;
  else
    type2Start = SCHED.type2Starts(T2FrameIndex+1);
  end
  
  TYPE_2_START = de2bi(type2Start,22, 'left-msb');
  inBandField = [inBandField TYPE_2_START];
end
