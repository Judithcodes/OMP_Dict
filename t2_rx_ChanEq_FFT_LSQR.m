function [xEq] = t2_rx_ChanEq_FFT_LSQR(yT,DataLoc,BEM_Cf,BEM_seq,iter_num)

switch(nargin)
  case 5,
  otherwise,
    error('t2_rx_construct_OP_Matrix SYNTAX');
end

%%%     Copyright: (c) Guoping TAN, 2014-2014
%%%
%%%     Adopt fast FFT based LSQR algoritym for equalizing the data symbols using only BEM model coefficiets 
%%%
%%%%%%%%%%%%%%%%%%%
%%%
%%%     Output:
%%%
%%%     xEq        ...   the eqlized data symbols with the position of DataLoc 
%%%
%%%     Input:
%%%
%%%     yT         ...   Time-domain symbols after removing CP 
%%%     DataLoc    ...   The positions of data symbols in subcarriers 
%%%     BEM_Cf     ...   the BEM model coefficeints with I*M matrix, where
%%%                      'I' is the order of BEM model, and 'M' is the number of taps
%%%     BEM_seq    ...   the sequence of BEM model with I*K matrix, where
%%%                      'K' is the nubmer of subcarriers
%%%     iter_num   ...   the maximum number of iterations with LSQR algorithm
%%%
%%%     we implement: 
%%%        The FFT based LSQR algorithm, which is divided into two steps:
%%%        step 1. Golub-Kahan bidiagonalization
%%%        step 2. Solving the bidiagonal least square problem using QR factorization 
%%%     The detail information on this LSQR based equalization algorithm
%%%     can be found in pp.5717 of the paper 'Low Complexity Equalization for Doubly 
%%%     Selective Channels Modeled by a Basis Expansion' writen by 
%%%     T. Hrycak et al.
%%%

Data_Len=length(DataLoc);
xEq=zeros(Data_Len,1);
K=length(yT);          %% 'K' is the number of subcarriers
yT=yT.';

[I M]=size(BEM_Cf);    %% 'I' is the order of BEM model, and 'M' is the number of taps
C=zeros(I,K);
for i=1:I
    C(i,:)=fft(BEM_Cf(i,:),K);  %% obtain the diagonal elements
end

%%% Using fast FFT for the LSQR algorithm, never construct the time domain
%%% H explicitly

%%% Same to left multiply R=sum(W'*C[i]'*W*B[i]'*yT)=H'*yT, which can be caculated by fast FFT and IFFT 

%%% intialization

R=zeros(K,1);  %% used for recording the values for the first iteration 

beta=norm(yT,2);
U = yT./beta;

for i=1:I
    R1=(BEM_seq(i,:)').*U;
    R2=fft(R1,K)/sqrt(K);
    R3=(C(i,:)').*R2;
    R4=ifft(R3,K)*sqrt(K);
    R=R+R4; 
end

alpha=norm(R,2);
V = R./alpha;
phi_=beta;
luo_=alpha;
W = V;
Rx=zeros(K,1);

%%% Iteration algorithm

for iter=1:1:iter_num
    %%% Same to left multiply R_=sum(B[i]*W'*C[i]*W*R)=H*R, which can be calculated by
    %%% fast FFT and IFFT
    R_=zeros(K,1); %%
    for i=1:I
        R1_=fft(V,K)/sqrt(K);
        R2_=(C(i,:).').*R1_;
        R3_=ifft(R2_,K)*sqrt(K);
        R4_=(BEM_seq(i,:).').*R3_;
        R_=R_+R4_; %% '*pinv(diag(C(1,:)))' only for precondition
    end
    beta_update=norm(R_-alpha*U,2);
    U_update = (R_-alpha.*U)./beta_update;
    beta=beta_update;
    U = U_update;
 
    %%% Same to left multiply R=sum(W'*C[i]'*W*B[i]'*R_)=H'*R_, which can be caculated by fast FFT and IFFT 
    R=zeros(K,1);
    for i=1:I
        R1=(BEM_seq(i,:)').*U;
        R2=fft(R1,K)/sqrt(K);
        R3=(C(i,:)').*R2;
        R4=ifft(R3,K)*sqrt(K);
        R=R+R4; %% '*pinv(diag(C(1,:)))' only for precondition
    end

    %%% update the values for this iteration
   
    alpha_update=norm(R-beta*V,2);
    V_update = (R-beta*V)./alpha_update;

    %%% save for the next iteration
    alpha=alpha_update;
    V = V_update;
    
    %%% Solving the LS problem using the simple iterations as proposed in
    %%% the paper 'LSQR: '
    
    luo=sqrt((luo_^2+beta^2));
    xi=luo_/luo;
    s=beta/luo;
    theta=s*alpha;
    phi=xi*phi_;
    
    %%% update luo_ and phi_
    luo_=-1*xi*alpha;
    phi_=s*phi_;
    
    %%% update Rx and W
    Rx=Rx+(phi/luo)*W;
    W=V-(theta/luo)*W;
end    

%demodX=fft(Rx,K)/sqrt(K);                  %% 'pinv(diag(C(1,:)))*' only for precondition
%xEq=demodX(DataLoc);
xEq=Rx;


