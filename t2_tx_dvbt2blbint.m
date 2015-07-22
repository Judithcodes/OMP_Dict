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
%* Description : T2_TX_DVBT2BLBINT DVBT2 Bit Interleaver
%*               DOUT = T2_TX_DVBT2BLBINT(DVBT2, FID, DIN) interleaves the data 
%*               following the configuration parameters of the DVBT2 structure.
%*               FID specifies the file identifier where any debug message is 
%*               sent.
%******************************************************************************

function DataOut = t2_tx_dvbt2blbint(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_tx_dvbt2blbint SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
NUM_PLPS   = DVBT2.NUM_PLPS; % Number of PLPs
MODE     = DVBT2.MODE;              % DVBT2 mode
SCHED   = DataIn.sched;
%------------------------------------------------------------------------------
% PLP Loop
%------------------------------------------------------------------------------

for plp=1:NUM_PLPS

    %------------------------------------------------------------------------------
    % PLP-specific Parameters Definition
    %------------------------------------------------------------------------------
    CONSTEL  = DVBT2.PLP(plp).CONSTELLATION;     % DVBT2 constellation
    %DCPS     = DVBT2.STANDARD.DC_PS;   % Data carriers per symbol
    V        = DVBT2.STANDARD.PLP(plp).MAP.V;    % Bits per cell
    COD_RATE = DVBT2.STANDARD.PLP(plp).ICOD.CR;
    Q        = DVBT2.STANDARD.PLP(plp).ICOD.Q;   % The q of the code
    S        = DVBT2.STANDARD.PLP(plp).ICOD.S;   % The S of the code
    FECLEN   = DVBT2.PLP(plp).FECLEN;            % The inner fec length
    CRATE    = DVBT2.PLP(plp).CRATE;             % The code rate
    START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME; % First Interleaving Frame to generate
    NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleving Frames to generate (may be zero)
    NBLOCKS = SCHED.NBLOCKS{plp}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame
    NUM_FBLOCK = sum(NBLOCKS); % Total number of FEC blocks to generate

    %------------------------------------------------------------------------------
    % Procedure
    %---------------------------------------
    data = DataIn.data{plp};

    fprintf(FidLogFile,'\t\tMode=%s - %s\n',MODE, CONSTEL);

    nLdpc  = FECLEN  ; % LDPC block size, need to pass this in
    intCol = V      ; % Interleaver columns = Bits per Symbol

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

    numIntlvBlocks = floor(length(data)/nLdpc); % Number of interleaving blocks
    data = data(1:numIntlvBlocks*nLdpc); %clip the length of the input data
    bitIntlvOut = zeros(1,length(data),'single'); %mem preallocation

    if int_type == 0
      %do no interleaving
      bitIntlvOut = data;
    elseif int_type == 1
      %make the RAI column twistinterleaving table
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

      %this is the type A interleaver
      for it=1:numIntlvBlocks
        % Write in columns
        bitIntlvWr = data((it-1)*nLdpc+1:it*nLdpc);

        %  Read in rows
        bitIntlvRd = bitIntlvWr(table);

        % LDPC block append
        bitIntlvOut((it-1)*nLdpc+1:it*nLdpc) = bitIntlvRd;
      end

    elseif  int_type == 2
      %the type B interleaver

      pLdpc = round(nLdpc * (1 - COD_RATE));
      %  kLdpc = round(nLdpc * COD_RATE);
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

      intered_parity = zeros(1, pLdpc);

      for it=1:numIntlvBlocks
        %pick off the parity bits
        parity = data( (it * nLdpc) - pLdpc + 1:it * nLdpc);

        %interleave the parity bits
        intered_parity(parity_table) = parity;

        %tack on the parity bits and interleave the whole lot
        bitIntlvWr = [data((it-1)*nLdpc+1:it* nLdpc - pLdpc) intered_parity];

        % Write a V&V test point for h/w testing
        % write_vv_test_point(bitIntlvWr, nLdpc, 1, vv_fname('07b', plp, DVBT2), 'bit', DVBT2, 1+floor((it-1)/NBLOCKS), 1+mod(it-1,NBLOCKS));

        %interleave the code word
        if ~parity_only; bitIntlvWr = bitIntlvWr(code_table); end

        % LDPC block append
        bitIntlvOut((it-1)*nLdpc+1:it*nLdpc) = bitIntlvWr;
      end

    end %if int_type == 1

    % Write V&V point
    write_vv_test_point(bitIntlvOut, nLdpc, NBLOCKS, vv_fname('07a',plp,DVBT2), 'bit', DVBT2, 1, DVBT2.START_T2_FRAME+1)

    fprintf(FidLogFile,'\t\tBit interleaver: %d interleaving blocks\n',... 
            numIntlvBlocks);

        DataOut.data{plp} = bitIntlvOut;
end

DataOut.sched = SCHED;
DataOut.l1 = DataIn.l1;