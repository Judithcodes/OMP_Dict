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
%* Description : T2_RX_DVBT2BLBDINT DVBS2 Bit De-Interleaver.
%*               DATAOUT = T2_RX_DVBT2BLBDINT(DVBT2, FID, DATAIN) de-interleaves 
%*               DATAIN following the configuration parameters of the DVBS2
%*               structure and stores the result in DATAOUT. FID specifies
%*               the file identifier where any debug message is sent.
%******************************************************************************

function DataOut = t2_rx_dvbt2blbdint(DVBT2, FidLogFile, DataIn)


%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_rx_dvbt2blbdint SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
PLP = DVBT2.RX_PLP; % PLP to decode in the receiver

MODE     = DVBT2.MODE;            % DVBT mode
CONSTEL  = DVBT2.PLP(PLP).CONSTELLATION;   % DVBT constellation
V        = DVBT2.STANDARD.PLP(PLP).MAP.V; % Bit per carrier
COD_RATE = DVBT2.STANDARD.PLP(PLP).ICOD.CR;
Q        = DVBT2.STANDARD.PLP(PLP).ICOD.Q; %the Q of the code
S        = DVBT2.STANDARD.PLP(PLP).ICOD.S; %the S of the code
FECLEN   = DVBT2.PLP(PLP).FECLEN;            %the size of the inner code   
CRATE    = DVBT2.PLP(PLP).CRATE;             % The code rate
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------
  
fprintf(FidLogFile,'\t\tMode=%s - %s\n', MODE, CONSTEL);
          
nLdpc  = FECLEN; % LDPC block size pass this in
bps    = V;     % Bits per Symbol
%intCol = bps;   % Interleaver columns
 
% Bit-wise de-interleaver     
dataSerial       = DataIn; 
%numDeintlvBlocks = floor(length(dataSerial)/nLdpc); % Number of interleaving blocks

%bitDeintlvOut = zeros(1,numDeintlvBlocks*nLdpc); %mem preallocation

%decide the type of interleaving, A or B
%   This appears to be old functionality which I believe only applied to pre-spec versions. CRN 2011-09-05.    
%     if COD_RATE < 1/2
%       %type A
%       int_type = 1;
%     else
%       %type B
%       int_type = 2;
%     end
    int_type = 2;
    parity_only = false;


Nc = V;

Nc = Nc * int_type;

switch nLdpc
    case 64800
        switch CONSTEL
            case 'QPSK'
                int_type = 0;
            case '16-QAM'
                Tc = [0	0	2	4	4	5	7	7];
            case '64-QAM'
                Tc = [0	0	2	2	3	4	4	5	5	7	8	9];
            case '256-QAM'
                Tc = [0	2	2	2	2	3	7	15	16	20	22	22	27	27	28	32];
        end
    case 16200
        switch CONSTEL
            case 'QPSK'
                if strcmp(CRATE,'1/3') || strcmp(CRATE,'2/5') % T2-Lite
                    parity_only = true;
                else
                    int_type = 0;
                end                
            case '16-QAM'
                Tc = [0	0	0	1	7	20	20	21];
            case '64-QAM'
                Tc = [0	0	0	2	2	2	3	3	3	6	7	7];
            case '256-QAM'
                Tc = [0	0	0	1	7	20	20	21];
                %there is an exception here for shoft blocks and 256qam
                Nc = Nc / 2;
        end
end

Nr = nLdpc / Nc;
numDeintlvBlocks = floor(length(dataSerial)/nLdpc); % Number of interleaving blocks
dataSerial = dataSerial(1:numDeintlvBlocks*nLdpc); %clip the length of the input data
bitDeintlvOut = zeros(1,length(dataSerial)); %mem preallocation


if int_type == 0
    bitDeintlvOut = dataSerial;
elseif int_type == 1
    %make the RAI column twist interleaving table
    %ll = 0:nLdpc-1;
    ll = 1:nLdpc;

   
    first = reshape(ll, Nr, Nc);

    cols = 0:Nc-1;

    table = zeros(1,nLdpc);

    for row = 0 : Nr-1

        idx = Nc  - 1 - floor(cols / Nc) - cols;

        idx = mod(idx, Nc) + 1;

        table(1 + row * Nc:Nc + row * Nc) = first(row + 1,idx);

        cols = cols + Nc;
    end

    % Bit-wise interleaver

    bitIntlvRd  = zeros(1, nLdpc);

    %this is the type A deinterleaver
    for it=1:numDeintlvBlocks
        % Write in columns
        bitIntlvWr = dataSerial((it-1)*nLdpc+1:it*nLdpc);

        %  Read in rows
        bitIntlvRd(table) = bitIntlvWr;

        % LDPC block append
        bitDeintlvOut((it-1)*nLdpc+1:it*nLdpc) = bitIntlvRd;
    end



elseif  int_type == 2
    %the type B deinterleaver

    pLdpc = round(nLdpc * (1 - COD_RATE));
    kLdpc = round(nLdpc * COD_RATE);
%    code_parallelism = 360;
%    q = 60; %need to pass this in

    %make the parity interleaving table
    parity_table = zeros(1,pLdpc);

    count = 1;
    for scount = 0:S-1
        for t = 0:Q-1

            %        table(params.q * s + t + 1) = params.pldpc * t + s + 1;
            %     val = params.range * t + s + 1;
            parity_table(count) = S * t + scount + 1;
            count = count + 1;
        end
    end

    %make the Sony interleaving table
if ~parity_only;    
    code_table = zeros(Nc, Nr);


    for cols = 1:Nc
        tc = Tc(cols);
        rw = (0:Nr-1)  -  tc;
        rwm = mod(rw, Nr) + 1;
        rwm = rwm + (cols - 1) * Nr;

        code_table(cols, :) = rwm;
    end

    code_table = reshape(code_table, Nr, []);% + 1;
    code_table = reshape(code_table, nLdpc, []);% + 1;
end
    
%    code_bits = zeros(1, nLdpc);

    for it=1:numDeintlvBlocks
        
        code_bits = dataSerial((it-1)*nLdpc+1:it*nLdpc);

        %deinterleave the code word - if not parity only
        if ~parity_only; bitIntlvWr(code_table) = code_bits; else bitIntlvWr = code_bits; end;
        
        %pick off the parity bits
        parity = bitIntlvWr(kLdpc + 1:end);
        
        %deinteleave the parity bits
        intered_parity = parity(parity_table);
        
        %put the parity bits back onto the code word
        bitIntlvWr = [bitIntlvWr(1:kLdpc) intered_parity];

        % LDPC block append
        bitDeintlvOut((it-1)*nLdpc+1:it*nLdpc) = bitIntlvWr;
    end

end%if int_type == 0

fprintf(FidLogFile,'\t\tBit-wise de-interlv: %d interleaving blocks\n',... 
        numDeintlvBlocks);

% Only Non hierarchical      
DataOut = bitDeintlvOut;
