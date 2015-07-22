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
%* Description : T2_TX_DVBT2BLMADAPT_INBANDGENB
%*
%******************************************************************************

function inBandField = t2_tx_dvbt2blmadapt_inbandgenB(TTO, ISCRTotal, bufferSize, tsRate)

PADDING_TYPE = de2bi(1,2, 'left-msb');
TTO = de2bi(round(TTO), 31, 'left-msb');
FIRST_ISCR = de2bi(mod(round(ISCRTotal),2^22), 22, 'left-msb');
BUFS_ISSY = t2_tx_dvbt2blmadapt_makeBUFS(bufferSize, 2);
BUFS_UNIT = BUFS_ISSY(5:6);
BUFS = BUFS_ISSY(7:end);
TS_RATE = de2bi(round(tsRate), 27, 'left-msb');
RESERVED_B = de2bi(0,8,'left-msb');

inBandField = [PADDING_TYPE TTO FIRST_ISCR BUFS_UNIT BUFS TS_RATE RESERVED_B];

end
