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
%* Description : Writes test point for RBM V&V exercise. data has as many
%*               rows as needed - each one becomes a column in the output
%*               file
%*               
%******************************************************************************

function write_vv_rbm_test_point(data, tpNum, DVBT2, startCycle, subsampleFactor)

if (nargin<5)
    subsampleFactor = 100;
end


if ~DVBT2.SIM.EN_VV_FILES
   return;
end

fprintf(1, 'Writing V&V test point %s\n', tpNum);

tpBaseNum = tpNum(1:2); % Just the number

% Generate output filename
filename = [DVBT2.SIM_VV_PATH '/TestPoint' tpBaseNum '/' DVBT2.SIM.VV_CONFIG_NAME '_TP' tpNum '_' DVBT2.SIM.VV_COMPANY_NAME '.txt'];

if ~exist([DVBT2.SIM_VV_PATH '/' 'TestPoint' tpBaseNum], 'dir')
    mkdir(DVBT2.SIM_VV_PATH, ['TestPoint' tpBaseNum]); % ensure directory exists
end

% Open output file
if (startCycle==0) % start of file: re-write
    outfile = fopen(filename, 'w');
else
    outfile = fopen(filename, 'a'); % append
end

numFields = size(data,1); % in

data = [startCycle:startCycle+size(data,2)-1; data];
data = data(:,mod(data(1,:),subsampleFactor)==0);

fprintf(outfile, ['%d' repmat('\t%d',1,numFields) '\n'],round(data));

fclose(outfile);


end