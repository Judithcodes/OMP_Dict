function DataOut = t2_rx_dvbt2blofdm(DVBT2, FidLogFile, DataIn, Fd)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 4,
  otherwise,
    error('t2_rx_dvbt2blofdm SYNTAX');
end
%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
MODE     = DVBT2.MODE;           % DVBT mode
C_LOC    = DVBT2.STANDARD.C_LOC; % Carriers location
NFFT     = DVBT2.STANDARD.NFFT;  % FFT number of points
TU         = DVBT2.STANDARD.TU;     % Length in s of the OFDM symbol data part
L_F         = DVBT2.STANDARD.L_F;       % Symbols per frame
SP_PATTLEN  = DVBT2.STANDARD.SP_PATTLEN; % Scattered pilots pattern length
SP_LOC      = DVBT2.STANDARD.SP_LOC;     % Scattared pilots locations
EDGE_LOC    = DVBT2.STANDARD.EDGE_LOC;   % Edge pilots locations
SP_FNAME   = DVBT2.RX.SP_FDO;      % SP file

SIM_DIR      = DVBT2.SIM.SIMDIR;          % Saving directory
MISO_ENABLED = DVBT2.MISO_ENABLED;
SNR           = DVBT2.CH.NOISE.SNR;     % Signal to noise ratio (dB)
GUARD_INT = 1/DVBT2.GI_FRACTION; % Guard interval 
nCP = fix(NFFT/GUARD_INT); % Number of samples of cyclic prefix
NFFT     = DVBT2.STANDARD.NFFT;  % FFT number of points
C_PS     = DVBT2.STANDARD.C_PS;
C_L = 0;%(NFFT - C_PS - 1)/2 + 1;

P2P_LOC     = DVBT2.STANDARD.P2P_LOC;    % P2 pilots locations
N_P2        = DVBT2.STANDARD.N_P2;       % P2 symbols per frame
L_FC        = DVBT2.STANDARD.L_FC;       % FC symbols per frame 1 or 0
FCP_LOC     = DVBT2.STANDARD.FCP_LOC;    % FC pilots locations

ts = TU/NFFT;
%p = sum(DataIn.*conj(DataIn))/length(DataIn);
snr = 10^(SNR/10);
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

fprintf(FidLogFile,'\t\tMode=%s\n', MODE);
if MISO_ENABLED
else
    misoGroup = 1;
end

dataAux = (sqrt(27*C_PS)/(5*NFFT))*fft(DataIn, NFFT, 2);
data_noncorrected = fftshift(dataAux, 2);
data = data_noncorrected(:, C_LOC);
y = DataIn;
x = DataIn;

