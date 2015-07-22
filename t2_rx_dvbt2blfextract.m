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
%* Description : T2_RX_DVBT2BLFEXTRACT DVBT2 Frame extraction
%*               DOUT = T2_RX_DVBT2BLFEXTRACT(DVBT2, FID, DIN) extracts the PLP 
%*               cells following the configuration parameters of the DVBT2 structure.
%*               FID specifies the file identifier where any debug message is 
%*               sent.
%******************************************************************************

function DataOut = t2_rx_dvbt2blfextract(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2blfextract SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------

START_T2_FRAME = DVBT2.START_T2_FRAME;
NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES; % Number of T2 frames to simulate

L_F = DVBT2.STANDARD.L_F; % Number of symbols per T2 frame
N_P2 = DVBT2.STANDARD.N_P2; % Number of P2 symbols per T2-frame
L_FC = DVBT2.STANDARD.L_FC; % Number of Frame Closing symbols

C_DATA = DVBT2.STANDARD.C_DATA; % Active cells per symbol
C_P2 = DVBT2.STANDARD.C_P2; % Active cells per P2 symbol
C_FC = DVBT2.STANDARD.C_FC; % Active cells in Frame closing symbol
N_FC = DVBT2.STANDARD.N_FC; % Data cells in Frame closing symbol including thinning cells

D_L1PRE = DVBT2.STANDARD.D_L1PRE; % Number of L1-pre signalling cells per T2 frame
D_L1POST = DVBT2.STANDARD.D_L1POST; % Number of L1-post signalling cells per T2 frame

NUM_PLPS = DVBT2.NUM_PLPS;
NUM_SUBSLICES = DVBT2.NUM_SUBSLICES;

PLP        = DVBT2.RX_PLP; % PLP number to decode


%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
data = DataIn.data;
h_est = DataIn.h_est;
SCHED = DataIn.sched;

numSymbols = NUM_SIM_T2_FRAMES * L_F; % Total number of symbols

symbolIndexInFrame = mod(0:numSymbols-1, L_F);

data = reshape(data, C_DATA, numSymbols); % each column is one symbol
h_est = reshape(h_est, C_DATA, numSymbols); % each column is one symbol

D_L1 = D_L1PRE + D_L1POST; % Total L1 cells

% Mark the extra cells not used in P2 and FCS
data(C_P2+1:C_DATA, symbolIndexInFrame<N_P2) = NaN; % P1

% Only do the following step when C_FC gives a potentially valid result,
% otherwise it will fail! NB Not all valid values of C_FC mean that there
% is a FC symbol. If there is no FCS, L_FC=0, so the test symbolIndexInFrame==L_F-L_FC
% will always be false
if (C_FC>0)
    data(C_FC+1:C_DATA, symbolIndexInFrame==L_F-L_FC) = NaN; % Frame closing
end

% Mark the L1 signalling
data(1:D_L1/N_P2, symbolIndexInFrame<N_P2) = NaN;

% extract everything else
h_est = h_est(~isnan(data)); % Extract channel response based on the NaNs in data
data = data(~isnan(data));

% Make a matrix with one column for each T2 frame
frameData = reshape(data, [], NUM_SIM_T2_FRAMES);
frame_h_est = reshape(h_est, [], NUM_SIM_T2_FRAMES);

sliceLengths = SCHED.sliceLengths(:,START_T2_FRAME+1:START_T2_FRAME+NUM_SIM_T2_FRAMES); % Pick out only the T2-frames we are processing this time
subsliceIntervals = SCHED.subsliceIntervals(:,START_T2_FRAME+1:START_T2_FRAME+NUM_SIM_T2_FRAMES);
startAddresses = SCHED.startAddresses(:,START_T2_FRAME+1:START_T2_FRAME+NUM_SIM_T2_FRAMES);
subsliceLengths = SCHED.subsliceLengths(:,START_T2_FRAME+1:START_T2_FRAME+NUM_SIM_T2_FRAMES);

sliceStarts = cumsum(sliceLengths, 2);
sliceStarts = [zeros(NUM_PLPS,1) sliceStarts(:,1:NUM_SIM_T2_FRAMES-1)] + 1; % Start indices of slices in the output data
sliceEnds = sliceStarts + sliceLengths(:,1:NUM_SIM_T2_FRAMES) - 1;% End indices of slices in the output data

data = zeros(sum(sliceLengths(PLP,:), 2),1); % Make vector to hold the extracted PLP cells
h_est = zeros(sum(sliceLengths(PLP,:), 2),1); % Make vector to hold the extracted channel values

for frameIdx = 1:NUM_SIM_T2_FRAMES
    % Extract the wanted PLP from the correct address
    subsliceInterval = subsliceIntervals(frameIdx);
    
    start = startAddresses(PLP,frameIdx); % Start frame address for first (or only) subslice
    len = subsliceLengths(PLP,frameIdx); % Length of subslice

    if DVBT2.PLP(PLP).PLP_TYPE == 2 % Type 2 PLP
        for ss = 0:NUM_SUBSLICES-1
            subsliceData = frameData(start+ss*subsliceInterval+1:start+ss*subsliceInterval+len,frameIdx);
            data(sliceStarts(PLP,frameIdx)+ss*len:sliceStarts(PLP,frameIdx)+(ss+1)*len-1) = subsliceData.'; % Get slice from the input
            subsliceH = frame_h_est(start+ss*subsliceInterval+1:start+ss*subsliceInterval+len,frameIdx);
            h_est(sliceStarts(PLP,frameIdx)+ss*len:sliceStarts(PLP,frameIdx)+(ss+1)*len-1) = subsliceH.'; % Get slice from the input
        end
    else % Type 1 or common PLP - one subslice only
        data(sliceStarts(PLP,frameIdx):sliceEnds(PLP,frameIdx)) = frameData(start+1:start+len,frameIdx);
        h_est(sliceStarts(PLP,frameIdx):sliceEnds(PLP,frameIdx)) = frame_h_est(start+1:start+len,frameIdx);
    end

end
    

fprintf(FidLogFile,'\t\tT2 Frames Extracted = %d\n', NUM_SIM_T2_FRAMES);

DataOut.data  = data(:);
DataOut.h_est = h_est(:);
DataOut.sched = SCHED;

