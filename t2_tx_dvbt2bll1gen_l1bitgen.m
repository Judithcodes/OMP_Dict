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
%* Description : t2_tx_dvbt2bll1gen_l1bitgen DVBT2 L1 coding bit generation
%******************************************************************************
function [L1_pre_bits, L1_post_bits] = t2_tx_dvbt2bll1gen_l1bitgen(L1, DVBT2)

N_P2 = DVBT2.STANDARD.N_P2;
NUM_PLPS = DVBT2.NUM_PLPS;
SPEC_VERSION = DVBT2.SPEC_VERSION;
L1_REPETITION_FLAG = DVBT2.L1_REPETITION_FLAG;

% Concatenate config into one string
config = [L1.config.SUB_SLICES_PER_FRAME L1.config.NUM_PLP...
          L1.config.NUM_AUX L1.config.AUX_CONFIG_RFU L1.config.RF_IDX(1,:) L1.config.FREQUENCY(1,:) ...
          L1.config.FEF_TYPE L1.config.FEF_LENGTH L1.config.FEF_INTERVAL];
for plp = 1:NUM_PLPS
          config = [config L1.config.PLP_ID(plp,:)...
          L1.config.PLP_TYPE(plp,:) L1.config.PLP_PAYLOAD_TYPE(plp,:) L1.config.FF_FLAG(plp,:)...
          L1.config.FIRST_RF_IDX(plp,:)...
          L1.config.FIRST_FRAME_IDX(plp,:) L1.config.PLP_GROUP_ID(plp,:) L1.config.PLP_COD(plp,:) L1.config.PLP_MOD(plp,:)...
          L1.config.PLP_ROTATION(plp,:)...
          L1.config.PLP_FEC_TYPE(plp,:) L1.config.PLP_NUM_BLOCKS_MAX(plp,:) L1.config.FRAME_INTERVAL(plp,:)...
          L1.config.TIME_IL_LENGTH(plp,:) L1.config.TIME_IL_TYPE(plp,:) L1.config.IN_BAND_A_FLAG(plp,:)...
          L1.config.IN_BAND_B_FLAG(plp,:) L1.config.RESERVED_1(plp,:) L1.config.PLP_MODE(plp,:) ...
          L1.config.STATIC_FLAG(plp,:) L1.config.STATIC_PADDING_FLAG(plp,:) ...
          ];
end
config = [config L1.config.FEF_LENGTH_MSB L1.config.RESERVED_2];

for aux = 1:DVBT2.NUM_AUX
    config = [config L1.config.AUX_STREAM_TYPE(aux,:) L1.config.AUX_PRIVATE_CONF(aux,:)];
end

% Concatenate dynamic into one string without the CRC_32 field
dynamic = makeDynamicBits(DVBT2, L1.dynamic);

if L1_REPETITION_FLAG
    dynamic_next_frame = makeDynamicBits(DVBT2,L1.dynamic_next_frame);
else
    dynamic_next_frame = [];
end

% Extension field
extension = [];

for blocknum = 1:length(L1.extension.block) % for each block
    extension = [extension L1.extension.block(blocknum).l1_ext_block_type L1.extension.block(blocknum).l1_ext_block_len ...
                  L1.extension.block(blocknum).l1_ext_block_data];
end

% Make L1 post out of config and dynamic plus optional bits
post = [config dynamic dynamic_next_frame extension];
       
post_info_size = length(post);

% Do the big post calculation
[N_post_FEC_block, K_sig, K_bch, N_post, N_punc, N_mod_total, N_mod_per_block, K_L1_PADDING] = t2_tx_dvbt2bll1gen_l1calcs(DVBT2, post_info_size);

% Set the fields of L1-post
L1.pre.L1_POST_INFO_SIZE = dec2bin(post_info_size,18);

L1.pre.L1_POST_SIZE = dec2bin(N_mod_total,18);

% Concatenate pre into one string without the CRC_32 field
pre = [L1.pre.TYPE L1.pre.BWT_EXT L1.pre.S1 L1.pre.S2 L1.pre.L1_REPETITION_FLAG...
       L1.pre.GUARD_INTERVAL L1.pre.PAPR L1.pre.L1_MOD L1.pre.L1_COD L1.pre.L1_FEC_TYPE...
       L1.pre.L1_POST_SIZE L1.pre.L1_POST_INFO_SIZE L1.pre.PILOT_PATTERN L1.pre.TX_ID_AVAILABILITY...
       L1.pre.CELL_ID L1.pre.NETWORK_ID L1.pre.T2_SYSTEM_ID L1.pre.NUM_T2_FRAMES...
       L1.pre.NUM_DATA_SYMBOLS L1.pre.REGEN_FLAG L1.pre.L1_POST_EXTENSION L1.pre.NUM_RF...
       L1.pre.CURRENT_RF_IDX L1.pre.T2_VERSION L1.pre.L1_POST_SCRAMBLED L1.pre.T2_BASE_LITE L1.pre.RESERVED
       ];

% Bias balancing -------------------------------------------------

% treat pre- and post- as one block
prepost = [pre post];

    
Nb0 = sum(prepost=='0');
Nb1 = sum(prepost=='1');
Nbias = Nb0-Nb1;
Nres = sum(prepost=='x');

if (strcmp(SPEC_VERSION, '1.0.1') || strcmp(SPEC_VERSION, '1.1.1') || DVBT2.L1_BIAS_BALANCING_BITS == 0)
    N1 = 0; % no bias balancing before version 1.2.1
elseif (Nbias<-Nres)
    N1 = 0;
elseif (Nbias>Nres)
    N1 = Nres;
else
    N1 = floor((Nbias+Nres)/2);
end

resBits = [repmat('1',1,N1) repmat('0',1,Nres-N1)];
prepost(prepost=='x') = resBits;

pre = prepost(1:length(pre));
post = prepost(length(pre)+1:end);

%----------------------------

% Convert L1 pre from text to numeric
L1_pre_bits = double(pre=='1')';

% Convert L1 post from text to numeric 
L1_post_bits = double(post=='1')';

end

function dynamic = makeDynamicBits(DVBT2, l1d)

dynamic = [l1d.FRAME_IDX l1d.SUB_SLICE_INTERVAL l1d.TYPE_2_START l1d.L1_CHANGE_COUNTER...
           l1d.START_RF_IDX l1d.RESERVED_1];
for plp = 1:DVBT2.NUM_PLPS       
       dynamic = [dynamic l1d.PLP_ID(plp,:)...
           l1d.PLP_START(plp,:) l1d.PLP_NUM_BLOCKS(plp,:) l1d.RESERVED_2(plp,:)];
end
dynamic = [dynamic l1d.RESERVED_3];

for aux = 1:DVBT2.NUM_AUX
    dynamic = [dynamic l1d.AUX_PRIVATE_DYN(aux,:)];
end

end


