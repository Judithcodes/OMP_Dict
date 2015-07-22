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
%* Description : T2_TX_DVBT2BLBMAP DVBT2 Bit Mapping into Constellations
%*               DOUT = T2_TX_DVBT2BLBMAP(DVBT2, FID, DIN)bit maps the input bits  
%*               following the configuration parameters of the DVBT2 structure.
%*               FID specifies the file identifier where any debug message is 
%*               sent.
%******************************************************************************

function DataOut = t2_tx_dvbt2blbmap(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_tx_dvbt2blbmap SYNTAX');
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
    CONSTEL  = DVBT2.PLP(plp).CONSTELLATION;     % DVBT2 constellation
    %DCPS     = DVBT2.STANDARD.DC_PS;   % Data carriers per symbol
    V        = DVBT2.STANDARD.PLP(plp).MAP.V;    % Bits per cell
    CRATE    = DVBT2.PLP(plp).CRATE; %the code rate
    FECLEN   = DVBT2.PLP(plp).FECLEN;            % The inner fec length
    SPEC_VERSION = DVBT2.SPEC_VERSION;
    START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME; % First Interleaving Frame to generate
    NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleving Frames to generate (may be zero)
    NBLOCKS = SCHED.NBLOCKS{plp}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame
    NUM_FBLOCK = sum(NBLOCKS); % Total number of FEC blocks to generate

    %------------------------------------------------------------------------------
    % Procedure
    %------------------------------------------------------------------------------
    data = DataIn.data{plp};

    streams = V * 2;

    switch CONSTEL
      case 'QPSK'
        mapping = [0 1 2 3] + 1;
      case '16-QAM'
        if strcmp(CRATE,'1/3') && FECLEN == 16200 %T2-Lite only
          mapping = [6 0 3 4 5 2 1 7] + 1;
        elseif strcmp(CRATE,'2/5') && FECLEN == 16200 %T2-Lite only
          mapping = [7 5 4 0 3 1 2 6] + 1;
        elseif strcmp(CRATE,'3/5') && FECLEN == 64800
          mapping = [0 5 1 2 4 7 3 6] + 1;
        else
          mapping = [7 1 4 2 5 3 6 0] + 1;
        end
      case '64-QAM'
        if strcmp(CRATE,'1/3') && FECLEN == 16200 %T2-Lite only
          mapping = [4 2 0 5 6 1 3 7 8 9 10 11] + 1;
        elseif strcmp(CRATE,'2/5') && FECLEN == 16200 %T2-Lite only
          mapping = [4 0 1 6 2 3 5 8 7 10 9 11] + 1;
        elseif strcmp(CRATE,'3/5') && FECLEN == 64800
          mapping = [2 7 6 9 0 3 1 8 4 11 5 10] + 1;
        else
          mapping = [11 7 3 10 6 2 9 5 1 8 4 0] + 1;
        end
      case '256-QAM'
        if FECLEN == 16200
          if strcmp(CRATE,'1/3') %T2-Lite only
              mapping = [4 0 1 2 5 3 6 7] + 1;
          elseif strcmp(CRATE,'2/5') %T2-Lite only
              mapping = [4 0 5 1 2 3 6 7] + 1;
          else
              mapping = [7 3 1 5 2 6 4 0] + 1;
          end
          streams = V;
        else
          if strcmp(CRATE,'3/5')
            mapping = [2 11 3 4 0 9 1 8 10 13 7 14 6 15 5 12] + 1;
          elseif strcmp(CRATE,'2/3') && ~strcmp(SPEC_VERSION, '1.0.1')
            mapping = [7 2 9 0 4 6 13 3 14 10 15 5 8 12 11 1] + 1;
          else
            mapping = [15 1 13 3 8 11 9 5 10 6 4 7 12 2 14 0] + 1;
          end
        end
    end

    numBits  = length(data);
    numCells = floor(numBits/streams);
    numBits  = numCells*streams;

    data = data(1:numBits);

    %make streams

    cells = reshape(data', streams, size(data,2)/streams)';

    %swap this to agree with spec, above line maps the wrong way
    cells(:, mapping) = cells;

    %split the cells into two cells

    cells = reshape(cells', [] , 1);
    cells = reshape(cells, V , [])';

    % Write V&V point
    write_vv_test_point(cells', FECLEN, NBLOCKS, vv_fname('07', plp, DVBT2), 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1)

    if ~isempty(cells)
        DataOut.data{plp} = bi2de(cells,'left-msb');
    else
        DataOut.data{plp} = [];
    end
end

DataOut.l1 = DataIn.l1;
DataOut.sched = SCHED;