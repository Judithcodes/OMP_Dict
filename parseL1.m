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
%* Description : parseL1 DVBT2 L1 parser
%******************************************************************************
function L1Data = parseL1 (L1postData, FEF, numFrames)

L1PostConfFields1 = {'SUB_SLICES_PER_FRAME','NUM_PLP','NUM_AUX','AUX_CONFIG_RFU'};
L1PostConfFieldsRF = {'RF_IDX','FREQUENCY'};
L1PostConfFieldsFEF = {'FEF_TYPE','FEF_LENGTH','FEF_INTERVAL'};
L1PostConfFieldsPLP = {'PLP_ID','PLP_TYPE','PLP_PAYLOAD_TYPE','FF_FLAG','FIRST_RF_IDX','FIRST_FRAME_IDX','PLP_GROUP_ID', ...
    'PLP_COD','PLP_MOD','PLP_ROTATION','PLP_FEC_TYPE','PLP_NUM_BLOCKS_MAX','FRAME_INTERVAL','TIME_IL_LENGTH','TIME_IL_TYPE', ...
    'IN_BAND_A_FLAG','IN_BAND_B_FLAG','RESERVED_1','PLP_MODE','STATIC_FLAG','STATIC_PADDING_FLAG'};
L1PostConfFields2 = {'RESERVED_2'};
L1PostConfFieldsAUX = {'AUX_RFU'};

L1PostDynFields1 = {'FRAME_IDX', 'SUB_SLICE_INTERVAL','TYPE_2_START','L1_CHANGE_COUNTER','START_RF_IDX','RESERVED_1'};
L1PostDynFieldsPLP = {'PLP_ID','PLP_START','PLP_NUM_BLOCKS','RESERVED_2'};
L1PostDynFields2 = {'RESERVED_3'};
L1PostDynFieldsAUX = {'AUX_RFU'};


    for m=1:numFrames
%         remain = data{i}(m,:);
        %remain = remain(1,:);
        remain = L1postData(m,:);
        fieldNames = [];

        [l1fields, remain] = extractFields(remain, [15 8 4 8]);
        fieldNames = [fieldNames, L1PostConfFields1];
        NUM_RF = 1;
        for rf=1:NUM_RF
            [fields, remain] = extractFields(remain, [3 32]);
            l1fields = [l1fields fields];
            fieldNames = [fieldNames, L1PostConfFieldsRF];
        end

        if (FEF)
            [fields, remain] = extractFields(remain, [4 22 8]);
            l1fields = [l1fields fields];
            fieldNames = [fieldNames, L1PostConfFieldsFEF];

        end

        NUM_PLP=bi2de(l1fields{2}, 'left-msb');

        for plp = 1:NUM_PLP
            [fields, remain] = extractFields(remain, [8 3 5 1 3 8 8 3 3 1 2 10 8 8 1 1 1 11 2 1 1]);
            l1fields = [l1fields fields];
            fieldNames = [fieldNames, L1PostConfFieldsPLP];

        end    

        [fields, remain] = extractFields(remain, 32);
        l1fields = [l1fields fields];
        fieldNames = [fieldNames, L1PostConfFields2];

        NUM_AUX=bi2de(l1fields{3}, 'left-msb');
        for aux = 1:NUM_AUX
            [fields, remain] = extractFields(remain, 32);
            l1fields = [l1fields fields];
            fieldNames = [fieldNames, L1PostConfFieldsAUX];
        end    

        [fields, remain] = extractFields(remain, [8 22 22 8 3 8]);
        l1fields = [l1fields fields];
        fieldNames = [fieldNames, L1PostDynFields1];

        for plp = 1:NUM_PLP
            [fields, remain] = extractFields(remain, [8 22 10 8]);
            l1fields = [l1fields fields];
            fieldNames = [fieldNames, L1PostDynFieldsPLP];
        end

        [fields, remain] = extractFields(remain, 8);
        l1fields = [l1fields fields];
        fieldNames = [fieldNames, L1PostDynFields2];

        for aux = 1:NUM_AUX
            [fields, remain] = extractFields(remain, 48);
            l1fields = [l1fields fields];
            fieldNames = [fieldNames, L1PostDynFieldsAUX];
        end    

        L1Data.l1fields=l1fields;
        for f=1:length(l1fields)
            L1Data.decValues(m,f) = bi2de(l1fields{f}, 'left-msb');
        end
        L1Data.fieldNames = fieldNames;
    end


function [fields, remain] = extractFields(inputBits, fieldLengths)

    remain = inputBits;
    fields = cell(1, length(fieldLengths));
    for i=1:length(fieldLengths)
        len = fieldLengths(i);
        fields{i} = remain(1:len);
        remain(1:len)=[];
    end
