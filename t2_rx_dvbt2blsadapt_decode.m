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
%* Description : T2_TX_DVBT2BLSADAPT DVBT2 Stream Adaptation
%*               DOUT = T2_TX_DVBT2BLSADAPT(DVBT2, FID, DIN) builds BB
%*               frames and applies BB scrambling.  FID specifies
%*               the file where any debug message is sent.
%
%                This version does not read the input file, but does the
%                decoding of DFL/DNP from the received data
%******************************************************************************

function [DataOut] = t2_rx_dvbt2blsadapt_decode(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2blsadapt_decode SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
PLP = DVBT2.RX_PLP; % PLP to decode in the receiver

K_BCH        = DVBT2.STANDARD.PLP(PLP).OCOD.K_BCH;   % BCH unencoded block length
STREAM       = DVBT2.PLP(PLP).STREAM;                % Stream parameters
NUM_INT_FRAMES = DVBT2.NUM_SIM_T2_FRAMES / (DVBT2.PLP(PLP).P_I * DVBT2.PLP(PLP).I_JUMP);
IN_BAND_A_FLAG = DVBT2.PLP(PLP).IN_BAND_A_FLAG;
P_I          = DVBT2.PLP(PLP).P_I;
I_JUMP       = DVBT2.PLP(PLP).I_JUMP;
IN_BAND_LEN  = DVBT2.STANDARD.PLP(PLP).IN_BAND_LEN;
SIM_DIR  = DVBT2.SIM.SIMDIR;    % Simulation directory 

% State initialisation
global DVBT2_STATE;
if DVBT2.START_T2_FRAME == 0
    DVBT2_STATE.RX.SADAPT.UNUSED_RX_BITS = []; % partial packet from end of last BBF can't be output
end

% Retrieve state

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

dataAux = DataIn';

madapt_data = reshape(dataAux, K_BCH/8, []); % arrange into one BBFrame per column

dataFieldLengths = 256*madapt_data(5,:) + madapt_data(6,:); % Decode DFL from Tx

% Convert input byte array to binary array
if ~isempty(dataAux)
    dataAuxBin = reshape(de2bi(dataAux, 8, 'left-msb').', 1, []);
else
    dataAuxBin = [];
end

numHeaderBits = 80;
numDataFieldBitsMax = K_BCH-numHeaderBits;   
numBBFrames = floor(length(dataAuxBin)/K_BCH);

fprintf(FidLogFile,'\t\tNumber of complete BB frames: %d (%d data bits per frame)\n', numBBFrames, numDataFieldBitsMax);
fprintf(FidLogFile,'\t\tNumber of transmitted bytes: %d\n', numBBFrames*numDataFieldBitsMax/8);

% Get BB scrambling sequence
bbPrbs = t2_rx_dvbt2blsadapt_bbprbsseq(K_BCH);

% Initialise output array (with any data saved from last time)
bbUnframedData = DVBT2_STATE.RX.SADAPT.UNUSED_RX_BITS;

% Initialise CRC8 failure count
crcFailureCount = 0;

for bbFrameIdx = 1:numBBFrames 
    
    numDataFieldBits = dataFieldLengths(bbFrameIdx);

    headerStart = ((bbFrameIdx - 1)*K_BCH) + 1;
    dataEnd = headerStart + K_BCH - 1;
    
    scrambledBbFrame = dataAuxBin(headerStart:dataEnd);
    bbFrame = xor(scrambledBbFrame, bbPrbs);    
    
    % Remove data before first SYNCD
    if DVBT2.START_T2_FRAME == 0 && bbFrameIdx == 1
        syncd = bi2de(bbFrame(57:72), 'left-msb');
    else
        syncd = 0; % Not really, but don't need to account for it after the first time
    end
    
    write_bbf_file(FidLogFile, bi2de(reshape(bbFrame, 8, []).', 'left-msb'), DVBT2.SIM.PLP(PLP).RX_BBF_FILENAME, DVBT2.START_T2_FRAME==0 && bbFrameIdx==1);

    % Extrect header field bits and convert to byte array
    headerBits = bbFrame(1:numHeaderBits);
    headerBits(end) = xor(headerBits(end), STREAM.MODE);
    headerField = bi2de(reshape(headerBits, 8, []).', 'left-msb');
        
    % Check CRC8 and increment failure count appropriately
    crcFailureCount = crcFailureCount + (t2_rx_dvbt2blsadapt_crc8(headerField) ~= 0);
    
    % Extract data field bits NB might not be a whole number of bytes
    dataField = bbFrame((numHeaderBits+1+syncd):(numHeaderBits+numDataFieldBits));
    
    bbUnframedData = [bbUnframedData, dataField];
end


OUPLbytes = STREAM.UPL/8;
UPLbytes = OUPLbytes;
if STREAM.TS_GS == 0 || STREAM.TS_GS == 3 % TS or GFPS
    UPLbytes = UPLbytes -1; % because sync byte is always removed
    % remove CRC8 from each user packet in normal mode
    if (STREAM.MODE == 0)  % Normal mode
        UPLbytes = UPLbytes + 1; % there is a CRC
        if (STREAM.ISSYI)
            UPLbytes = UPLbytes + STREAM.ISSYLEN;
        end
    end
    if (STREAM.NPD)
        UPLbytes = UPLbytes + 1; % there is a DNP count
    end

    % Use only the complete packets this time - keep the rest for next time
    numCompletePackets = floor(numel(bbUnframedData) / (UPLbytes*8));
    numBits = numCompletePackets * UPLbytes * 8;
    
    DVBT2_STATE.RX.SADAPT.UNUSED_RX_BITS = bbUnframedData(numBits+1:end);
    
    bbUnframedData = bbUnframedData(1:numBits);

    % Convert to bytes
    bbUnframedData = reshape(bbUnframedData, 8,[]).';
    if ~isempty(bbUnframedData)
        bbUnframedData = bi2de(bbUnframedData, 'left-msb');
    end
    
    bbUnframedData = reshape(bbUnframedData, UPLbytes, []);% one packet per column
    
    if (STREAM.MODE == 0)
        bbUnframedData = bbUnframedData(1:UPLbytes-1,:); % Remove the CRC
        UPLbytes = UPLbytes -1;
    end

    if (STREAM.NPD)
%        DNPs = txUnframedData(UPLbytes,:); % Extract the DNP counts from the transmitted packets
        DNPs = bbUnframedData(UPLbytes,:); % Extract the DNP counts from the transmitted packets
        bbUnframedData = bbUnframedData(1:UPLbytes-1,:); % remove DNP counts
        UPLbytes = UPLbytes - 1;
    else
        DNPs = zeros(1,numCompletePackets);
    end
    
    if (STREAM.ISSYI && STREAM.MODE == 0)
        % Remove the ISSY bytes
        UPLbytes = UPLbytes - STREAM.ISSYLEN;
        bbUnframedData = bbUnframedData(1:UPLbytes, :);
    end
    
    bbUnframedData = [zeros(1,numCompletePackets); bbUnframedData]; % put space at the top for the sync byte
    bbUnframedData(1,:) = STREAM.SYNC; % Reinsert the sync bytes
    UPLbytes = UPLbytes+1;
    
    % Reinsert the deleted null packets
    nullPacket = zeros(188,1);
    nullPacket(1) = hex2dec('47');
    nullPacket(2) = hex2dec('1f');
    nullPacket(3) = hex2dec('ff');
    nullPacket(4) = hex2dec('10');
    
    outputPackets = zeros(UPLbytes, numCompletePackets+sum(DNPs)); % Empty array for output packets
    pktIdx = 1;
    for i=1:numCompletePackets
        % Write the run of null packets
        outputPackets(:,pktIdx:pktIdx+DNPs(i)-1) = repmat(nullPacket, 1, DNPs(i));
        pktIdx = pktIdx + DNPs(i);
        % Write the real packet
        outputPackets(:,pktIdx) = bbUnframedData(:,i);
        pktIdx = pktIdx + 1;
    end
    
    bbUnframedData = reshape(outputPackets,[],1);

end


fprintf(FidLogFile,'\t\tNumber of CRC8 failures: %d/%d\n', crcFailureCount, numBBFrames);

DataOut = bbUnframedData';


