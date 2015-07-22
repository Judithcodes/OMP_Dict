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
%* Description : T2_TX_DVBT2RAWBBFILEDATAGEN DVBT2 inputdata generator.
%*               DOUT = T2_TX_DVBT2RAWBBFILEDATAGEN(DVBT2) reads input BBframes
%*               from a raw binary file.
%*
%*               DOUT = T2_TX_DVBT2RAWBBFILEDATAGEN(DVBT2, FID) specifies the file 
%*               identifier in FID where any debug message is sent.
%******************************************************************************

function DataOut = t2_tx_dvbt2rawbbfiledatagen(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_tx_dvbt2rawfiledatagen SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------

NUM_PLPS   = DVBT2.NUM_PLPS;
START_T2_FRAME = DVBT2.START_T2_FRAME;

%------------------------------------------------------------------------------
% PLP Loop
%------------------------------------------------------------------------------

for plp=1:NUM_PLPS % Currently only makes sense for 1 PLP because only one file

    %------------------------------------------------------------------------------
    % PLP-specific Parameters Definition
    %------------------------------------------------------------------------------
    
    INPUT_FILENAME = DVBT2.SIM.PLP(plp).INPUT_BBF_FILENAME;
    NUM_INT_FRAMES = DVBT2.NUM_SIM_T2_FRAMES / (DVBT2.PLP(plp).P_I * DVBT2.PLP(plp).I_JUMP);
    START_INT_FRAME = floor(START_T2_FRAME/(DVBT2.PLP(plp).P_I * DVBT2.PLP(plp).I_JUMP));
    NBLOCKS    = DVBT2.PLP(plp).NBLOCKS;
    NUM_FBLOCK = NUM_INT_FRAMES * NBLOCKS;          % Number of frames to transmit
    CR         = DVBT2.STANDARD.PLP(plp).ICOD.CR;    % Coding rate
    FECLEN     = DVBT2.PLP(plp).FECLEN;              %the inner fec length
    K_BCH      = DVBT2.STANDARD.PLP(plp).OCOD.K_BCH; 

    %------------------------------------------------------------------------------
    % Procedure
    %------------------------------------------------------------------------------
   
    numBytes = NBLOCKS * NUM_INT_FRAMES * K_BCH/8;
    
    fid = fopen(INPUT_FILENAME, 'r');
    fseek(fid, START_INT_FRAME * NBLOCKS * K_BCH/8, 'bof');
    
    % Read input data
    data = fread(fid, numBytes, 'uint8');

    fclose(fid);
    
    fprintf(FidLogFile,'\t\t%d Bytes read\n', numBytes);

    DataOut{plp} = data;
end