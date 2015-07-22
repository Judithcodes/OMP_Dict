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
%* Description : T2_TX_DVBT2BLFBUILD DVBT2 Frame builder
%*               DOUT = T2_TX_DVBT2BLFBUILD(DVBT2, FID, DIN) takes the
%                incoming data and generates the data cells of each T2 frame 
%                by inserting L1 signalling (currently
%                random) and dummy cells. The output has C_DATA cells for
%                each symbol, but for P2 and Frame closing symbols there
%                are NaNs at the end because those symbols have a lower
%                capacity.
%******************************************************************************

function DataOut = t2_tx_dvbt2blfbuild(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2blfbuild SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
L_F = DVBT2.STANDARD.L_F; % Number of symbols per T2 frame
N_P2 = DVBT2.STANDARD.N_P2; % Number of P2 symbols per T2-frame
L_FC = DVBT2.STANDARD.L_FC; % Number of Frame Closing symbols

C_DATA = DVBT2.STANDARD.C_DATA; % Active cells per symbol
C_P2 = DVBT2.STANDARD.C_P2; % Active cells per P2 symbol
C_FC = DVBT2.STANDARD.C_FC; % Active cells in Frame closing symbol
N_FC = DVBT2.STANDARD.N_FC; % Data cells in Frame closing symbol including thinning cells

START_T2_FRAME = DVBT2.START_T2_FRAME;
NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES;
NUM_PLPS = DVBT2.NUM_PLPS;
NUM_SUBSLICES = DVBT2.NUM_SUBSLICES;

NUM_AUX = DVBT2.NUM_AUX;

NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2 = DVBT2.NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2;
NUM_DUMMY_L1_BIAS_BALANCING_CELLS_PER_P2 = DVBT2.STANDARD.NUM_DUMMY_L1_BIAS_BALANCING_CELLS_PER_P2;
NUM_TOTAL_L1_BIAS_BALANCING_CELLS = DVBT2.STANDARD.NUM_TOTAL_L1_BIAS_BALANCING_CELLS;

L1_BIAS_BALANCING_CELLS_MAX_AMPLITUDE = DVBT2.L1_BIAS_BALANCING_CELLS_MAX_AMPLITUDE;

SCHED = DataIn.sched; % Scheduling information (now passed along the chain)


%--------------------------------------------------------------------------
% Initialisation
%--------------------------------------------------------------------------
global DVBT2_STATE;
if START_T2_FRAME == 0
    for plp=1:NUM_PLPS
        DVBT2_STATE.FBUILD.UNUSED_DATA{plp} = [];
    end
end

%------------------------------------------------------------------------------
% Procedure
%--------------------------------------------------------------------------

for plp=1:NUM_PLPS
    data{plp} = [DVBT2_STATE.FBUILD.UNUSED_DATA{plp} DataIn.data{plp}];
end

L1pre = DataIn.l1.pre;
L1post = DataIn.l1.post;

L1pre = reshape(L1pre, [], NUM_SIM_T2_FRAMES);
L1post = reshape(L1post, [], NUM_SIM_T2_FRAMES);
D_L1PRE = size(L1pre, 1);
D_L1POST = size(L1post, 1);
D_L1 = D_L1PRE + D_L1POST;


assert(D_L1 == (DVBT2.STANDARD.D_L1PRE + DVBT2.STANDARD.D_L1POST));

%%%
% Generate L1 bias balance cells (T2 spec clause 8.3.6.3.0)
if (NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2 > 0)
    C_bias = sum(L1pre,1) + sum(L1post,1);
    
    Cdash_bal = - C_bias ./ (N_P2 * NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2);
    C_bal = Cdash_bal; % row vector, one element per T2-frame
    C_bal(abs(C_bal) > L1_BIAS_BALANCING_CELLS_MAX_AMPLITUDE) = C_bal(abs(C_bal) > L1_BIAS_BALANCING_CELLS_MAX_AMPLITUDE) / abs(C_bal(abs(C_bal) > L1_BIAS_BALANCING_CELLS_MAX_AMPLITUDE));
    
    % Make the active bias balancing cells and put NaN where the dummy cells
    % will go
    
    l1BiasBalancingCells = repmat(C_bal, NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2,1); % one symbol of active BB cells
    l1BiasBalancingCells = [l1BiasBalancingCells; NaN(NUM_DUMMY_L1_BIAS_BALANCING_CELLS_PER_P2,NUM_SIM_T2_FRAMES)]; % followed by dummies
    l1BiasBalancingCells = repmat(l1BiasBalancingCells, N_P2-1,1); % Replicate for all but last P2
    l1BiasBalancingCells = [l1BiasBalancingCells; repmat(C_bal, NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2,1)]; % last P2 symbol has no dummies
    
    assert(size(l1BiasBalancingCells,1)==NUM_TOTAL_L1_BIAS_BALANCING_CELLS);
else
    l1BiasBalancingCells= zeros(0,NUM_SIM_T2_FRAMES);
end

fprintf(FidLogFile, '\t\tL1 bias balance: %d cells total\n', NUM_TOTAL_L1_BIAS_BALANCING_CELLS);
if (NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2 > 0)
%  fprintf(FidLogFile, '\t\tC_bal0: %f%+fj |%f| (for %d cells)\n', real(C_bal0), imag(C_bal0), abs(C_bal0), N_biasCellsMin);
  fprintf(FidLogFile, '\t\tC_bal: %f%+fj |%f| (for %d cells per P2)\n', real(C_bal), imag(C_bal), abs(C_bal), NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2);
end
%%%

% get the relevant scheduling info for the range of T2 frames being built.
% Indexing is (PLPorder, t2-frame)
sliceLengths = SCHED.sliceLengths(:,START_T2_FRAME+1:START_T2_FRAME+NUM_SIM_T2_FRAMES);
startAddresses = SCHED.startAddresses(:,START_T2_FRAME+1:START_T2_FRAME+NUM_SIM_T2_FRAMES);
subsliceIntervals = SCHED.subsliceIntervals(:,START_T2_FRAME+1:START_T2_FRAME+NUM_SIM_T2_FRAMES);
subsliceLengths = SCHED.subsliceLengths(:,START_T2_FRAME+1:START_T2_FRAME+NUM_SIM_T2_FRAMES);

numNormalSymbols = L_F - N_P2 - L_FC;

readPos(1:NUM_PLPS) = 1;
readPosAux(1:NUM_AUX) = 1;

%sliceStarts = cumsum(sliceLengths, 2);
%sliceStarts = [zeros(NUM_PLPS,1) sliceStarts(:,1:NUM_SIM_T2_FRAMES-1)] + 1; % Start indices of slices in the input data
%sliceEnds = sliceStarts + sliceLengths(:,1:NUM_SIM_T2_FRAMES) - 1;% End indices of slices in the input data
numPLPCells = sum(sliceLengths(:,1:NUM_SIM_T2_FRAMES), 1); % Total cells used for PLPs in each frame

% data = reshape(data, PLPCellsPerT2Frame, numT2Frames).'; % one row per T2 frame

CTot = N_P2 * C_P2 + numNormalSymbols * C_DATA + L_FC * C_FC; % total active cells per T2-frame

nDummyMax = CTot - D_L1 - min(numPLPCells) - (NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2 * N_P2); % Maximum number of dummy cells per T2 frame

if nDummyMax<0, error('t2_tx_dvbt2blfbuild: PLP data exceeds capacity of T2 frame'); end;

% Scrambler PRBS generation - TODO: move into a separate function
Prbs = zeros(1,nDummyMax); % initialize output
x = [1 0 0 1 0 1 0 1 0 0 0 0 0 0 0];
for k = 1:nDummyMax
  xNext(1) = xor(x(14),x(15));  
  xNext(2:15) = x(1:14);      % PG (X)=1+X^14+X^15
  x = xNext;
  Prbs(k) = x(1);
end

dummyBits = double(Prbs);

dummyCells = 1 - 2*dummyBits;

if (L_FC==1)
    nThinning = N_FC - C_FC; % Number of unmodulated cells in Frame Closing Symbol
else
    nThinning = 0;
end

thinningCells = zeros(1, nThinning);

for m = 0:NUM_SIM_T2_FRAMES-1
    % Map each PLP to the correct address (using the scheduler info so
    % that this can be changed in the future
    frameL1BiasBalancingCells = l1BiasBalancingCells(:,m+1);
    frameAddressedCells = NaN(1,CTot-D_L1);
    
    %framePLPData = zeros(1,numPLPCells(m+1));

    subsliceInterval = subsliceIntervals(m+1);

    % Map the bias-balancing cells
    frameAddressedCells(1:NUM_TOTAL_L1_BIAS_BALANCING_CELLS) = frameL1BiasBalancingCells;
    
    % Map the PLP cells
    for plp=1:NUM_PLPS
        sliceLen = sliceLengths(plp,m+1);
        sliceData = data{plp}(readPos(plp):readPos(plp)+sliceLen-1).'; % Get slice from the input
        readPos(plp) = readPos(plp)+sliceLen; % Update pointer in input
        start = startAddresses(plp,m+1);
        len = subsliceLengths(plp,m+1);
        
        if DVBT2.PLP(plp).PLP_TYPE == 2 % Type 2 PLP
            sliceData = reshape(sliceData, [], NUM_SUBSLICES);
            for ss = 0:NUM_SUBSLICES-1
                %assert(isempty(find(framePLPData(start+ss*subsliceInterval+1:start+ss*subsliceInterval+len)~=0,1)));
                frameAddressedCells(start+ss*subsliceInterval+1:start+ss*subsliceInterval+len) = sliceData(:,ss+1).';
            end
        else % Type 1 or common PLP - one subslice only
            %assert(isempty(find(framePLPData(start+1:start+len)~=0,1)));
            frameAddressedCells(start+1:start+len) = sliceData;
        end
    end
    
    if ~DVBT2.PSEUDO_FIXED_FRAME_STRUCTURE %The following checks might fail in pseudo fixed mode
        assert(~any(isnan(frameAddressedCells(NUM_TOTAL_L1_BIAS_BALANCING_CELLS+1:NUM_TOTAL_L1_BIAS_BALANCING_CELLS+numPLPCells(m+1))))); % no unmapped cells within the PLP region
        assert(all(isnan(frameAddressedCells(NUM_TOTAL_L1_BIAS_BALANCING_CELLS+numPLPCells(m+1)+1:end))));% no (sub)slices extended beyond PLP region
    end

    % Map the Aux Streams
    numAuxCells = 0;
    for aux = 1:NUM_AUX
        start = SCHED.AUX(aux).START(START_T2_FRAME + m + 1);
        len = SCHED.AUX(aux).LENGTH(START_T2_FRAME + m + 1);
        frameAddressedCells(start+1:start+len) = DataIn.auxData{aux}(readPosAux(aux):readPosAux(aux)+len-1);
        readPosAux(aux) = readPosAux(aux) + len;
        numAuxCells = numAuxCells + len;
    end
    
    % Insert the dummy cells anywhere there is nothing else
    numDummyCells = CTot - D_L1 - numPLPCells(m+1) - N_P2*NUM_ACTIVE_L1_BIAS_BALANCING_CELLS_PER_P2 - numAuxCells;
    
    frameAddressedCells(isnan(frameAddressedCells)) = dummyCells(1:numDummyCells);
    
    % Map the L1
    L1PreCells = L1pre(:, m+1); % read the appropriate L1 pre cells
    L1PostCells = L1post(:, m+1); % read the appropriate L1 post cells
    frameOut = zeros(C_DATA, L_F); % each col is one symbol; P2s and FCS will be padded with NaNs
    frameOut(C_P2+1:C_DATA, 1:N_P2) = NaN;
    frameOut(N_FC+1:C_DATA, L_F-L_FC+1:L_F) = NaN; % only pad from data carriers. Thinning will be added to the vector of cells to be mapped
    
    % Map the L1 in zigzag manner
    frameOut(1:D_L1/N_P2, 1:N_P2) = [reshape(L1PreCells, N_P2, D_L1PRE/N_P2) reshape(L1PostCells, N_P2, D_L1POST/N_P2)].';
    
    % Now map the PLP, dummy cells and thinning cells. The cells not
    % yet mapped are zero
   
    frameOut(frameOut == 0) = [frameAddressedCells thinningCells];

    DataOut(:,m*L_F+1:(m+1)*L_F) = frameOut;
end

% Store unused data for the next frame (i.e. for multi-frame interleaving)
for plp=1:NUM_PLPS
    DVBT2_STATE.FBUILD.UNUSED_DATA{plp} = data{plp}(readPos(plp):end);
end

% Write V&V point
write_vv_test_point(DataOut, C_DATA, L_F, '12', 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)



fprintf(FidLogFile,'\t\tT2 Frames mapped = %d frames\n', NUM_SIM_T2_FRAMES);

DataOut = DataOut(:);