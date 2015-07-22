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
%* Description : t2_tx_dvbt2dynvvdatagen_cat2packets 
%*               DVB-T2 V&V group category 2 packet generator
%******************************************************************************

function data = t2_tx_dvbt2dynvvdatagen_cat2packets(numPackets, isActual, plp, describedPLP, DVBT2, init, commonPLP)

    if nargin<7
        commonPLP = plp;
    end
    
    isCommonInData = (commonPLP ~= plp);
    
    global DVBT2_STATE;
    if init
        cont = 0; % Continuity count for PLP
    else
        if isCommonInData
            cont = DVBT2_STATE.DATAGEN.CAT2.PLP(plp).sdt_cont_common;
        else
            cont = DVBT2_STATE.DATAGEN.CAT2.PLP(plp).sdt_cont;
        end
    end

    OUPL = 188*8; % This only works for TS anyway

    data = zeros(OUPL/8,numPackets);
    PID = hex2dec('0011');
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
        0 0 0 0 0 0 0 1 0 0 0 1 ...
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ...
        1 1 ...
        0 0 0 0 0 ...
        1 ...
        0 0 0 0 0 0 0 0 ...
        0 0 0 0 0 0 0 0 ...
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ...
        1 1 1 1 1 1 1 1 ...
        0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ...
        1 1 1 1 1 1 ...
        1 ...
        1 ...
        1 0 0 ...
        0 ...
        0 0 0 0 0 0 0 0 0 0 0 0 ...
        ];
    
    section = bi2de(reshape(section,8,[])','left-msb');
    section(4) = hex2dec('34');
    section(12) = hex2dec('12');
    data(6:6+length(section)-1,:) = repmat(section,1,numPackets);
    data(6,isActual) = hex2dec('42'); % Table ID = SDT actual
    data(6,~isActual) = hex2dec('46'); % Table ID = SDT other
    % Calculate the CRCs
    for i=1:numPackets
        data(10,i) = DVBT2.PLP(describedPLP(i)).PLP_ID; % TS_ID
        data(18,i) = DVBT2.PLP(describedPLP(i)).PLP_ID; % service ID
        crc = dvb_crc32(data(6:6+length(section)-1,i), true);
        crc = de2bi(crc,32,'left-msb');
        data(6+length(section):6+length(section)+3,i) = bi2de(reshape(crc, 8,[])', 'left-msb');
    end
    data(6+length(section)+4:end,:) = hex2dec('FF'); % Pad rest of packet with FF
    % keep continuity count for next time
    cont = bitand(cont+numPackets, hex2dec('0F'));
    if isCommonInData
        DVBT2_STATE.DATAGEN.CAT2.PLP(plp).sdt_cont_common = cont;
    else
        DVBT2_STATE.DATAGEN.CAT2.PLP(plp).sdt_cont = cont;
    end
end
