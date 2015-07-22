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

function data = t2_tx_dvbt2itudatagen_prbsseq_precalc(plp, len, DVBT2, init, prbsPLP)

if ~exist('prbsPLP', 'var')
    prbsPLP = plp;
end

DI_FNAME = DVBT2.TX.DATAGEN_FDI;
SIM_DIR  = DVBT2.SIM.SIMDIR;    

prbs_plp_id = DVBT2.PLP(prbsPLP).PLP_ID;

if len==0
    data = [];
    return;
end

isCommonInData = (prbsPLP ~= plp);

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
% State initialisation
%------------------------------------------------------------------------------

% Generate PRBS if it hasn't been stored in a file yet
prbsFileName = strcat(SIM_DIR, filesep, DI_FNAME, '.mat');
totalLen = (2^23)-1;
    
if ~exist(prbsFileName, 'file') % need to create it
    fprintf(1,'Generating basic PRBS - this should only need to be done once');
    %srBin = ~fliplr(de2bi(plpidx,24)); % Initial shift register contents are complement of PLP index
    srBin = ones(1,23);% Initial shift register contents are complement of PLP index, i.e. all ones for PLP=0
    startIndex = zeros(1,256);

    prbsBin = zeros(1,totalLen); % Initialize output
    
    % Generates PRBS sequence
    for n=1:totalLen
        plp_id = bi2de(~srBin,'right-msb'); % work out which PLP_ID would start in this state
        if plp_id<256
            startIndex(plp_id+1) = n; % store the start position
            fprintf(1,'Start index for plp_id %d is %d\n',plp_id,n);
        end
        fedBackBit = xor(srBin(23), srBin(18)); % XOR bits 18 and 23
        prbsBin(n) = ~fedBackBit;  % Output
        srBin = [fedBackBit, srBin(1:22)];            
    end
    
    save(prbsFileName,'prbsBin','startIndex');
    
end

prbsData = load(prbsFileName);


global DVBT2_STATE;
if init
  prbsIndex = prbsData.startIndex(prbs_plp_id+1); % Initial shift register contents are complement of PLP ID - start at the right place
else
    if isCommonInData
        prbsIndex = DVBT2_STATE.DATAGEN.PRBS.PLP(plp).PRBS_INDEX_COMMON;
    else
        prbsIndex = DVBT2_STATE.DATAGEN.PRBS.PLP(plp).PRBS_INDEX;
    end
end

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

% Initialize variables

%srBin = ~fliplr(de2bi(plpidx,24)); % Initial shift register contents are complement of PLP index
%srBin = ~(de2bi(plpidx,23)); % Initial shift register contents are complement of PLP index

startBits = min(totalLen-prbsIndex+1,len); % bits to take from the end of the sequence
midRepeats = floor((len-startBits)/totalLen); % how many repeats of the whole sequence
endBits = len-startBits-midRepeats*totalLen; % how many bits from the start to finish off with

dataBin = [prbsData.prbsBin(prbsIndex:prbsIndex+startBits-1) repmat(prbsData.prbsBin,1,midRepeats) prbsData.prbsBin(1:endBits)];
assert(length(dataBin)==len);

% calculate new prbs index for next time
prbsIndex = mod(prbsIndex+len-1, totalLen)+1;

% keep shift register state for next run
if isCommonInData
    DVBT2_STATE.DATAGEN.PRBS.PLP(plp).PRBS_INDEX_COMMON =  prbsIndex;
else
    DVBT2_STATE.DATAGEN.PRBS.PLP(plp).PRBS_INDEX =  prbsIndex;
end

dataBin = reshape(dataBin, 8, []);
data = bi2de(dataBin', 'left-msb');
