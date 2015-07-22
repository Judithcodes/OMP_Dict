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
%* Description : T2_RX_DVBT2BLFREQDINT_SPERMAT DVBT Freq-Interleaver Symbol
%*               Permutation Matrices.
%*               [H, HINV] = T2_RX_DVBT2BLFREQDINT_SPERMAT(DVBT2) returns the symbol
%*               freq-interleaver permutation matrix H, and in inverse HINV
%*               following the configuration parameters of the DVBT2
%*               structure.
%******************************************************************************

function [HEven, HOdd, HEvenP2, HOddP2, HEvenFC, HOddFC]=t2_rx_dvbt2blfreqdint_spermat(DVBT2)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
  otherwise,
    error('t2_rx_dvbt2blfreqdint_spermat SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
MODE    = DVBT2.MODE;           % DVBT2 mode
C_DATA  = DVBT2.STANDARD.C_DATA; % Data carriers per symbol
C_P2	= DVBT2.STANDARD.C_P2; % Data carriers in P2 symbols
N_FC	= DVBT2.STANDARD.N_FC; % Data carriers in frame closing symbols
NFFT    = DVBT2.STANDARD.NFFT;  % Carriers per symbol

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

% Interleaver permutation matrix
switch  MODE
  case '1k'     
    mMax=NFFT; nR=log2(mMax); nMax=C_DATA;
      
    % R_prime matrix definition
    rP = zeros(mMax,nR-1);
    rP(3,1) = 1;
      
    for k=3:mMax-1
      rP(k+1,(0:1:nR-3)+1) = rP(k,(1:1:nR-2)+1); % Shift LFSR
      rP(k+1,8+1) = xor(rP(k,1),rP(k,5));        % xor bit 4 and bit 0
    end

    % R = R_prime permutation
    rEven = zeros(mMax,nR-1);
    rOdd = zeros(mMax,nR-1);

    permutationRP = [8 7 6 5 4 3 2 1 0];
        permutationREven  = [4 3 2 1 0 5 6 7 8];
        permutationROdd   = [3 2 5 0 1 4 7 8 6];
      
    rEven(:,permutationREven+1) = rP(:,permutationRP+1);    
    rOdd(:,permutationROdd+1) = rP(:,permutationRP+1);    

  case '2k'     
    mMax=NFFT; nR=log2(mMax); nMax=C_DATA;
      
    % R_prime matrix definition
    rP = zeros(mMax,nR-1);
    rP(3,1) = 1;
      
    for k=3:mMax-1
      rP(k+1,(0:1:nR-3)+1) = rP(k,(1:1:nR-2)+1); % Shift LFSR
      rP(k+1,9+1) = xor(rP(k,1),rP(k,4));        % xor bit 3 and bit 0
    end

    % R = R_prime permutation
    r = zeros(mMax,nR-1);

    permutationRP = [9 8 7 6 5 4 3 2 1 0];
        permutationREven  = [0 7 5 1 8 2 6 9 3 4];
        permutationROdd  = [3 2 7 0 1 5 8 4 9 6];
      
    rEven(:,permutationREven+1) = rP(:,permutationRP+1);    
    rOdd(:,permutationROdd+1) = rP(:,permutationRP+1);    

  case '4k'
    mMax = NFFT; nR=log2(mMax); nMax=C_DATA;
      
    % R_prime matrix definition
    rP = zeros(mMax,nR-1);
    rP(3,1) = 1;
      
    for k=3:mMax-1
      rP(k+1,(0:1:nR-3)+1) = rP(k,(1:1:nR-2)+1); % Shift LFSR
      rP(k+1,10+1) = xor(rP(k,1),rP(k,3));       % xor bit 2 and bit 0
    end
      
    % R = R_prime permutation
    r = zeros(mMax,nR-1);
      
    permutationRP = [10 9 8 7 6 5 4 3 2 1 0];
        permutationREven  = [7 10 5 8 1 2 4 9 0 3 6];
        permutationROdd  = [6 2 7 10 8 0 3 4 1 9 5];
      
    rEven(:,permutationREven+1) = rP(:,permutationRP+1);    
    rOdd(:,permutationROdd+1) = rP(:,permutationRP+1);    
       
  case '8k'
    mMax=NFFT; nR=log2(mMax); nMax=C_DATA;
    
    % R_prime matrix definition
    rP=zeros(mMax,nR-1);
    rP(3,1)=1;
    
    for k=3:mMax-1
      rP(k+1,(0:1:nR-3)+1) = rP(k,(1:1:nR-2)+1); %Shift LFSR
      
      alfa = xor(rP(k,1),rP(k,2));              %xor bit 0 and bit 1
      beta = xor(rP(k,5),rP(k,7));              %xor bit 4 and bit 6
      rP(k+1,12) = xor(alfa,beta);
    end
    
    % R = R prime permutation
    r=zeros(mMax,nR-1);
    
    permutationRP = [11 10 9 8  7 6 5 4 3 2 1 0];
    permutationREven  = [ 5 11 3 0 10 8 6 9 2 4 1 7];
    permutationROdd  = [ 8 10 7 6 0 5 2 1 3 9 4 11];
    
    rEven(:,permutationREven+1) = rP(:,permutationRP+1);    
    rOdd(:,permutationROdd+1) = rP(:,permutationRP+1);    

    
  case '16k'
    mMax=NFFT; nR=log2(mMax); nMax=C_DATA;
    
    % R_prime matrix definition
    rP=zeros(mMax,nR-1);
    rP(3,1)=1;
    
    for k=3:mMax-1
      rP(k+1,(0:1:nR-3)+1) = rP(k,(1:1:nR-2)+1); %Shift LFSR
      
      alfa  = xor(rP(k,1),rP(k,2));              %xor bit 0 and bit 1
      beta  = xor(rP(k,5),rP(k,6));              %xor bit 4 and bit 5
      gamma = xor(rP(k,10),rP(k,12));            %xor bit 9 and bit 11
      rP(k+1,13) = xor(xor(alfa,beta), gamma);
    end
    
    % R = R prime permutation
    r=zeros(mMax,nR-1);
    
    permutationRP = [12 11 10 9 8 7  6  5  4 3 2 1 0];
    permutationREven  = [ 8 4 3 2 0 11 1 5 12 10 6 7 9 ];
    permutationROdd  = [ 7 9 5 3 11 1 4 0 2 12 10 8 6 ];
    
    rEven(:,permutationREven+1) = rP(:,permutationRP+1);    
    rOdd(:,permutationROdd+1) = rP(:,permutationRP+1);    

  case '32k'
    mMax=NFFT; nR=log2(mMax); nMax=C_DATA;
    
    % R_prime matrix definition
    rP=zeros(mMax,nR-1);
    rP(3,1)=1;
    
    for k=3:mMax-1
      rP(k+1,(0:1:nR-3)+1) = rP(k,(1:1:nR-2)+1); %Shift LFSR
      
      alfa = xor(rP(k,1),rP(k,2));             %xor bit 0 and bit 1
      beta = xor(rP(k,3),rP(k,13));            %xor bit 2 and bit 12
      rP(k+1,14) = xor(alfa,beta);
    end
    
    % R = R prime permutation
    r=zeros(mMax,nR-1);
    
    permutationRP = [13 12 11 10  9  8 7  6  5 4 3 2 1  0];
    permutationR  = [ 6  5  0 10  8  1 11 12 2 9 4 3 13 7];
    
    r(:,permutationR+1)= rP(:,permutationRP+1);
    
  otherwise, error('t2_tx_dvbt2blfreqdint_spermat UNKNOWN MODE');
end    

% Permutation matrix generation (H(q))

k=(0:mMax-1)';

if (strcmp(MODE,'32k'))
	HOdd = [r mod(k,2)] * 2.^(0:1:(nR-1))';
    HOddP2 = HOdd(HOdd<C_P2)';
    HOddFC = HOdd(HOdd<N_FC)';
	HOdd = HOdd(HOdd<nMax)'; % Drop the numbers >= nMax

	% Even symbols use the inverse mapping (Hinv)
	HEven=zeros(size(HOdd));
	HEven(HOdd+1)=(0:1:(length(HOdd)-1));

    HEvenP2=zeros(size(HOddP2));
	HEvenP2(HOddP2+1)=(0:1:(length(HOddP2)-1));

    HEvenFC=zeros(size(HOddFC));
	HEvenFC(HOddFC+1)=(0:1:(length(HOddFC)-1));

else
	HEven = [rEven mod(k,2)] * 2.^(0:1:(nR-1))';
    HEvenP2 = HEven(HEven<C_P2)';
    HEvenFC = HEven(HEven<N_FC)';
	HEven = HEven(HEven<nMax)'; % Drop the numbers >= nMax

    HOdd = [rOdd mod(k,2)] * 2.^(0:1:(nR-1))';
    HOddP2 = HOdd(HOdd<C_P2)';
    HOddFC = HOdd(HOdd<N_FC)';
	HOdd = HOdd(HOdd<nMax)'; % Drop the numbers >= nMax

end
