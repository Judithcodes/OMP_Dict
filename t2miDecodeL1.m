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
%* Description : t2miDecodeL1 DVBT2 T2-MI decoder: decode L1 packet
%******************************************************************************
function [l1p l1c l1d] = t2miDecodeL1(t2miPacket)

if t2miPacket.packet_type ~= hex2dec('10')
    return
end

% Decode L1pre

[rest l1p.type l1p.bwt_ext l1p.s1 l1p.s2 l1p.l1_repetition_flag l1p.guard_interval l1p.papr ...
    l1p.l1_mod l1p.l1_cod l1p.l1_fec_type l1p.l1_post_size l1p.l1_post_info_size l1p.pilot_pattern ...
    l1p.tx_id_availability l1p.cell_id l1p.network_id l1p.t2_system_id l1p.num_t2_frames l1p.num_data_symbols l1p.regen_flag ...
    l1p.l1_post_extension l1p.num_rf l1p.current_rf_idx l1p.reserved] = ...
    splitBitFields(t2miPacket.l1pre, [8 1 3 4 1 3 4 4 2 2 18 18 4 8 16 16 16 8 12 3 1 3 3 10], 'bits');

% L1 configurable

[rest l1c.sub_slices_per_frame l1c.num_plp l1c.num_aux l1c.aux_config_rfu] = splitBitFields(t2miPacket.l1conf, [15 8 4 8], 'bits');

for i=1:l1p.num_rf
    [rest l1c.rf_idx(i) l1c.frequency(i)] = splitBitFields(rest, [3 32], 'bits');
end

if bitand(l1p.s2, 1)==1
    [rest l1c.fef_type l1c.fef_length l1c.fef_interval] = splitBitFields(rest, [4 22 8], 'bits');
end

for i=1:l1c.num_plp
    [rest l1c.plp_id(i) l1c.plp_type(i) l1c.plp_payload_type(i) l1c.ff_flag(i) l1c.first_rf_idx(i) l1c.first_frame_idx(i) l1c.plp_group_id(i) ...
        l1c.plp_cod(i) l1c.plp_mod(i) l1c.plp_rotation(i) l1c.plp_fec_type(i) l1c.plp_num_blocks_max(i) l1c.frame_interval(i) ...
        l1c.time_il_length(i) l1c.time_il_type(i) l1c.in_band_a_flag(i) l1c.in_band_b_flag(i) l1c.reserved_1(i) l1c.plp_mode(i) l1c.static_flag(i) l1c.static_padding_flag(i)] = ...
        splitBitFields(rest, [8 3 5 1 3 8 8 3 3 1 2 10 8 8 1 1 1 11 2 1 1], 'bits');
end

[rest l1c.reserved_2] = splitBitFields(rest, 32);

for i=1:l1c.num_aux
    [rest l1c.aux_rfu(i)] = splitBitFields(rest, 32);
end


% L1 dynamic
[rest l1d.frame_idx l1d.sub_slice_interval l1d.type_2_start l1d.l1_change_counter l1d.start_rf_idx l1d.reserved_1] = ...
    splitBitFields(t2miPacket.l1dyn, [8 22 22 8 3 8], 'bits');

for i=1:l1c.num_plp
    [rest l1d.plp_id(i) l1d.plp_start(i) l1d.plp_num_blocks(i) l1d.reserved_2(i)] = splitBitFields(rest, [8 22 10 8], 'bits');
end

assert(isequal(l1c.plp_id,l1d.plp_id)); % should be in same order in conf and dynamic

[rest l1d.reserved_3] = splitBitFields(rest, 8, 'bits');

for i=1:l1c.num_aux
    [rest l1d.aux_rfu(i)] = splitBitFields(rest, 48, 'bits');
end

end
