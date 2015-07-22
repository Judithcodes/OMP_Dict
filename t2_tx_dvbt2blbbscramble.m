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
%* Description : T2_TX_DVBBBSCRAMBLE DVBT2 Stream Adaptation
%*               DOUT = T2_TX_DVBT2BBSCRAMBLE(DVBT2, FID, DIN) takes pre-prepared BB
%*               frames and applies BB scrambling.  FID specifies
%*               the file where any debug message is sent.  
%******************************************************************************

function DataOut = t2_tx_dvbt2blbbscramble(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2bbscramble SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
NUM_PLPS   = DVBT2.NUM_PLPS; % Number of PLPs
SCHED = DataIn.sched;
%------------------------------------------------------------------------------
% PLP Loop
%------------------------------------------------------------------------------

for plp=1:NUM_PLPS

    %------------------------------------------------------------------------------
    % PLP-specific Parameters Definition
    %------------------------------------------------------------------------------
    START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME; % First Interleaving Frame to generate
    NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleving Frames to generate (may be zero)
    NBLOCKS = SCHED.NBLOCKS{plp}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame
    NUM_FBLOCK = sum(NBLOCKS); % Total number of FEC blocks to generate
    K_BCH      = DVBT2.STANDARD.PLP(plp).OCOD.K_BCH;   % BCH unencoded block length

    %------------------------------------------------------------------------------
    % Procedure
    %------------------------------------------------------------------------------

    dataAux = DataIn.data{plp}';

    %-----------------------------
    % Pre-process input packets
    %-----------------------------

    fprintf(FidLogFile,'\t\tNumber of complete BB frames: %d\n', NUM_FBLOCK);

    % Get BB scrambling sequence
    bbPrbs = t2_tx_dvbt2blbbscramble_bbprbsseq(K_BCH);
    bbPrbs = bi2de(reshape(bbPrbs,8,[])','left-msb'); % convert to bytes
    
    dataAux = reshape(dataAux, K_BCH/8, []); % One column per BBFrame
    for bbFrameIdx = 1:size(dataAux,2)
        dataAux(:,bbFrameIdx) = bitxor(dataAux(:,bbFrameIdx), bbPrbs);
    end

    if ~isempty(dataAux)
     dataAuxBin = de2bi(dataAux,8,'left-msb')';
    else
     dataAuxBin = [];
    end
    
    write_vv_test_point(dataAuxBin, K_BCH, NBLOCKS, vv_fname('04', plp, DVBT2), 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);

    DataOut.data{plp} = dataAux(:)';
end
DataOut.sched = DataIn.sched;
if isfield(DataIn, 'l1')
  DataOut.l1 = DataIn.l1;
else
  DataOut.l1 = [];
end