% ----------------------------------------------------------------
      % Separate SP here and save them to file
      numSymb = size(data,1);

        for symbIdx = 1:numSymb   % for each symbol
            symbInFrame = mod(symbIdx-1, L_F);
            % Get scattered pilot locations
            spLoc = SP_LOC(mod(symbInFrame,SP_PATTLEN)+1, :);
            spLoc = spLoc(find(spLoc>0));
            % Assign pilot signals before marking them
            spLoc_rx_my = data(symbIdx,C_L+spLoc);
            edge_rx_my = data(symbIdx,C_L+EDGE_LOC);
            if symbIdx==1
                spLoc_rx_m_array = zeros(numSymb,length(spLoc_rx_my));
                p_sp_rx_m_array = zeros(numSymb,length(data_noncorrected(1,:)));
                edge_rx_m_array = zeros(numSymb,length(edge_rx_my));
            end
             spLoc_rx_m_array(symbIdx,1:length(spLoc_rx_my)) = spLoc_rx_my;
             edge_rx_m_array(symbIdx,1:length(edge_rx_my)) = edge_rx_my;
             p_data = zeros(1,length(C_LOC));
             p_data(spLoc) = spLoc_rx_my;
             p_sp_rx_m_array(symbIdx,C_LOC) = p_data;
        end

        % Write scattered pilot to file
        if ~strcmp(SP_FNAME, '')
         save(strcat(SIM_DIR, filesep, SP_FNAME),'spLoc_rx_m_array','edge_rx_m_array')
         fprintf(FidLogFile,'\t\tScattered pilot output  saved in file: %s\n',...
         SP_FNAME);
        end
        
        
                
        %%%% Saving the P2 pilot values
        for symbIdx = 1:numSymb   % for each symbol
            symbInFrame = mod(symbIdx-1, L_F);
            if(symbInFrame<N_P2) %% It is a P2 symbol
                p2pLoc = P2P_LOC(find(P2P_LOC>0));
                p2pLoc_rx_my  = data(symbIdx,C_L+p2pLoc);
                if symbIdx==1
                    p2pLoc_rx_m_array = nan(numSymb,length(p2pLoc_rx_my));
                end
                p2pLoc_rx_m_array(symbIdx,1:length(p2pLoc_rx_my)) = p2pLoc_rx_my;
            end
            
            if((symbInFrame == L_F-L_FC)) %% it is a frame closing symbol
                fcpLoc = FCP_LOC(find(FCP_LOC>0));
                fcpLoc_rx_my  = data(symbIdx,C_L+fcpLoc);
               if(~exist('fcpLoc_rx_m_array', 'var'))
                   fcpLoc_rx_m_array = nan(numSymb,length(fcpLoc_rx_my));
               end
                fcpLoc_rx_m_array(symbIdx,1:length(fcpLoc_rx_my)) = fcpLoc_rx_my;
            end
        end
        
        if N_P2 > 0
            if L_FC > 0
            %%% Write P2 and FC pilot to file
                if ~strcmp(SP_FNAME, '')
                 save(strcat(SIM_DIR, filesep, SP_FNAME),'spLoc_rx_m_array','edge_rx_m_array','p2pLoc_rx_m_array','fcpLoc_rx_m_array')
                 fprintf(FidLogFile,'\t\tP2 pilot output  saved in file: %s\n',...
                 SP_FNAME);
                end        
            else
                % Write P2 pilot to file
                if ~strcmp(SP_FNAME, '')
                 save(strcat(SIM_DIR, filesep, SP_FNAME),'spLoc_rx_m_array','edge_rx_m_array','p2pLoc_rx_m_array')
                 fprintf(FidLogFile,'\t\tP2 pilot output  saved in file: %s\n',...
                 SP_FNAME);
                end 
            end
        end
        
        
        
        

% ----------------------------------------------------------------
       if  strcmp(DVBT2.DOPPLER_DICT,'Optim-Basis')
       %%%%% Initializing the Optimal Doppler Basis
           J = size(DataIn,1);
           J = 32;
           Dop_Basis = optimizedDopplerBasis(DVBT2,J);
%            save(strcat(SIM_DIR, filesep, 'OptimBasis'),'Dop_Basis','J'); %% Basis is already saved inside the function
       end



       %data_che_est = t2_rx_bp(DVBT2, FidLogFile);
       %chan = t2_rx_ompalg(DVBT2, FidLogFile);
       chan = t2_rx_ompalg_full(DVBT2, FidLogFile);
       %data_che_est = t2_rx_bmpalg_full(DVBT2, FidLogFile);
       
       if(DVBT2.CHANTRACK == 1)                                             %%%% Channel Tracking
           %%% Channel Tracking wil be used for Normal Symbols excluding FC and  P2 Symbols                                                        %%%% Channel Tracking
           for index = (N_P2+1):(numSymb-L_FC)
               chan.tau(index,:) = chan.tau(N_P2,:);
               chan.fd(index,:) = chan.fd(N_P2,:);
               chan.ro(index,:) = chan.ro(N_P2,:);
           end
       end

      %F = dftmtx(NFFT);
      %F_H = conj(F);

     % Get the delay, atenuation, phase and doppler frequency
      load(strcat(SIM_DIR, filesep, 'sp_tx_do'), 'spLoc_tx_m_array'); % Load data
      chSeed = 1000*rand(1);
      %{
      ChParams = t2_ch_dvbtpscen_getch(DVBT2, chSeed, FidLogFile);
      ro  = ChParams.ro(:,misoGroup);
      tau = ChParams.tau(:,misoGroup);
      phi = ChParams.phi(:,misoGroup);
      fd  = ChParams.fd(:,misoGroup);
      cos_array = [cosd(90) cosd(0) cosd(15) cosd(30) cosd(45) cosd(60)];
      cos_array = [cosd(30) cosd(45) cosd(15) cosd(90) cosd(0) cosd(60)];
      fd = fd.*cos_array(1:length(tau))';
      
      fn = strcat('DVBT2_chan', num2str(SNR),'','.mat');
      load(strcat(SIM_DIR, filesep, fn),'chan')
      %}
      [num len] = size(dataAux);
      %C_L = (NFFT - C_PS - 1)/2 + 1;

