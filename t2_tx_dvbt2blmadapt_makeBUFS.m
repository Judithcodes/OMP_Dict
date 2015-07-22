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
%* Description : t2_t2_dvbt2blmadapt_makeBUFS DVBT2 ISSY BUFS variable generator
%******************************************************************************
function ISSYb = t2_tx_dvbt2blmadapt_makeBUFS(BufferSize, numBytes)
    if BufferSize <= 1023
        BUFSVal = BufferSize;
        UNITb = [0 0]; % bits
    elseif ceil(BufferSize/1024) <=1023
        BUFSVal = ceil(BufferSize/1024);
        UNITb = [0 1]; % Kbits
    elseif ceil(BufferSize/8192) <=1023
        BUFSVal = ceil(BufferSize/8192);
        UNITb = [1 1]; % 8-Kbits
    else
        BUFSVal = ceil(BufferSize/(2^20));
        UNITb = [1 0]; % Mbits
    end

    ISSYb = [1 1 0 0 UNITb de2bi(BUFSVal, 10, 'left-msb')];
    if numBytes==3
        ISSYb = [ISSYb zeros(1,8)];
    end
end
