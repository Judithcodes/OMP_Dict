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
%* Description : T2_TX_DVBT2BLOCOD DVBT2 Outer Coder
%*               DOUT = T2_TX_DVBT2BLOCOD(DVBT2, FID, DIN) encodes DIN following
%*               the configuration parameters of the DVBT2 structure. FID 
%*               specifies the file identifier where any debug message is sent.
%*               Modified by Pace to append dummy BCH parity block to each
%*               BB frame.
%******************************************************************************

function DataOut = t2_tx_dvbt2blocod(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_tx_dvbt2blocod SYNTAX');
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
    K_BCH      = DVBT2.STANDARD.PLP(plp).OCOD.K_BCH;   % BCH unencoded block length
    N_BCH      = DVBT2.STANDARD.PLP(plp).OCOD.N_BCH;    % Encoded length of BCH block
    BCH_GEN  = DVBT2.STANDARD.PLP(plp).OCOD.BCH_GEN; % Generator polynomial of BCH
    assert(N_BCH-K_BCH == length(BCH_GEN)-1);
    START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME; % First Interleaving Frame to generate
    NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleving Frames to generate (may be zero)
    NBLOCKS = SCHED.NBLOCKS{plp}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame

    %------------------------------------------------------------------------------
    % Procedure
    %------------------------------------------------------------------------------

    Data = DataIn.data{plp}(:);

    NumBytes = length(Data);
    fprintf(FidLogFile,'\t\tNumber of Bytes read: %d\n', NumBytes);

    if ~isempty(Data)
        % Convert to binary
        Data = de2bi(Data, 8, 'left-msb').';
        Data = Data(:);

        NumBCHBlocks = floor(length(Data)/K_BCH);
        fprintf(FidLogFile,'\t\tBCH blocks: %d\n', NumBCHBlocks);

        Data = reshape(Data(1:NumBCHBlocks*K_BCH), [K_BCH NumBCHBlocks]);

        % Compute parity bits
        Parity = double(t2_tx_dvbt2blocod_encode(logical(Data), logical(BCH_GEN)));

        % Append parity bits (systematic code)
        Data = [Data; Parity];

        % Convert to bytes
        DataOut.data{plp} = bi2de(reshape(Data, 8, []).', 'left-msb');
    else
        Data = [];
        DataOut.data{plp} = [];
    end
    % Write V&V point
    write_vv_test_point(Data, N_BCH, NBLOCKS, vv_fname('05',plp, DVBT2), 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
end
DataOut.sched = DataIn.sched;
DataOut.l1 = DataIn.l1;