% ----------------------------------------------------------------
%load(strcat(SIM_DIR, filesep, 'h'),'h') % real channel transfer function
%summ = 0;
% ----------------------------------------------------------------
H_l_k = zeros(num,NFFT);

for ii = 1:num
% ----------------------------------------------------------------
%%{
      f = find(chan.ro(ii,:)==-1);
      if length(f)>0
          f = f(1)-1;
      else
          f = length(chan.ro(ii,:));
      end
       
      ro = (chan.ro(ii,1:f));
      tau = (chan.tau(ii,1:f));
      fd = (chan.fd(ii,1:f));
      %}
      phi = zeros(1,length(tau));
      
      hT_DS = zeros(length(tau),NFFT);
      hTD = zeros(length(tau),NFFT);  
      hF_DS = zeros(length(tau),NFFT);

        for k = 1:length(tau)
  Indx = 0:(NFFT-1);
  
%%%%%%%%%%%%%%%%%%%%% DELAY ATOM%%%%%%%%%%%%%%%%%%%
switch DVBT2.DELAY_DICT
    case 'Fourier'
        %%% Fourier Atoms
        freqIndx = 1:NFFT;
        freqIndx = freqIndx - (NFFT/2) - 1;
        carSpacing = 1/TU;
        freqIndx = 2 * pi * freqIndx * carSpacing;
        hF_DS(k,:) = hF_DS(k,:) + ro(k) * exp(1j*( phi(k) - freqIndx*tau(k)*1e-6));
        hT_DS(k,:) = fftshift(ifft(fftshift(hF_DS(k,:))));
        hTD(k,:) = hT_DS(k,:);
        
    case 'Sinc'
        %%% Sinc Atoms
        h_sinc = ro(k) * fftshift(sinc(1*(Indx-(tau(k)*1e-6)/ts)));
        hTD(k,:) = hTD(k,:)+ h_sinc;
        
    case 'Gabor'
        %%% Gabor Atom
        %%% Dialation by ts and translation via Tau
        %%%Not working
        Index_new = (Indx*ts -(tau(k)*1e-6)).^2;
        Index_new = Index_new/((ts).^2);
        dic_Ind = exp(-Index_new);
        hTD(k,:) = hTD(k,:)+ ro(k) *fftshift(dic_Ind);

    case 'Wavelet'
        %%% Wavelet(Shannon) Atoms
        %%% Dialation by ts and translation via Tau
        Index_new = Indx -(tau(k)*1e-6)/ts;
        dic_Ind = (2*sinc(2*Index_new) - sinc(Index_new))/sqrt(ts);
        hTD(k,:) =  hTD(k,:)+ ro(k) *fftshift(dic_Ind);
    
    case 'RC-Wavelet'
        %%% Raised cosine Filter with Wavelet(Shannon) Atoms
        %%% Dialation by ts and translation via Tau
        rol = 0.025;
        Index_new = Indx -(tau(k)*1e-6)/ts;
        dic_Ind = (2*sinc(2*Index_new) - sinc(Index_new))/sqrt(ts);
        Filt = cos(rol.*pi.*Index_new)./(1-((2.*rol.*Index_new).^2));
        hTD(k,:) =  hTD(k,:)+ ro(k) *fftshift(dic_Ind.*Filt);
        
    case 'RC-Sinc'
        %%% raised cosine filter with sinc Atoms
        rol = 0.25; %0.025; % Old simulations;
        Indx_f = 1*(Indx-(tau(k)*1e-6)/ts);
        Filt = cos(rol.*pi.*Indx_f)./(1-((2.*rol.*Indx_f).^2));
        h_sinc = ro(k) * fftshift(sinc(Indx_f).*Filt);
        hTD(k,:) = hTD(k,:)+ h_sinc;
        
    case 'RC-Fourier'
        %Raised Cosine filter with Fourier Atoms

        rol = 0.25; %0.025; % Old simulations
        Indx_f = 1*(Indx-(tau(k)*1e-6)/ts);
        Filt = cos(rol.*pi.*Indx_f)./(1-((2.*rol.*Indx_f).^2));

        freqIndx = 1:NFFT;
        freqIndx = freqIndx - (NFFT/2) - 1;
        carSpacing = 1/TU;
        freqIndx = 2 * pi * freqIndx * carSpacing;
        hF_DS(k,:) = hF_DS(k,:) + ro(k) * exp(1j*( phi(k) - freqIndx*tau(k)*1e-6));
        hT_DS(k,:) = fftshift(ifft(fftshift(hF_DS(k,:))).*Filt);
        hTD(k,:) = hT_DS(k,:);
    
    case 'Optim-Basis'
        %%%% The fourier basis used in the delay domain for the optimized 
        %%%% basis determined using the TAUBÖCK Paper
        %%% Fourier Atoms
        freqIndx = 1:NFFT;
        freqIndx = freqIndx - (NFFT/2) - 1;
        carSpacing = 1/TU;
        freqIndx = 2 * pi * freqIndx * carSpacing;
        hF_DS(k,:) = hF_DS(k,:) + ro(k) * exp(1j*( phi(k) - freqIndx*tau(k)*1e-6));
        hT_DS(k,:) = fftshift(ifft(fftshift(hF_DS(k,:))));
        hTD(k,:) = hT_DS(k,:);
