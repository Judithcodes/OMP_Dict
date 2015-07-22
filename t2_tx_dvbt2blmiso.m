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
%* Description : T2_TX_DVBT2BLMISO DVBT2 MISO processing
%*               DOUT = T2_TX_DVBT2BLMISO(DVBT2, FID, DIN) performs the
%*               MISO processing
%*               following the configuration parameters of the DVBT2 structure.
%*               FID specifies the file identifier where any debug message is 
%*               sent.
%******************************************************************************

function DataOut = t2_tx_dvbt2blmiso(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2blmiso SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
MODE     = DVBT2.MODE;               % DVBT mode
C_DATA  = DVBT2.STANDARD.C_DATA; % Data carriers per normal symbol
C_P2	= DVBT2.STANDARD.C_P2; % Data carriers in P2 symbols
N_FC	= DVBT2.STANDARD.N_FC; % Data carriers in frame closing symbols (including the thinning cells)
L_F     = DVBT2.STANDARD.L_F; % symbols per T2-frame
N_P2    = DVBT2.STANDARD.N_P2; % Number of P2 symbols per T2-frame
L_FC    = DVBT2.STANDARD.L_FC; % Number of Frame Closing symbols
MISO_ENABLED = DVBT2.MISO_ENABLED; % 1=MISO 0=SISO

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

data = DataIn(:);

data=reshape(data, C_DATA, []);

if (MISO_ENABLED)
   % Group 1 Tx is unmodified
   DataOut{1} = data(:).';
   
   DataAux = zeros(size(data));
   DataAux(1:2:end,:) = -conj(data(2:2:end,:)); % the NaNs will be in pairs so will stay where they are
   DataAux(2:2:end,:) = conj(data(1:2:end,:));
   
   DataOut{2} = (DataAux(:)).';
   
   % Write V&V points
   write_vv_test_point(DataOut{1}, C_DATA, L_F, '14Tx1' , 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)
   write_vv_test_point(DataOut{2}, C_DATA, L_F, '14Tx2' , 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)

else % don't do anything if MISO disabled, but put in a cell array for consistency 
   DataOut = {data(:).'};
   write_vv_test_point(DataOut{1}, C_DATA, L_F, '14' , 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)
end
    

fprintf(FidLogFile,'\t\tMISO processing: %d symbols\n',... 
        size(data,2));

