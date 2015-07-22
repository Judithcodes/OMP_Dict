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
%* Description : t2_tx_dvbt2itudatagen_normalpackets 
%*               DVB-T2 V&V group normal packet generator with ITU PRBS
%******************************************************************************

function data = t2_tx_dvbt2itudatagen_normalpackets(numPackets, plp, DVBT2, init, prbsPLP)

    if ~exist('prbsPLP', 'var')
        prbsPLP = plp;
    end
    
    isCommonInData = plp ~= prbsPLP;
    
    global DVBT2_STATE;
    if init
        cont = 0; % Continuity count for PLP
    else
        if isCommonInData % this is a common packet for insertion in a data PLP - keep track separately of the cont
            cont = DVBT2_STATE.DATAGEN.NORMAL.PLP(plp).contCommon;
        else
            cont = DVBT2_STATE.DATAGEN.NORMAL.PLP(plp).cont;
        end
    end

    % Generate random data

    PLP_ID = DVBT2.PLP(prbsPLP).PLP_ID; % PLP_ID for the PLP that the PRBS is based on
    
    pktHeaderLen = 32;
    OUPL = 188*8; % This only works for TS anyway

    numBits = numPackets*(OUPL-pktHeaderLen);

    data = zeros(OUPL/8,numPackets);
    PID = 2^12+PLP_ID;
    data(1,:) = hex2dec('47');
    data(2,:) = floor(PID/256); % 000 then most sig 5 bits of PID
    data(3,:) = bitand(255, PID); % LS 8 bits of PID
    data(4,:) = 16 + bitand(cont:cont+numPackets-1, 15); % 0001 then 4 bit counter
    if ~DVBT2.SIM.EN_DJB_SHORTCUTS
        data(5:end,:) = reshape(t2_tx_dvbt2itudatagen_prbsseq_precalc(plp, numBits, DVBT2, init, prbsPLP),(OUPL-pktHeaderLen)/8,[]);
    end
    
    % keep continuity count for next time
    cont = bitand(cont+numPackets, hex2dec('0F'));
    if isCommonInData
        DVBT2_STATE.DATAGEN.NORMAL.PLP(plp).contCommon = cont;
    else
        DVBT2_STATE.DATAGEN.NORMAL.PLP(plp).cont = cont;
    end
end
