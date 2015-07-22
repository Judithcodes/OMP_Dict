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
%* Description : T2_RX_DVBT2BLIDCOD LDPC Decoder
%*               DATAOUT = T2_RX_DVBT2BLIDCOD(DVBT2, FID, DATAIN) decodes the data
%*               DATAIN and stores the result in DATAOUT following the
%*               configuration parameters of the DVBT2 structure. FID specifies
%*               the file identifier where any debug message is sent. 
%******************************************************************************

function DataOut = t2_rx_dvbt2blidcod(DVBT2, FidLogFile, DataIn)


%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_rx_dvbt2blidcod SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
PLP = DVBT2.RX_PLP; % PLP to decode in the receiver

H                = DVBT2.STANDARD.PLP(PLP).ICOD.H;       % LDPC H matrix
STRING_COD_RATE  = DVBT2.PLP(PLP).CRATE;                 % String coding rate
LDPC_MAXNIT      = DVBT2.RX.IDCOD.LDPC_MAXNIT;  % max number of iterations

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

data = DataIn;  

fprintf(FidLogFile,'\t\tCoding rate: %s\n', STRING_COD_RATE);

ldpcFEC = fec.ldpcdec(H);
%ldpcFEC.DecisionType = 'Hard decision'; 
ldpcFEC.DecisionType = 'Soft decision'; 
ldpcFEC.OutputFormat = 'Information part';
ldpcFEC.NumIterations = LDPC_MAXNIT;          
% Stop if all parity-checks are satisfied
ldpcFEC.DoParityChecks = 'Yes'; 

numBitPerBlock = ldpcFEC.BlockLength;
numBlocks = floor(length(data)/numBitPerBlock);
fprintf(FidLogFile,'\t\tLDPC blocks: %d\n', numBlocks);

data = data(1:numBlocks*numBitPerBlock);
data = reshape(data, numBitPerBlock, numBlocks).';

numOutBitPerBlock = ldpcFEC.NumInfoBits;
numOutputBits = numBlocks*numOutBitPerBlock;

totalNumIter = 0;
minIter=LDPC_MAXNIT;
maxIter=0;

iterations = zeros (numBlocks, 1);
decData = zeros(1, numOutputBits);
fprintf(FidLogFile,'\t\t');
for k=1:numBlocks
  fprintf(FidLogFile,'.');
  decMsg = decode(ldpcFEC, data(k,:)); 
  decMsg = decMsg<0;
  fprintf(FidLogFile,'Total unsatisfied parity checks = %d/%d\n', sum(ldpcFEC.FinalParityChecks),length(ldpcFEC.FinalParityChecks));
  numIter = ldpcFEC.ActualNumIterations;
  iterations(k) = numIter;
  totalNumIter = totalNumIter + numIter;
  if numIter > maxIter
    maxIter = numIter;
  end
  if numIter < minIter
    minIter = numIter;
  end
  decData((k-1)*numOutBitPerBlock +1: k*numOutBitPerBlock) = decMsg;
end
numBytes = floor(length(decData)/8);
decData = decData(1:numBytes*8);
decData = reshape(decData, 8, []).';
if ~isempty(decData)
    decData = bi2de(decData, 'left-msb');
end
fprintf(FidLogFile,'\n');
fprintf(FidLogFile, '\t\tNumber of iterations per LDPC block (mean): %f\n',  totalNumIter/numBlocks);
fprintf(FidLogFile, '\t\tMaximum number of iterations: %d\n', maxIter);
fprintf(FidLogFile, '\t\tMinimum number of iterations: %d\n', minIter);
fprintf(FidLogFile, '\n\t\tIterations for each block:\n\t\t');
fprintf(FidLogFile, '%d ', iterations);
fprintf(FidLogFile, '\n');

DataOut = decData;
