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
%* Description : get_t2mi_packet DVBT2 Get T2-MI packet from fidTS
%******************************************************************************
function [packet state] = get_t2mi_packet(fidTS, state, pid, isDataPiping)

t2miHeaderBytes = 6;
t2miCRCBytes = 4;

if nargin<2 || isempty(state)
    state.data = [];
	state.previous_packet_count = -1;
end

if nargin<4
    isDataPiping = true;
end

data = state.data;
previous_packet_count = state.previous_packet_count;

packet = [];

if isDataPiping


    if isempty(data)
        tsPacket = get_ts_packet(fidTS, pid);

        % Keep going until we get a TS packet containing the start of a T2MI packet
        while (~tsPacket.pusi)
            tsPacket = get_ts_packet(fidTS, pid);
            if feof(fidTS)
                return
            end
        end

        % Get start position indicator: always the first byte if pusi=1
        startPos = tsPacket.payload(1);

        data = tsPacket.payload(startPos+2:end);
    end

    % keep going until we have enough data for a T2MI packet header
    while length(data)<t2miHeaderBytes
        tsPacket = get_ts_packet(fidTS, pid);
        if feof(fidTS)
            return
        end
        data = [data tsPacket.payload(tsPacket.pusi+1:end)]; % skip the packet start pos if present
    end
else
    data = fread(fidTS, t2miHeaderBytes, 'uint8')';
    if feof(fidTS)
        return
    end
end

% Extract and decode the header

[data packet.packet_type packet.packet_count packet.superframe_idx packet.rfu packet.payload_len ] = ...
    splitBitFields(data, [8 8 4 12 16],'bytes');

payloadBytes = ceil(packet.payload_len/8);

if isDataPiping
    % Keep getting TS packets until we have read the whole packet
    while length(data)<payloadBytes+t2miCRCBytes
        tsPacket = get_ts_packet(fidTS, pid);
        if feof(fidTS)
            return
        end
        data = [data tsPacket.payload(tsPacket.pusi+1:end)]; % skip the packet start pos if present
    end
else
    data = fread(fidTS, payloadBytes+t2miCRCBytes, 'uint8')';
    if feof(fidTS)
        return
    end

end

payload = data(1:payloadBytes);
packet.crc32 = data(payloadBytes+1:payloadBytes+t2miCRCBytes);


if isDataPiping
    % Keep the remainder of the TS packet for next time
    data = data(payloadBytes+t2miCRCBytes+1:end);

    % deal with an "Erik"
    if length(data)==1
        if exist('tsPacket')     % andrewm deal with case where no new TS packet is read (ie 2 pkts starting in a TS pkt but last one ends 1 byte before end)
           if tsPacket.pusi==0
            fprintf(1, 'ERIK length data 1 %x\n', data(1));
            assert(data==hex2dec('FF'));
            data = []; % last byte is padding in this case
           end
        end
    end
end

if previous_packet_count ~= -1
  previous_packet_count = previous_packet_count + 1;
  if previous_packet_count > 255
    previous_packet_count = 0;
  end
  %fprintf(1,'now: %d, previous: %d\n', packet.packet_count, previous_packet_count);
  assert (packet.packet_count == previous_packet_count);
end

switch packet.packet_type
    case hex2dec('00') % Baseband Frame
        [packet.bbframe packet.frame_idx packet.plp_id packet.intl_frame_start packet.rfu2 ] = ...
            splitBitFields(payload,[8 8 1 7],'bytes');
%        fprintf('packet %x %x %x %x %x %x %x %x %x %x\n', payload(4:13));

    case hex2dec('10') % L1-current
        [rest packet.frame_idx packet.rfu2] = ...
            splitBitFields(payload,[8 8],'bytes');
        rest = reshape(de2bi(rest', 8, 'left-msb')',1,[]);
        [packet.l1pre rest] = getBitField(rest,168,1);
        [packet.l1conf_len rest] = getBitField(rest, 16);
        [packet.l1conf rest] = getBitField(rest,8*ceil(packet.l1conf_len/8),1);
        packet.l1conf = packet.l1conf(1:packet.l1conf_len);
        [packet.l1dyn_len rest] = getBitField(rest, 16);
        [packet.l1dyn rest] = getBitField(rest,8*ceil(packet.l1dyn_len/8),1);
        packet.l1dyn = packet.l1dyn(1:packet.l1dyn_len);
        [packet.l1ext_len rest] = getBitField(rest, 16);
        [packet.l1ext rest] = getBitField(rest,8*ceil(packet.l1ext_len/8),1);
        packet.l1ext = packet.l1ext(1:packet.l1ext_len);
        
    case hex2dec('11') % L1-future
        [rest packet.frame_idx packet.rfu] = splitBitFields(payload, [8 8], 'bytes');
        rest = reshape(de2bi(rest', 8, 'left-msb')',1,[]);
        [packet.l1dyn_next_len rest] = getBitField(rest, 16);
        [packet.l1dyn_next rest] = getBitField(rest,8*ceil(packet.l1dyn_next_len/8),1);
        packet.l1dyn_next = packet.l1dyn_next(1:packet.l1dyn_next_len);
        [packet.l1dyn_next2_len rest] = getBitField(rest, 16);
        [packet.l1dyn_next2 rest] = getBitField(rest,8*ceil(packet.l1dyn_next2_len/8),1);
        packet.l1dyn_next2 = packet.l1dyn_next2(1:packet.l1dyn_next2_len);
        [packet.num_inband rest] = getBitField(rest, 8);
        for i=1:packet.num_inband
            [packet.plp_id(i) rest] = getBitField(rest,8);
            [packet.inband_len(i) rest] = getBitField(rest,16);
            [packet.inband{i} rest] = getBitField(rest, 8*ceil(packet.inband_len(i)/8),1);
            packet.inband{i} = packet.inband{i}(1:packet.inband_len(i));
        end
        
    case hex2dec('30') % Null FEF part
        [rest packet.fef_idx packet.rfu packet.s1_field packet.s2_field] = splitBitFields(payload, [8 9 3 4], 'bytes');
end

state.data = data;
state.previous_packet_count = packet.packet_count;
    
end


