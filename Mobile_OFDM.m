%%####################################################################
% Parameters
%####################################################################
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% System parameter configuration
% Default configuration
clear all;
tic
TestPath='';
WorkPath='work';
FidLog = 'stdout';

%%% For different types of delay and doppler dictionaries. more information
%%% in t2_rx_dict_tubs.m

DVBT2.DELAY_DICT = 'Fourier';
DVBT2.DOPPLER_DICT = 'Fourier';
DVBT2.CHANTRACK = 1;
DVBT2.P2Data = 0;  %% Set to 1 inorder to include no data in P2 Symbols

%%% L1 signaling commands (P2 and Frame closing Symbols)
Commandline_Params = {{'DVBT2.STRICT=0','DVBT2.TX.ENABLE=1','DVBT2.MISO_ENABLED=0','DVBT2.CH.PSCEN.CHSTR.TYPE=''DVBT-P''','DVBT2.SP_PATTERN=''PP1''','DVBT2.TX.BBSCRAMBLE_FDI  = ''L1Gen_tx_do''','DVBT2.TX.L1GEN_FDI   = ''madapt_tx_do''','DVBT2.TX.L1GEN_FDO   = ''L1Gen_tx_do''','DVBT2.TX.DMCELLS.ENABLE = 0','DVBT2.TX.L1GEN.ENABLE   = 1','DVBT2.TX.FBUILD.ENABLE  = 1','DVBT2.RX.DMCELLS.ENABLE  = 0','DVBT2.RX.FEXTRACT.ENABLE = 1'}};

%%% Normal Symbols commands
% Commandline_Params = {{'DVBT2.STRICT=0','DVBT2.TX.ENABLE=1','DVBT2.MISO_ENABLED=0','DVBT2.CH.PSCEN.CHSTR.TYPE=''DVBT-P''','DVBT2.SP_PATTERN=''PP1'''}};

DVBT2.CFG_TYPE = 'DVBT2BL_NOL1';  % Configuration model type
DVBT2 = t2_cfg_wr(DVBT2,WorkPath,FidLog);  % Default configuration
DVBT2 = cfg_indep_var(DVBT2,WorkPath);
DVBT2 = override_params(DVBT2, Commandline_Params);
DVBT2.STD_TYPE='DVBT2BL';
DVBT2.STANDARD = t2_std_config_wr(DVBT2);

%Load test scenarios
scenarios = cfg_scenario();
k=1;
  DVBT2.PLP(1).CONSTELLATION = scenarios{k,1};    % Constellation
  DVBT2.PLP(1).CRATE         = scenarios{k,2};    % High priority stream coding rate
  minSNR                     = scenarios{k,3}(1); % Initial SNR
  DVBT2.CH.PSCEN.CHSTR.TYPE  = scenarios{k,4};    % Noise Type
  if size(scenarios,2)>5 % Also add FFT size and Guard Interval
      DVBT2.MODE          =     scenarios{k,6};  % Mode
      DVBT2.EXTENDED      =     scenarios{k,7};  % Extended carrier mode: 1=extended 0=normal
      DVBT2.GI_FRACTION   =     scenarios{k,8};
  end
  
  
  
  % UPDATE Depedent variables
  DVBT2.STANDARD = t2_std_config_wr(DVBT2);
  FidLogFile = 1;
  K = 100;  
  L = 100;
  ber_pilot = []; %modified
  snr_pilot = []; %modified 
  
% if  strcmp(DVBT2.DOPPLER_DICT,'Optim-Basis')
%     %%%%% Initializing the Optimized basis
%     J = 6; %DVBT2.STANDARD.L_F;
%     Dop_Basis = optimizedDopplerBasis(DVBT2,J);
%     save(strcat(SIM_DIR, filesep, 'OptimBasis'),'Dop_Basis','J');
% end

   
   snr_scn = [0 0:5:45];
   snr_scn = [45];  
   
  for j=1:length(snr_scn) %modified
      ll = 0;
    %   kk = 45;
      kk = snr_scn(j)
      DVBT2.L = ll; % Doppler steps
      DVBT2.K = kk; % Doppler steps
       % Change the SNR
      s = DVBT2.PLP(1).CONSTELLATION;
      pos2 = strfind(s,'-');
      SNR0 = 10*log10(log2(str2num(s(1:pos2-1))));
      %SNR0 = 0;
      DVBT2.CH.NOISE.SNR = kk + SNR0 + 0.39;
      DVBT2.CH.PSCEN.ENABLE=1;

    %% ####################################################################
    % Transmitter
    %####################################################################
    t2_tx_dvbt2bltx(DVBT2, FidLogFile);              

    %% ####################################################################
    % Channel
    %####################################################################      
    % Channel propagation scenario
    t2_ch_pscen_wr(DVBT2, FidLogFile)
    % Noise
    t2_ch_noise_wr(DVBT2, FidLogFile)

    %% ####################################################################
    % Receiver
    %####################################################################
    [result] = t2_rx_dvbt2blrx(DVBT2, FidLogFile);

     ber_pilot = [ber_pilot; result.BER.DMAP]; %modified
     snr_pilot = [snr_pilot; snr_scn(j)]; %modified
%      snr_pilot = [snr_pilot; DVBT2.CH.NOISE.SNR]; %modified

    %% ####################################################################
    % Chan estimation
    %####################################################################

    %% ####################################################################
    % Equalization
    %####################################################################
 end  %modified
toc
save('snr_ber_Raw.mat','ber_pilot', 'snr_pilot') %modified