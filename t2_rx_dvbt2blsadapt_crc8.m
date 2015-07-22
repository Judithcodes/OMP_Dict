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
%* Description : PRBS = T2_RX_DVBT2BLSADAPT_CRC8(argVector) calculates the
%*               Cyclic Redundency Check code (CRC-8) used to protect the  
%*               BB header
%******************************************************************************

function CRC8 = t2_rx_dvbt2blsadapt_crc8(argVector)


%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

% Initialize shift register
srBin = zeros(8, 1); % Shift register content

% Convert input byte array to binary array
inputBin = reshape(de2bi(argVector, 8, 'left-msb').', 1, []);

% process CRC-8
for n=1:length(argVector)*8
    fedBackBit = xor(srBin(8), inputBin(n));
    srBin(8) = xor(srBin(7), fedBackBit);
    srBin(7) = xor(srBin(6), fedBackBit);
    srBin(6) = srBin(5);
    srBin(5) = xor(srBin(4), fedBackBit);
    srBin(4) = srBin(3);
    srBin(3) = xor(srBin(2), fedBackBit);
    srBin(2) = srBin(1);
    srBin(1) = fedBackBit;
end

% convert shift register binary array into a number
CRC8 = bi2de(reshape(srBin, 8, []).', 'right-msb');
    
