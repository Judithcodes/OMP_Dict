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
%* Description : t2_tx_dvbt2dynvvdatagen_cat3packets DVBT2 V&V group
%*               category 3 packet generator
%******************************************************************************

function data = t2_tx_dvbt2dynvvdatagen_cat3packets(numPackets, isActual, isPresFol, plp, describedPLP, DVBT2, init, commonPLP)

    if nargin<8
        commonPLP = plp;
    end
    
    isCommonInData = (commonPLP ~= plp);
    
    global DVBT2_STATE;
    if init
        cont = 0; % Continuity count for PLP
    else
        if isCommonInData
            cont = DVBT2_STATE.DATAGEN.CAT3.PLP(plp).eit_cont_common;
        else
            cont = DVBT2_STATE.DATAGEN.CAT3.PLP(plp).eit_cont;
        end
    end

  
    
    
    
    % Generate random data

    PLP_ID = DVBT2.PLP(plp).PLP_ID;
    pktHeaderLen = 32;
    OUPL = 188*8; % This only works for TS anyway

    numBits = numPackets*(OUPL-pktHeaderLen);

    data = zeros(OUPL/8,numPackets);
    PID = hex2dec('0012');
    data(1,:) = hex2dec('47');
    data(2,:) = 64 + floor(PID/256); % 010 then most sig 5 bits of PID (PUSI=1)
    data(3,:) = bitand(255, PID); % LS 8 bits of PID
    data(4,:) = 16 + bitand(cont:cont+numPackets-1, 15); % 0001 then 4 bit counter
    data(5,:) = 0; % section start

    section = [
        0 0 0 0 0 0 0 0  ...
        1 ...
        1 ...
        1 1 ...
        0 0 0 0 0 0 0 1 1 0 1 1 ...
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ...
        1 1 ...
        0 0 0 0 0 ...
        0 ...
        0 0 0 0 0 0 0 0 ...
        0 0 0 0 0 0 0 0 ...
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ...
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ...
        0 0 0 0 0 0 0 0 ...
        0 0 0 0 0 0 0 0 ...
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ...
        zeros(1,40) ...
        zeros(1,24) ...
        1 0 0 ...
        0 ...
        0 0 0 0 0 0 0 0 0 0 0 0 ...
        ];
    
    section = bi2de(reshape(section,8,[])','left-msb');
    section(4) = hex2dec('12');
    section(9) = hex2dec('34');
    section(15) = hex2dec('56');
    data(6:6+length(section)-1,:) = repmat(section,1,numPackets);
    % Table IDs
    data(6,isActual & isPresFol) = hex2dec('4E'); % Table ID = EIT actual present/following
    data(6,isActual & ~isPresFol) = hex2dec('50'); % Table ID = EIT actual schedule
    data(6,~isActual & isPresFol) = hex2dec('4F'); % Table ID = EIT other present/following
    data(6,~isActual & ~isPresFol) = hex2dec('60'); % Table ID = EIT other schedule
    data(19,:) = data(6,:); % last table ID

    if ~DVBT2.SIM.EN_DJB_SHORTCUTS % skip CRC calculation if only running it for DJB simulations
        % Calculate the CRCs
        for i=1:numPackets
            data(10,i) = DVBT2.PLP(describedPLP(i)).PLP_ID;  % Service ID
            data(15,i) = DVBT2.PLP(describedPLP(i)).PLP_ID;  % TS ID
            data(21,i) = DVBT2.PLP(describedPLP(i)).PLP_ID;  % event_id
            recalc = true;
            if (i>1)
                if describedPLP(i)==describedPLP(i-1) && isActual(i)==isActual(i-1) && isPresFol(i)==isPresFol(i-1)
                    recalc = false; % can reuse previous CRC
                end
            end
            if recalc
                crc = dvb_crc32(data(6:6+length(section)-1,i), true);
                crc = de2bi(crc,32,'left-msb');
            end
            data(6+length(section):6+length(section)+3,i) = bi2de(reshape(crc, 8,[])', 'left-msb');
        end
    end

    data(6+length(section)+4:end,:) = hex2dec('FF'); % Pad rest of packet with FF

    % keep continuity count for next time
    cont = bitand(cont+numPackets, hex2dec('0F'));
    if isCommonInData
        DVBT2_STATE.DATAGEN.CAT3.PLP(plp).eit_cont_common = cont;
    else
        DVBT2_STATE.DATAGEN.CAT3.PLP(plp).eit_cont = cont;
    end
end
