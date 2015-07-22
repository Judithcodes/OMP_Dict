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
%* Description : T2_TX_DVBT2MIL1GEN DVBT2 L1 signalling generation and coding
%*               DOUT = T2_TX_DVBT2L1GEN(DVBT2, FID, DIN) passes the input
%                data straight and BICMs the L1 received via T2MI
%                signalling, including adding the CRC.
%******************************************************************************

function DataOut = t2_tx_dvbt2mil1gen(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2mil1gen SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------

NUM_SIM_T2_FRAMES = DVBT2.NUM_SIM_T2_FRAMES;

N_T2  = DVBT2.N_T2; % Number of T2 frames per superframe

NUM_PLPS = DVBT2.NUM_PLPS;
START_T2_FRAME = DVBT2.START_T2_FRAME;

SPEC_VERSION = DVBT2.SPEC_VERSION;

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
data = DataIn.data;
SCHED = DataIn.sched;
l1 = DataIn.l1;

switch SPEC_VERSION
    case '1.0.1'
        specVersionCode = 0; % this version (the original Blue Book) did not have an official ETSI number
    case '1.1.1'
        specVersionCode = 0; 
    case '1.2.1'
        specVersionCode = 1; 
end

%--------------------------------------------------------------------------
% Generate signalling from DVB structure
%--------------------------------------------------------------------------


L1pre = [];
L1post = [];

% matrices for the intermediate testpoints.
L1prebits = [];
L1prepadded = [];
L1prebchout = [];
L1preldpcout = [];
L1prepunctureout = [];
L1postbits = [];
L1postpadded = [];
L1postbchout = [];
L1postldpcout = [];
L1postpunctureout = [];
L1postbitout = [];


% assume input is one row per T2-frame
L1_pre_bits = l1.pre;
L1_post_bits = [l1.conf l1.dyn l1.dyn_next l1.ext];

for m = 1:NUM_SIM_T2_FRAMES
        
    % encode and modulate it
    if DVBT2.L1_ACE_MAX > 0
        fprintf(FidLogFile,'\t\tL1 ACE Enabled (L1_ACE_MAX=%d)\n', DVBT2.L1_ACE_MAX);
    end
    [frameL1pre, frameL1post, frameL1test] = t2_tx_dvbt2bll1gen_l1coding(L1_pre_bits(m,:).', L1_post_bits(m,:).', DVBT2);
    L1pre = [L1pre frameL1pre];
    L1post = [L1post frameL1post];
  
    % Concatenate the intermediate points
    L1prebits = [L1prebits frameL1test.pre.bits];
    L1prepadded = [L1prepadded frameL1test.pre.padded];
    L1prebchout = [L1prebchout frameL1test.pre.bchout];
    L1preldpcout = [L1preldpcout frameL1test.pre.ldpcout];
    L1prepunctureout = [L1prepunctureout frameL1test.pre.punctureout];

    L1postbits = [L1postbits frameL1test.post.bits];
    L1postpadded = [L1postpadded frameL1test.post.padded];
    L1postbchout = [L1postbchout frameL1test.post.bchout];
    L1postldpcout = [L1postldpcout frameL1test.post.ldpcout];
    L1postpunctureout = [L1postpunctureout frameL1test.post.punctureout];
    L1postbitout = [L1postbitout frameL1test.post.bitout];

    fprintf(FidLogFile,'\t\tFrame %d Sum of uncoded L1 bits = %d (of %d bits)\n', ...
        START_T2_FRAME+m, sum(frameL1test.pre.bits)+sum(frameL1test.post.bits), ...
        length(frameL1test.pre.bits)+length(frameL1test.post.bits));
    fprintf(FidLogFile,'\t\tFrame %d Sum of coded L1 bits = %d (of %d bits)\n', ...
        START_T2_FRAME+m, sum(frameL1test.pre.punctureout)+sum(frameL1test.post.bitout(:)), ...
        length(frameL1test.pre.punctureout)+length(frameL1test.post.bitout(:)));
    fprintf(FidLogFile,'\t\tFrame %d Sum of modulated L1 cells = %f + %fi (of %d cells)\n', ...
        START_T2_FRAME+m, real(sum([frameL1pre; frameL1post])), imag(sum([frameL1pre; frameL1post])), ...
        length([frameL1pre; frameL1post]));
        
end

fprintf(FidLogFile,'\t\tT2 Frames of L1 generated = %d frames\n', NUM_SIM_T2_FRAMES);

% Write all the test points
write_vv_test_point(L1prebits, size(L1prebits,1), 1, '20', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1prepadded, size(L1prepadded,1), 1, '21', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1prebchout, size(L1prebchout,1), 1, '22', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1preldpcout, size(L1preldpcout,1), 1, '23', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1prepunctureout, size(L1prepunctureout,1), 1, '24', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1pre, size(L1pre,1), 1, '25', 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1);

write_vv_test_point(L1postbits, size(L1postbits,1), 1, '26', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1postpadded, size(L1postpadded,1), 1, '27', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1postbchout, size(L1postbchout,1), 1, '28', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1postldpcout, size(L1postldpcout,1), 1, '29', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1postpunctureout, size(L1postpunctureout,1), 1, '30', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1postbitout, size(L1postbitout,1), 1, '31', 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1);
write_vv_test_point(L1post, size(L1post,1), 1, '32', 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1);

DataOut.data = data;
DataOut.l1.pre = L1pre;
DataOut.l1.post = L1post;
DataOut.sched = SCHED;