%         hTD(k,:) = fftshift(hF_DS(k,:));
                
        
    otherwise, error('t2_rx_dict_tubs UNKNOWN DELAY DICTIONARY');
end
  

        end

  hT_DSS = (hTD(:,:));
% ----------------------------------------------------------------
h_m = zeros(length(tau),NFFT);
lenDop = 1*(NFFT + nCP);
indx_ds = zeros(length(tau),NFFT);
for t = 1:length(tau)
hT_DSS(t,:) = fftshift(hT_DSS(t,:));

%%%%%%%%%%%%%%%%%%%%% DOPPLER ATOM%%%%%%%%%%%%%%%%%%%

switch DVBT2.DOPPLER_DICT
    case 'Fourier'
        %%% Fourier Dictionary
        doppIndx = fd(t)*(0:(lenDop-1));
        doppIndx = 2 * pi * doppIndx * ts;
        doppIndx = exp(1j*doppIndx);
        indx_ds(t,:) = doppIndx(nCP+1:nCP+NFFT);
        H_l_k(ii,:) = H_l_k(ii,:) + hF_DS(t,:).*indx_ds(t,:);
        
     %%% cosine dictionary   
    case 'DCT-I'
        %%%% DCT-I dictionary
        doppIndx = 0:(lenDop-1);
        Fd_disc = fd(t)*ts;
        doppIndx = cos(2.*pi.*Fd_disc.* doppIndx); %DCT-I
        indx_ds(t,:) = doppIndx(nCP+1:nCP+NFFT);
        
    case 'DCT-II'
         %%%% DCT-II dictionary
        doppIndx = 0:(lenDop-1);
        Fd_disc = fd(t)*ts;
        doppIndx = cos(pi.*(doppIndx +1/2).*Fd_disc); %DCT-II
        indx_ds(t,:) = doppIndx(nCP+1:nCP+NFFT);
