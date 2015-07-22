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
%* Description : splitBitFields: Split data into bitfields according to 
%*               specified fieldLengths
%******************************************************************************
function [rest, varargout] = splitBitFields(data, fieldLengths, ioFormat)

if nargin <3
    ioFormat = 'bits'; % input and rest output is bits by default
end

numBits = sum(fieldLengths);
numFields = length(fieldLengths);

fields=zeros(1, numFields);

if strcmp(ioFormat,'bytes')
    numBytes = numBits/8;
    assert(mod(numBytes,1)==0);
    fieldBits = de2bi(data(1:numBytes)',8,'left-msb')';
    fieldBits = fieldBits(:)';
    rest = data(numBytes+1:end);
else
    fieldBits = data(1:numBits);
    rest = data(numBits+1:end);
end

for i=1:numFields
    [fields(i) fieldBits] = getBitField(fieldBits, fieldLengths(i));
end

varargout = num2cell(fields); % return variable number of fields

end
