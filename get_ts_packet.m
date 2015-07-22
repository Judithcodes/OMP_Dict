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
%* Description : get_ts_packet Get transport stream packet from the file fidTS
%*               Gets the next packet with the specified pid.
%******************************************************************************
function packet = get_ts_packet(fidTS, pid)

if nargin<2
    pid = -1;
end

tsPacketLengthBytes = 188;
tsPacketHeaderBytes = 4;

done = 0;

while ~done % Keep going until we find a packet with the desired pid (-1 means any pid)

    % Read packet from file
    tsPacket = fread(fidTS, tsPacketLengthBytes, 'uint8')';

    if feof(fidTS)
        packet = [];
        return;
    end

    % Check sync byte
    assert(tsPacket(1)==hex2dec('47'));

    % Get header in bits
    header = tsPacket(1:tsPacketHeaderBytes);
    header = de2bi(header',8,'left-msb')';
    header = header(:)';

    % Read all the header fields
    [packet.sync header] = getBitField(header, 8);
    [packet.tei header] = getBitField(header, 1);
    [packet.pusi header] = getBitField(header, 1);
    [packet.priority header] = getBitField(header, 1);
    [packet.pid header] = getBitField(header, 13);
    [packet.scrambling header] = getBitField(header, 2);
    [packet.adaptation_exist header] = getBitField(header, 1);
    [packet.payload_exist header] = getBitField(header, 1);
    [packet.cc header] = getBitField(header, 4);

    % Skip header field
    if (packet.adaptation_exist)
        adaptation_field_len = tsPacket(tsPacketHeaderBytes+1)+1;
    else
        adaptation_field_len = 0;
    end

    % extract the adaptation field
    packet.adaptation_field = tsPacket(tsPacketHeaderBytes+1:tsPacketHeaderBytes+adaptation_field_len);
    % Extract the payload
    packet.payload = tsPacket(tsPacketHeaderBytes+1+adaptation_field_len:end);

    if packet.pid == pid || pid == -1
        done = 1;
    end
end
end