%         H_l_k(ii,:) = H_l_k(ii,:) + hF_DS(t,:).*indx_ds(t,:);

    case 'Exp-DCT-I'
        %%%% Exponential DCT-I dictionary
        doppIndx = 0:(lenDop-1);
        Fd_disc = fd(t)*ts;
        doppIndx = cos(2.*pi.*Fd_disc.* doppIndx); %DCT-I
        doppIndx = exp(doppIndx);  % exponential DCT
        indx_ds(t,:) = doppIndx(nCP+1:nCP+NFFT);        
        
    case 'Exp-DCT-II'
        %%%% Exponential DCT-II dictionary
        doppIndx = 0:(lenDop-1);
        Fd_disc = fd(t)*ts;
        doppIndx = cos(pi.*(doppIndx +1/2).*Fd_disc); %DCT-II
        doppIndx = exp(doppIndx);  % exponential DCT
        indx_ds(t,:) = doppIndx(nCP+1:nCP+NFFT);
        
    case 'Gabor'
        %gabor dictionary
        Indx1 = 0:lenDop-1;
        doppIndx = Indx1*ts - (tau(t)*1e-6);
        doppIndx = 2*pi*fd(t)*doppIndx;
        indx_ds(t,:) = cos(doppIndx(nCP+1:nCP+NFFT) + phi(t));
        
    case 'Wavelet'
        %%% Wavelet(Morlet) Atom
        %%% Dialation by (ts) and translation via Fd
        
        doppIndx = 0:(lenDop-1);
        doppIndx = doppIndx*ts;% - (tau(k)*1e-6);
        dic_Ind = exp(1j*2*pi*fd(t).*doppIndx).*exp(-(doppIndx.^2)/2)./(pi.^(1/4));
        indx_ds(t,:)= dic_Ind(nCP+1:nCP+NFFT);
        
        %%% Wavelet(Shannon) Atoms
        %%% Dialation by (1/TU) and translation via Fd
        %%% Not working
%         doppIndx = 1:lenDop;
%         doppIndx = doppIndx - (lenDop/2) -1;
%         carSpacing = 1/TU;
%         doppIndx = doppIndx -fd(k)/(carSpacing);
%         dic_Ind = (2*sinc(2*doppIndx) - sinc(doppIndx))/sqrt(carSpacing);
%         indx_ds(t,:) = fftshift(ifft(fftshift(dic_Ind(nCP+1:nCP+NFFT))));


    case 'Optim-Basis'
        %%%% The optimized basis determined using the TAUBÖCK Paper
        load(strcat(SIM_DIR, filesep, 'OptimBasis'),'Dop_Basis','J');
        i_val = (-J/2:J/2-1);
        ind_i = round(TU*fd(t)*J);
        ind_i = find(i_val ==ind_i);
        
        %%% The basis which corresponds to the current doppler frequency
        Dop_Basis_curr = Dop_Basis(:,ind_i);
        Dop_Basis_curr = Dop_Basis_curr(ii); %% This value corrsponds to the doppler for each element of the delay atom
        
%         dic_Ind = Dop_Basis_curr * hT_DSS(t,:);
%         hT_DSS(t,:) = ifft(dic_Ind,NFFT);
%         indx_ds(t,:)= ones(1,NFFT);                                   %%% For H./
        
%         H_l_k(ii,:) = H_l_k(ii,:) + fftshift(fft(fftshift(hTD(t,:))))*Dop_Basis_curr;        %%% For H./ with RC-Fourier
       

        dic_Ind = Dop_Basis_curr*ones(1,lenDop);                         %%% FOR LSQR
        
%         dic_Ind = fftshift(ifft(fftshift(dic_Ind))); 
        
        indx_ds(t,:)= dic_Ind(nCP+1:nCP+NFFT);                          %%% FOR rLSQR
        
%         H_l_k(ii,:) = H_l_k(ii,:) + hF_DS(t,:)*Dop_Basis_curr;        %%% For H./

        
    otherwise, error('t2_rx_dict_tubs UNKNOWN DOPPLER DICTIONARY');        
end


  


%doppIndx_re = exp(-1j*doppIndx);
%indx_ds_rev = doppIndx_re(nCP+1:nCP+NFFT);
%indx_ds_rev = (ifft(indx_ds_rev));
%hT_DSS(t,:) = indx_ds_rev.*hT_DSS(t,:);
end
for t = 1:length(tau)
    for r = 1:NFFT
        %h_m(t,r) = hT_DSS(t,NFFT-r+1);
    end
end
%H_c = zeros(NFFT,NFFT);
for c = 1:NFFT
    %row = zeros(1,NFFT);
    for t = 1:length(tau)
        %row = row + indx_ds(t, c)*circshift(h_m(t,:), [1 c]);
    end
