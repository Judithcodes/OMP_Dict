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
%* Description : T2_TX_DVBT2ITUDATAGEN DVBT2 random data generator.
%*               DOUT = T2_TX_DVBT2BLDATAGEN(DVBT2) generates a random 
%*               transport stream with the configuration parameters stored in 
%*               the DVBT2 structure
%*               The prbs is the new one adopted by the V&V group on 1st Jan 2009
%*
%*               DOUT = T2_TX_DVBT2BLDATAGEN(DVBT2, FID) specifies the file 
%*               identifier in FID where any debug message is sent.
%******************************************************************************

function DataOut = t2_tx_dvbt2itudatagen(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_tx_dvbt2vvdatagen SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
NUM_PLPS   = DVBT2.NUM_PLPS; % Number of PLPs

%------------------------------------------------------------------------------
% State initialisation
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
% PLP Loop
%------------------------------------------------------------------------------

for plp=1:NUM_PLPS

    %------------------------------------------------------------------------------
    % PLP-specific Parameters Definition
    %------------------------------------------------------------------------------
    START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME; % First Interleaving Frame to generate
    NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleving Frames to generate (may be zero)
    NBLOCKS = DVBT2.PLP(plp).NBLOCKS;
    K_BCH      = DVBT2.STANDARD.PLP(plp).OCOD.K_BCH;   % BCH unencoded block length
    PLP_ID     = DVBT2.PLP(plp).PLP_ID;
    STREAM     = DVBT2.PLP(plp).STREAM;
    IN_BAND_LEN = DVBT2.STANDARD.PLP(plp).IN_BAND_LEN;

    %------------------------------------------------------------------------------
    % Procedure
    %------------------------------------------------------------------------------
    if size(NBLOCKS)==1
        NBLOCKS = repmat(NBLOCKS, 1, NUM_INT_FRAMES);
    else        
        NBLOCKS = NBLOCKS(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame
    end
    NUM_FBLOCK = sum(NBLOCKS); % Total number of FEC blocks to generate
    
    numHeaderBits = 80;
    numDataFieldBitsMax = K_BCH-numHeaderBits;

    
    OUPL = STREAM.UPL; % Start with complete packets
    UPL = OUPL;
    pktHeaderLen = 32;

    % in TS or GFPS mode, remove the sync bytes and reduce UPL by 8
    if STREAM.TS_GS == 0 || STREAM.TS_GS == 3 % TS or GFPS
      UPL = UPL - 8; % sync bytes removed
      if STREAM.MODE == 0
          UPL = UPL + 8; % CRC in normal mode
      end
    end

    totalPayloadBits = ((numDataFieldBitsMax * NUM_FBLOCK) - IN_BAND_LEN*NUM_INT_FRAMES);
    numPackets = ceil(totalPayloadBits/UPL);

    data = t2_tx_dvbt2itudatagen_normalpackets(numPackets, plp, DVBT2, START_INT_FRAME==0, plp);
    
    data = data(:);

    fprintf(FidLogFile,'\t\t%d Bytes generated\n', length(data));

    write_TS_file(FidLogFile, data, DVBT2.SIM.PLP(plp).OUTPUT_TS_FILENAME, DVBT2.START_T2_FRAME==0);
    write_vv_test_point(data, OUPL/8, inf, vv_fname('01', plp, DVBT2), 'byte', DVBT2, 1, DVBT2.START_T2_FRAME+1)

    DataOut{plp} = data;

end
