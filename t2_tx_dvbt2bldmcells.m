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
%* Description : T2_TX_DVBT2BLDMCELLS DVBT2 Dummy Cells Insertion
%*               DOUT = T2_TX_DVBT2BLDMCELLS(DVBT2, FID, DIN) inserts dummy
%*               cells following the configuration parameters of the DVBT2 structure.
%*               FID specifies the file identifier where any debug message is 
%*               sent.
%******************************************************************************

function DataOut = t2_tx_dvbt2bldmcells(DVBT2, FidLogFile, DataIn)

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
C_DATA      = DVBT2.STANDARD.C_DATA; % Data carriers per symbol

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
data = DataIn.data{1};
SCHED = DataIn.sched;

numSymb = ceil(length(data)/C_DATA);
nDummy = numSymb*C_DATA - length(data);

% Scrambler PRBS generation
Prbs = zeros(1,nDummy); % initialize output
x = [1 0 0 1 0 1 0 1 0 0 0 0 0 0 0];
for k = 1:nDummy
  xNext(1) = xor(x(14),x(15));  
  xNext(2:15) = x(1:14);      % PG (X)=1+X^14+X^15
  x = xNext;
  Prbs(k) = x(1);
end

dummyBits = double(Prbs);

dummyCells = 1 - 2*dummyBits;

fprintf(FidLogFile,'\t\tDummy Cells Inserted = %d cells\n', nDummy);

DataOut = [data dummyCells];
% Discard scheduling info (this block replaces the frame builder)