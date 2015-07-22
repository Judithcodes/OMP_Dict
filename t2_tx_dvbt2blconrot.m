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
%* Description : T2_TX_DVBT2BLCONROT DVBT2 Rotated constellations.
%*               DOUT = T2_TX_DVBT2BLCONROT(DVBT2, FID, DIN) rotates the incoming
%*               cells by specified amount and performs cyclic shift of Q(imag).
%*               FID specifies the file identifier where any debug message is 
%*               sent.
%*               NOTE: This part of the baseline specification is still under discussion
%******************************************************************************

function DataOut = t2_tx_dvbt2blconrot(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
  otherwise,
    error('t2_tx_dvbt2blconrot SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
NUM_PLPS   = DVBT2.NUM_PLPS; % Number of PLPs

EN_PAUSES    = DVBT2.SIM.EN_PAUSES;       % Pause enable
EN_FIGS      = DVBT2.SIM.EN_FIGS;         % Figure enable
SAVE_FIGS    = DVBT2.SIM.SAVE_FIGS;       % Enable figure saving
SIM_DIR      = DVBT2.SIM.SIMDIR;          % Saving directory
CLOSE_FIGS   = DVBT2.SIM.CLOSE_FIGS;      % Close figure after plotting

EN_CONST_A   = DVBT2.TX.CONROT.EN_CONST_A;   % Enable post-rotation constellation plot
CONSTA_FNAME = DVBT2.TX.CONROT.CONSTA_FNAME; % Figure file name if saved

SCHED = DataIn.sched;
%------------------------------------------------------------------------------
% PLP Loop
%------------------------------------------------------------------------------

for plp=1:NUM_PLPS

    %------------------------------------------------------------------------------
    % PLP-specific Parameters Definition
    %------------------------------------------------------------------------------
    CONSTEL  = DVBT2.PLP(plp).CONSTELLATION;     % DVBT2 constellation
    FECLEN_BITS   = DVBT2.PLP(plp).FECLEN;            % The inner fec length
    START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME; % First Interleaving Frame to generate
    NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleaving Frames to generate (may be zero)
    NBLOCKS = SCHED.NBLOCKS{plp}(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame
    BITS_PER_CELL = DVBT2.STANDARD.PLP(plp).MAP.V; % constellation order
    CELLS_PER_FEC_BLOCK = FECLEN_BITS / BITS_PER_CELL;

    BYPASS       = DVBT2.PLP(plp).ROTCON_BYPASS;          % Bypass rotation

    %------------------------------------------------------------------------------
    % Procedure
    %------------------------------------------------------------------------------

    switch CONSTEL
      case 'QPSK'
          ROTATION_ANGLE_DEGREES = 29.0;
      case '16-QAM'
          ROTATION_ANGLE_DEGREES = 16.8;
      case '64-QAM'
          ROTATION_ANGLE_DEGREES = 8.6;
      case '256-QAM'
          ROTATION_ANGLE_DEGREES = atand(1/16);
    end

    if (BYPASS == 0)
      data = DataIn.data{plp};
      % truncate DataIn to a multiple of CELLS_PER_FEC_BLOCK
      num_fec_blocks = floor(length(data)/CELLS_PER_FEC_BLOCK);
      data = data(1:CELLS_PER_FEC_BLOCK * num_fec_blocks);

      ROTATION_ANGLE_RADIANS = 2*pi*ROTATION_ANGLE_DEGREES/360;
      rotation = cos(ROTATION_ANGLE_RADIANS) + j * sin (ROTATION_ANGLE_RADIANS);

      %convert to 2 lots of 2^V PAM, u1 and u2
      u1 = real(data*rotation);
      u2 = imag(data*rotation);

      % Write V&V test point
      write_vv_test_point(u1+j*u2, CELLS_PER_FEC_BLOCK, NBLOCKS, vv_fname('08',plp,DVBT2), 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1) % really it's 8

      %shift of DataIn below means that u1 is independent of u2 so that all
      %points on the new 2^V x 2^V constellation are be populated

      u2 = reshape(u2, CELLS_PER_FEC_BLOCK, []);
      u2 = u2([end 1:(end-1)], :);

      % turn back into a row;
      u2 = reshape(u2, 1, []);

      % map u1 and shifted u2 onto I & Q axes respectively
      data = u1 + j * u2;

      % Write V&V test point
      write_vv_test_point(data, CELLS_PER_FEC_BLOCK, NBLOCKS, vv_fname('09',plp,DVBT2), 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)

      fprintf(FidLogFile,'\t\tConstellation rotation: %f degrees rotation angle\n',... 
              ROTATION_ANGLE_DEGREES);

      % plot rotated constellation
      if EN_FIGS && EN_CONST_A
        figure;
        plot(data, 'o')
        title('Constellation after rotation, generation of u1 & u2 and cyclic u2 shift');
        grid;

        if SAVE_FIGS
          fName = sprintf('%s%s', SIM_DIR, CONSTA_FNAME);
          hgsave(fName);
        end

        if EN_PAUSES
          pause;
        end

        if CLOSE_FIGS
          close;
        end
      end
    else
      fprintf(FidLogFile,'\t\tConstellation rotation: bypassed\n');
      data = DataIn.data{plp};
    end
    %------------------------------------------------------------------------------
    % Output formatting
    %------------------------------------------------------------------------------
    DataOut.data{plp} = data;
end
DataOut.sched = SCHED;
DataOut.l1 = DataIn.l1;