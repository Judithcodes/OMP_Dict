function [T BEM_seq] = t2_rx_construct_OP_Matrix(DVBT2, FidLogFile, D,I,K,Type)
%%%     Copyright: (c) Guoping TAN, 2014-2014
%%%
%%%    Construct Orthogonal Projection (OP) matrix and caculate the BEM
%%%    sequences
%%%
%%%%%%%%%%%%%%%%%%%
%%%
%%%     Output:
%%%
%%%     T         ...   the OP matrix of I*D for computing B from D Fourier coeeficients 
%%%     BEM_seq   ...   the BEM model sequences 
%%%
%%%     Input:
%%%
%%%     D         ...   the number of Fourier coeeficients
%%%     I         ...   the order of the BEM model     
%%%     K         ...   the number of subcarriers 
%%%     Type      ...   the Basis function type, 'LP' or 'PF', can be developed later... 
%%%
%%%     we implement: 
%%%      T(i,d)=j.^i*(2*i+1)*(-1).^d*BesselJ(i,pi*d)       
%%%     where i=0,1,..I-1, d=D-,...,D+
%%%
%------------------------------------------------------------------------------
switch(nargin)
  case 6,
  otherwise,
    error('t2_rx_construct_OP_Matrix SYNTAX');
end
%------------------------------------------------------------------------------
j=sqrt(-1);
T = zeros(I,D);
Dmin=-1*floor((D-1)/2);
Dmax=floor(D/2);
Dv=[Dmin:Dmax];
BEM_seq=zeros(I,K);

n=[0:1:K-1];
t=(2.*n)./K-1;

if Type == 'LP'
    for i=1:I
        BEM_seq(i,:)=mfun('P',i-1,t);             %% compute the LP sequences
        cf=((-1).^Dv)*(j.^(i-1))*(2*(i-1)+1);
        T(i,:)=cf.*t2_rx_sphbesselj(DVBT2, FidLogFile,(i-1),Dv*pi);      %% compute the LP OP matrix
    end
    %BEM_seq.'
elseif Type == 'PF'
    disp('To do ...');
    return;
else
    disp('The type must be LP or PWSF!!');
    return;
end


