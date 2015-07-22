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
%* Description : T2_RX_DVBT2BLDMCELLS DVBT2 Dummy Cells extraction
%*               DOUT = T2_RX_DVBT2BLDMCELLS(DVBT2, FID, DIN) extracts dummy
%*               cells following the configuration parameters of the DVBT2 structure.
%*               FID specifies the file identifier where any debug message is 
%*               sent.
%******************************************************************************

function DataOut = t2_rx_dvbt2bldmcells(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2blfreqint SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
PLP            = DVBT2.RX_PLP;
FECLEN         = DVBT2.PLP(1).FECLEN;         % FEC block size (16200 or 64800)
NBLOCKS        = DVBT2.PLP(1).NBLOCKS;        % Number of FEC blocks per Interleaving Frame.
BITS_PER_CELL  = DVBT2.STANDARD.PLP(1).MAP.V; % Bits per cell
C_DATA         = DVBT2.STANDARD.C_DATA;       % Active cells per symbol
NUM_SIM_T2_FRAMES  = DVBT2.NUM_SIM_T2_FRAMES;         % Number of T2-Frames
P_I            = DVBT2.PLP(1).P_I;             % Number of T2-frames to which Interleaving Frame is mapped


%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
data = DataIn.data;

cellsPerFECBlock = FECLEN / BITS_PER_CELL; 
cellsPerInterleavingFrame = cellsPerFECBlock * NBLOCKS;
numBits = floor(cellsPerInterleavingFrame*NUM_SIM_T2_FRAMES*BITS_PER_CELL/P_I);

streams = BITS_PER_CELL * 2;
numCells = floor(numBits/streams)*2;
nBlocksTotal = floor(numCells/cellsPerFECBlock);
nCellsTx = nBlocksTotal*cellsPerFECBlock;

if NBLOCKS > 0
  
  numInterleavingFrames = floor(nCellsTx/cellsPerInterleavingFrame);

  nCellsTx = numInterleavingFrames*cellsPerInterleavingFrame; % trim to whole number of sub-frames

end

numSymb = ceil(nCellsTx/C_DATA);
nDummy = numSymb*C_DATA - nCellsTx;

fprintf(FidLogFile,'\t\tDummy Cells Extracted = %d cells\n', nDummy);

DataOut.data  = data(1:end-nDummy);
DataOut.h_est = DataIn.h_est(1:end-nDummy);