%H_c(c,1:NFFT) = row;
end
BEM_Cf = hT_DSS;
BEM_seq = indx_ds(:,1:NFFT);
%CIR = (BEM_Cf.'*BEM_seq).';
%{
sym_i = ii;
hT = h((sym_i-1)*(NFFT+nCP)+1:1:sym_i*(NFFT+nCP),:);
CIR = hT(nCP+1:end,:); 
D = 2;
I = 2;
Type = 'LP'; % data symbol
[T BEM_seq] = t2_rx_construct_OP_Matrix(DVBT2, FidLogFile, D,I,NFFT,Type);
BEM_Cf = pinv(BEM_seq.')*CIR;
%}
x(ii,:) = (t2_rx_ChanEq_FFT_LSQR((y(ii,:)), 1:NFFT, BEM_Cf, BEM_seq, 30));
%{
CIR = (BEM_Cf.'*BEM_seq);
[hLoc, hO] = t2_rx_init_TDChan_matrix(DVBT2, FidLogFile, NFFT, NFFT);
H_c = t2_rx_build_TDFChan_matrix(DVBT2, FidLogFile,CIR,hO,hLoc,NFFT,numSymb);
%}
%x(ii,:) = conj(H_c)*inv(H_c*conj(H_c) + eye(NFFT)/snr)*y(ii,:).';
%x(ii,:) = conj(H_c)*pinv(H_c*conj(H_c) + eye(NFFT)/snr)*y(ii,:).';
%A = (H_c*conj(H_c) + eye(NFFT)/snr);
%x(ii,:) = conj(H_c)*(A\(y(ii,:).'));
%clear A;
%clear H_c;
%{
% ----------------------------------------------------------------
% ANMSE
h_r = BEM_Cf.*BEM_seq;
h_t = (h(nCP*ii+NFFT*(ii-1)+1:(nCP+NFFT)*ii,:)).';
h_t = (sum(h_t(:,1:NFFT)));
h_r = (sum(h_r(:,1:NFFT)));
summ = summ + (norm(h_t-h_r,2)^2)...
        /(norm(h_r,2)^2);
%}
end
%summ
%A = F*H_c*F_H;
%A_inv = NFFT*inv(A);

%DataEqualized = dataAux;
for n = 1:num
%DataEqualized(n,:) = A_inv*DataEqualized(n,:).';
end

% ----------------------------------------------------------------
% LMMSE Analysis of pilot patterns and channel estimation for DVB-T2
for n = 1:num
%x(n,:) = ((conj(H_c)*inv(H_c*conj(H_c))+eye(NFFT)/snr)*y(n,:).');
end
%dataAux_lmmse = (sqrt(27*C_PS)/(5*NFFT))*fft(x, NFFT, 2);
dataAux_lsqr = (sqrt(27*C_PS)/(5*NFFT))*(fft(x, NFFT, 2));

% ----------------------------------------------------------------
% FFT shift
%dataAux = fftshift(dataAux, 2);
%dataAux = fftshift(DataEqualized, 2);
%dataAux = fftshift(dataAux_lmmse, 2);
dataAux = fftshift(dataAux_lsqr, 2);
% if  strcmp(DVBT2.DOPPLER_DICT,'Optim-Basis')
%     dataAux = data_noncorrected ./ H_l_k;                               %%% For H./
% end

if(DVBT2.CHANTRACK == 1)
    %%%% Performing Channel tracking and equalization
    dataAux = t2_rx_dvbt2ChanTrack(DVBT2, FidLogFile, dataAux);             %%%% Channel Tracking
end



hEstCh = data_noncorrected./dataAux;
save(strcat(SIM_DIR, filesep, 'hEstCh'),'hEstCh')

% ----------------------------------------------------------------
%         ANMSE
%
%load(strcat(SIM_DIR, filesep, 'dat'),'dat')
%hEstCh_h = data_noncorrected./dat;
%summ = (norm(hEstCh-hEstCh_h,2)^2)...
%        /(norm(hEstCh_h,2)^2);
%20 * log10(summ/numSymb)
% ----------------------------------------------------------------

% Get only the useful carriers 
DataOut = dataAux(:, C_LOC);


