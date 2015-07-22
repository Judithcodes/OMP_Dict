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
%* Description : T2_TX_DVBT2TSBLDATAGEN DVB TS reader.
%*               DOUT = T2_TX_DVBT2TSDATAGEN(DVBT2) reads from a 
%*               transport stream file. It assumes the TS file is perfect
%*               and makes no attempt to re-sync on 0x47 
%*               DOUT = T2_TX_DVBT2BLTSDATAGEN(DVBT2, FID) specifies the file 
%*               identifier in FID where any debug message is sent.
%******************************************************************************

function DataOut = t2_tx_dvbt2tsdatagen(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_tx_dvbt2tsdatagen SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------

NUM_PLPS = DVBT2.NUM_PLPS;

%------------------------------------------------------------------------------
% State initialisation
%------------------------------------------------------------------------------
global DVBT2_STATE;
if DVBT2.START_T2_FRAME == 0
  for plp=1:NUM_PLPS
      DVBT2_STATE.DATAGEN.PLP(plp).TS_FILE_OFFSET = 0;
  end
end
    

for plp=1:NUM_PLPS

  %------------------------------------------------------------------------------
  % PLP-specific Parameters Definition
  %------------------------------------------------------------------------------
  START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME; % First Interleaving Frame to generate
  NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleving Frames to generate (may be zero)
  NUM_FBLOCK = NUM_INT_FRAMES * DVBT2.PLP(plp).NBLOCKS; % Total number of FEC blocks to generate

  K_BCH           = DVBT2.STANDARD.PLP(plp).OCOD.K_BCH;   % BCH unencoded block length
  STREAM          = DVBT2.PLP(plp).STREAM;                % stream parameters
  PLP_ID          = DVBT2.PLP(plp).PLP_ID;
  IN_BAND_A_FLAG    = DVBT2.PLP(plp).IN_BAND_A_FLAG;
  IN_BAND_LEN     = DVBT2.STANDARD.PLP(plp).IN_BAND_LEN;
  NUM_PLPS        = DVBT2.NUM_PLPS; % Number of PLPs
  TS_FILENAME     = DVBT2.SIM.PLP(plp).INPUT_TS_FILENAME;
   
    
  %------------------------------------------------------------------------------
  % Procedure
  %------------------------------------------------------------------------------
  pktLen    = 188*8;
  
  numHeaderBits = 80;
  numDataFieldBitsMax = K_BCH-numHeaderBits;
    
  OUPL = STREAM.UPL; % Start with complete packets
  UPL = OUPL;
    
  % in TS or GFPS mode, remove the sync bytes and reduce UPL by 8
  if STREAM.TS_GS == 0 || STREAM.TS_GS == 3 % TS or GFPS
      UPL = UPL - 8; % sync bytes removed
      if STREAM.MODE == 0
          UPL = UPL + 8; % CRC in normal mode
      end
  end

  totalPayloadBits = ((numDataFieldBitsMax * NUM_FBLOCK) - IN_BAND_LEN * NUM_INT_FRAMES);
  NUM_TS_PACKETS = ceil(totalPayloadBits/UPL);

  fprintf(FidLogFile, 'TS_FILENAME: %s\n', TS_FILENAME);
  FidTS = fopen(TS_FILENAME, 'r');
  fseek(FidTS, DVBT2_STATE.DATAGEN.PLP(plp).TS_FILE_OFFSET, -1);
 
  TS_CHUNK_SIZE_BYTES = NUM_TS_PACKETS * OUPL/8;

  data = uint8(fread(FidTS, TS_CHUNK_SIZE_BYTES, 'uint8'));

  DVBT2_STATE.DATAGEN.PLP(plp).TS_FILE_OFFSET = ftell(FidTS);
  
  fclose(FidTS);
  fprintf(FidLogFile,'\t\t%d TS bytes read\n', length(data));

  write_vv_test_point(data, pktLen/8, inf, vv_fname('01', plp, DVBT2), 'byte', DVBT2, 1, DVBT2.START_T2_FRAME+1)

  DataOut{plp} = data;
end

