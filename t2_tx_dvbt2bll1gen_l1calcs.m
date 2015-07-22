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
%* Description : T2_TX_DVBT2L1GEN_L1CALCS DVBT2 L1 signalling generation and coding
%*               Calculates various values needed in the L1 encoding
%                
%******************************************************************************

function [N_post_FEC_block, K_sig, K_bch, N_post, N_punc, N_mod_total, N_mod_per_block, K_L1_PADDING] = t2_tx_dvbt2bll1gen_l1calcs(DVBT2, post_info_size)

N_P2 = DVBT2.STANDARD.N_P2;

switch DVBT2.L1_CONSTELLATION
    case 'BPSK'
        eta_mod = 1;
    case 'QPSK'
        eta_mod = 2;
    case '16-QAM'
        eta_mod = 4;
    case '64-QAM'
        eta_mod = 6;
end
        
L1.pre.L1_POST_INFO_SIZE = dec2bin(post_info_size,18);
K_bch = 7032;
K_post_ex_pad = post_info_size + 32;
N_post_FEC_block = ceil(K_post_ex_pad / K_bch);
K_L1_PADDING = ceil(K_post_ex_pad / N_post_FEC_block) * N_post_FEC_block - K_post_ex_pad;
K_post = K_post_ex_pad + K_L1_PADDING;
K_sig = K_post / N_post_FEC_block;
N_punc_temp = floor(6 / 5 * (K_bch - K_sig));
N_bch_parity = 168;
N_post_temp = K_sig + N_bch_parity + 9000 - N_punc_temp;

if N_P2 == 1
    N_post = ceil(N_post_temp / (2*eta_mod)) * 2*eta_mod;
else
    N_post = ceil(N_post_temp / (eta_mod * N_P2)) * eta_mod * N_P2;
end

N_punc = N_punc_temp - (N_post - N_post_temp);
N_mod_per_block = N_post / eta_mod;
N_mod_total = N_mod_per_block * N_post_FEC_block;
L1.pre.L1_POST_SIZE = dec2bin(N_mod_total,18);
