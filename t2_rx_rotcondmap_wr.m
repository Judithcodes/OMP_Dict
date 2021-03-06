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
%* Description : T2_RX_ROTCONDMAP_WR DVBT2 Rotated Constellation Demapper Wrapper
%*               T2_RX_ROTCONDMAP_WR(DVBT2) wrapper for the DVBT2 rotated 
%*               constellation demapper.
%*  
%*               T2_RX_ROTCONDMAP_WR(DVBT2, FID) specifies the file identifier 
%*               in FID where any debug message is sent.
%******************************************************************************

function t2_rx_rotcondmap_wr(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_rx_rotcondmap_wr SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
ENABLED  = DVBT2.RX.ROTCON.ENABLE; % Enable
DI_FNAME = DVBT2.RX.ROTCON_FDI;    % Input file
DO_FNAME = DVBT2.RX.ROTCON_FDO;    % Output file
TYPE     = DVBT2.RX.ROTCON.TYPE;   % Block type
SIM_DIR  = DVBT2.SIM.SIMDIR;       % Simulation directory 
TX_FNAME = DVBT2.TX.MAP_FDI;       % Transmiter data (Mapper input)      
           
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
global DATA;
    
if ENABLED
  fprintf(FidLogFile,'\tDVBT2-RX-ROTCONDMAP: (%s)\n', TYPE);

  if strcmp(DI_FNAME, '')
    data = DATA;
    
  else
    load(strcat(SIM_DIR, filesep, DI_FNAME), 'data'); % Load input data    
  end  

  switch TYPE
    case 'DVBT2BL'    
      dataRx = data; 
      if strcmp(TX_FNAME, '') 
        dataTx = [];
      else
        load(strcat(SIM_DIR, filesep, TX_FNAME), 'data'); % Load input data    
        dataTx = data;
      end      
      data = t2_rx_dvbt2blrotcondmap(DVBT2, FidLogFile, dataRx, dataTx);  
    otherwise     
      error('Unknown rotated constellation demapper type %s', TYPE);
  end

else % If disabled
  fprintf(FidLogFile,'\tDVBT2-RX-ROTCONDMAP: DISABLED\n');
end

%------------------------------------------------------------------------------
% Output saving and formatting
%------------------------------------------------------------------------------
if ENABLED
  if strcmp(DO_FNAME, '')
    DATA = data;
    fprintf(FidLogFile,'\t\tRotated constellation demapper output stored in workspace\n');
  else
    save(strcat(SIM_DIR, filesep, DO_FNAME),'data')
    fprintf(FidLogFile,'\t\tRotated constellation demapper output saved in file: %s\n',DO_FNAME);
  end
end
