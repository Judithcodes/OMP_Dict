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
%* Description : T2_TX_DVBT2BLMAP DVBT2 Mapper
%*               DOUT = T2_TX_DVBT2BLMAP(DVBT2, FID, DIN) modulates the data 
%*               following the configuration parameters of the DVBT2 structure.
%*               FID specifies the file identifier where any debug message is 
%*               sent.
%******************************************************************************

function DataOut = t2_tx_dvbt2blmap(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_tx_dvbt2blmap SYNTAX');
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
    V        = DVBT2.STANDARD.PLP(plp).MAP.V;    % Bits per cell
    FECLEN   = DVBT2.PLP(plp).FECLEN;            % The inner fec length
    START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME; % First Interleaving Frame to generate
    NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleving Frames to generate (may be zero)
    NBLOCKS = SCHED.NBLOCKS{plp}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame
    C_POINTS = DVBT2.STANDARD.PLP(plp).MAP.C_POINTS; % Constellation points

    %------------------------------------------------------------------------------
    % Procedure
    %------------------------------------------------------------------------------

    data = DataIn.data{plp};

    fprintf(FidLogFile,'\t\t%s\n', CONSTEL);    

    data = C_POINTS(data+1); % Mapper    

    % Write V&V point
    write_vv_test_point(data, FECLEN/V, NBLOCKS, vv_fname('08a',plp,DVBT2), 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1) % really it's 8a

    DataOut.data{plp} = data;
end

DataOut.sched = SCHED;
DataOut.l1 = DataIn.l1;