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
%* Description : 
%*               
%******************************************************************************

function write_vv_test_point(data, blockLen, blocksPerFrameIn, tpNum, tpFormat, DVBT2, startBlock, startFrame)

if ~DVBT2.SIM.EN_VV_FILES && ~(~isempty(strfind(tpNum,'19')) && DVBT2.SIM.EN_VV_FILE_TP19)
    return;
end

if (nargin == 6)
    startBlock = 1;
    startFrame = 1;
end

tpBaseNum = tpNum(1:2); % Just the number

if strcmp (tpBaseNum, '19')
    if startFrame < DVBT2.STANDARD.OUTPUT_START_FRAME
        return % Mute output when needed because of compensating delays
    end
    startFile = (startBlock==1 && startFrame == DVBT2.STANDARD.OUTPUT_START_FRAME);
else
    startFile = (startBlock==1 && startFrame==1);
end

fprintf(1, 'Writing V&V test point %s\n', tpNum);

% Generate output filename
filename = [DVBT2.SIM_VV_PATH '/TestPoint' tpBaseNum '/' DVBT2.SIM.VV_CONFIG_NAME '_TP' tpNum '_' DVBT2.SIM.VV_COMPANY_NAME '.txt'];

if ~exist([DVBT2.SIM_VV_PATH '/' 'TestPoint' tpBaseNum], 'dir')
    mkdir(DVBT2.SIM_VV_PATH, ['TestPoint' tpBaseNum]); % ensure directory exists
end

% Open output file
if startFile % start of file: re-write
    outfile = fopen(filename, 'w');
else
    outfile = fopen(filename, 'a'); % append
end

%outfile = 1;

% Reshape data into one long vector
data = reshape(data, [], 1);

% Reshape data so dimensions are items, blocks, frames

inputSize = length(data(:));

printFrames = 1;
printBlocks = 1;



if length(blocksPerFrameIn)>1 % there's a vector of numbers of blocks, one for each frame
    numFrames = length(blocksPerFrameIn);
    blocksPerFrame = blocksPerFrameIn;
    if length(blockLen)==1
        blockLen(1:numFrames) = blockLen; % same block length in each frame
    end
    
elseif length(blockLen)>1 % there's a vector of block lengths, one for each frame
    numFrames = length(blockLen);
    if blocksPerFrameIn == 0 % Usual case - there are no blocks, and each block is a whole frame (e.g. TINT output)
        blocksPerFrame(1:numFrames) = 1;
        printBlocks = 0; % Don't print #block lines
    else
        blocksPerFrame(1:numFrames) = blocksPerFrameIn;
    end
elseif isempty(blockLen) % was a vector of block lengths, but is empty
    numFrames = 0;
    blocksPerFrame = 0;
    printFrames = 0;
    printBlocks = 0;
elseif isempty(blocksPerFrameIn) % it was a vector, but it's empty as there are no frames
    numFrames = 0;
    blocksPerFrame = 0;
    printFrames = 0;
    printBlocks = 0;
elseif isinf(blocksPerFrameIn) % This means there are no frames
    numFrames = 1;
    blocksPerFrame = ceil(inputSize/blockLen);    
    printFrames = 0; % don't print #frame lines

elseif blocksPerFrameIn == 0 % This means there are no blocks
    numFrames = ceil(inputSize/blockLen);
    blocksPerFrame(1:numFrames) = 1;
    blockLen(1:numFrames) = blockLen;
    printBlocks = 0; % Don't print #block lines 
else
    numFrames = ceil(inputSize/(blockLen*blocksPerFrameIn));
    blocksPerFrame(1:numFrames) = blocksPerFrameIn;
    blockLen(1:numFrames) = blockLen;
end

data(inputSize+1: blocksPerFrame * blockLen') = NaN; % Pad with NaNs to avoid reshape crashing

switch tpFormat
    case 'byte'
        itemsPerLine = 32;
        formatString = '%02X';
    case 'bit'
        itemsPerLine = 64;
        formatString = '%1d';
    case 'complex'
        itemsPerLine = 1;
        formatString = '%+e %+e';
end

if startFile
    c=clock;
    fprintf(outfile, '%% DVB-T2 verification & validation working group\n');
    fprintf(outfile, '%% Modulator reference stream file\n');
    fprintf(outfile, '%%\n');
    fprintf(outfile, '%% Created by the Common Simulation Platform (https://corben.us.es)\n');
    fprintf(outfile, '%%\n');
    fprintf(outfile, '%% Notification to Recipient\n');
    fprintf(outfile, '%%\n');
    fprintf(outfile, '%% This data is copyright (c) Digital Video Broadcasting Project (DVB) %04d\n', c(1));
    fprintf(outfile, '%% Distribution of this data is permitted but only in unmodified form,\n');
    fprintf(outfile, '%% unless prior written permission has been obtained from DVB.\n');
    fprintf(outfile, '%% At the date of creation of this data, DVB believe this data to be accurate \n');
    fprintf(outfile, '%% (according to the DVBT2 standard) and that it does not infringe third party rights,\n');
    fprintf(outfile, '%% however DVB do not provide any warranties or guarantees in this respect.\n');
    fprintf(outfile, '%% Any other warranties are excluded to the fullest extent permitted in law.\n');
    fprintf(outfile, '%% The manner in which this data is used is entirely at the election of the user.\n');
    fprintf(outfile, '%%\n');
    fprintf(outfile, '%% DVB Project website: www.dvb.org\n');
    fprintf(outfile, '%%\n');
    fprintf(outfile, '%% Test point %s (%s data)\n', tpNum, tpFormat);
    fprintf(outfile, '%%\n');
    fprintf(outfile, '%% Generated on %04d-%02d-%02d %02d:%02d\n', c(1:5));
    fprintf(outfile, '%%\n');
end

pos = 1;
for frameNum = 1:numFrames
    if printFrames && (startBlock == 1 || frameNum > 1) % Only print frame if there are frames
        fprintf(outfile, '# frame %d \n', frameNum + startFrame - 1);
    end
    
    for blockNum = 1:blocksPerFrame(frameNum)
        if printBlocks % Only print block if there are blocks
            fprintf(outfile, '# block %d of %d\n', blockNum + startBlock - 1, blocksPerFrame(frameNum));
        end
        
        % extract the block for pre-processing
        block = data(pos:pos+blockLen(frameNum)-1);
        pos = pos + blockLen(frameNum);
        
        % Expunge NaNs (used for variable length blocks e.g. P2/NormalFC symbols)
        block = block(~isnan(block));
        
        % Split complex into Real/Imag
        if (strcmp(tpFormat, 'complex'))
            block = [real(block) imag(block)].';
            block = reshape(block,[],1);
        end
        
        if blockLen(frameNum)==0
            % Don't try to print it
        elseif (itemsPerLine == 1)
            fprintf(outfile, [formatString '\n'], block);
        else
            itemNum=1;
            for lineNum = 1:floor(size(block, 1)/itemsPerLine) % complete lines
                fprintf(outfile, formatString, block(itemNum:itemNum+itemsPerLine-1,:));
                fprintf(outfile, '\n');
                itemNum = itemNum+itemsPerLine;
            end
            if (itemNum<=size(block,1)) % shorter last line
                fprintf(outfile, formatString, block(itemNum:end, :));
                fprintf(outfile, '\n');
            end
        end
        
    end    

end

fclose(outfile);
end
