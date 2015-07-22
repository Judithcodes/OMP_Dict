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
%* Description : t2_tx_dvbt2blfef_makeprbsfef DVBT2 PRBS FEF generator
%******************************************************************************
function fefData = t2_tx_dvbt2blfef_makeprbsfef(DVBT2, numFEFSamples, FidLogFile)

P1LEN = DVBT2.STANDARD.P1LEN;
FEF_LENGTH = DVBT2.FEF_LENGTH;
FEF_INTERVAL = DVBT2.FEF_INTERVAL;

numFEFPartSamples = FEF_LENGTH - P1LEN;
numFEFPartsPerSF = sum(mod(1+(0:DVBT2.N_T2-1), FEF_INTERVAL)==0);
numFEFSamplesPerSF = numFEFPartsPerSF*numFEFPartSamples;

%------------------------------------------------------------------------------
% State initialisation
%------------------------------------------------------------------------------

global DVBT2_STATE;
if DVBT2.START_T2_FRAME == 0
    % sequence is reset every superframe. Make a super-frame's worth at the
    % beginning and extract the appropriate part of it each FEF part

    DVBT2_STATE.FEF.FEF_DATA = t2_tx_dvbt2blfef_makeprbsfefdata(DVBT2, numFEFSamplesPerSF, FidLogFile);

end

%Calculate where we are in the SF - output is rotated, truncated version of
%DVBT2.STATE.FEF_DATA;

startFEFIdx = mod(DVBT2.START_T2_FRAME, DVBT2.N_T2);

fefData = circshift(DVBT2_STATE.FEF.FEF_DATA, [0, -numFEFPartSamples*startFEFIdx]);
fefData = repmat(fefData,1,ceil(numFEFSamples/numFEFSamplesPerSF)); %in case need more than one superframe
fefData = fefData(1:numFEFSamples);

end
