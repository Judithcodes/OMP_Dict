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
%* Description : PRBS = T2_TX_DVBT2VVDATAGEN_PRBSSEQ(LEN) generates the
%*               pseudo random binary sequence used to scramble the "BB Frame" 
%*               within the "Stream Adaption" module
%******************************************************************************

function prbs = t2_tx_dvbt2itudatagen_prbsseq(plpidx, plp, len, DVBT2, init, commonPLP)

if len==0
    prbs = [];
    return;
end

if nargin<6
    commonPLP = plp;
end
isCommonInData = (commonPLP ~= plp);

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
% State initialisation
%------------------------------------------------------------------------------
global DVBT2_STATE;
if init
  srBin = ~(de2bi(plpidx,23)); % Initial shift register contents are complement of PLP index
else
    if isCommonInData
        srBin = DVBT2_STATE.DATAGEN.PRBS.PLP(plp).PRBS_SR_BIN_COMMON;
    else
        srBin = DVBT2_STATE.DATAGEN.PRBS.PLP(plp).PRBS_SR_BIN;
    end
end

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

% Initialize variables

%srBin = ~fliplr(de2bi(plpidx,24)); % Initial shift register contents are complement of PLP index
%srBin = ~(de2bi(plpidx,23)); % Initial shift register contents are complement of PLP index
prbsBin = zeros(1,len); % Initialize output

% Generates PRBS sequence
for n=1:len
    fedBackBit = xor(srBin(23), srBin(18)); % XOR bits 18 and 23
    prbsBin(n) = ~fedBackBit;  % Output
    srBin = [fedBackBit, srBin(1:22)];
end

% keep shift register state for next run
if isCommonInData
    DVBT2_STATE.DATAGEN.PRBS.PLP(plp).PRBS_SR_BIN_COMMON =  srBin;
else
    DVBT2_STATE.DATAGEN.PRBS.PLP(plp).PRBS_SR_BIN =  srBin;
end

prbsBin = reshape(prbsBin, 8, []);
prbs = bi2de(prbsBin', 'left-msb');
