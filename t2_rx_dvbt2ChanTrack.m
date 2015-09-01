function DataOut = t2_rx_dvbt2ChanTrack(DVBT2, FidLogFile, DataIn)

N_P2        = DVBT2.STANDARD.N_P2;       % P2 symbols per frame
L_FC        = DVBT2.STANDARD.L_FC;       % FC symbols per frame 1
C_LOC    = DVBT2.STANDARD.C_LOC; % Carriers location
NFFT     = DVBT2.STANDARD.NFFT;  % FFT number of points
L_F         = DVBT2.STANDARD.L_F;       % Symbols per frame
SP_PATTLEN  = DVBT2.STANDARD.SP_PATTLEN; % Scattered pilots pattern length
SP_LOC      = DVBT2.STANDARD.SP_LOC;     % Scattared pilots locations
EDGE_LOC    = DVBT2.STANDARD.EDGE_LOC;   % Edge pilots locations
PN_SEQ      = DVBT2.STANDARD.PN_SEQ;     % PN sequence
C_PS     = DVBT2.STANDARD.C_PS;
SIM_DIR      = DVBT2.SIM.SIMDIR;          % Saving directory
prbs = t2_tx_dvbt2blfadapt_prbsseq(DVBT2);

C_L = (NFFT - C_PS - 1)/2 + 1;


numSymb = size(DataIn,1);
DataOut = DataIn;
load(strcat(SIM_DIR, filesep, 'EDGEcen_ch_do'), 'EDGE_tx_m_array'); % Load data for edge pilots


%%% Channel Tracking for Phase
% data_phcorr = nan(numSymb,NFFT);
% car_loc = 1:C_PS;
% 
% for symbIdx = (N_P2+1):(numSymb-L_FC)   % for each symbol
%     symbInFrame = mod(symbIdx-1, L_F);
%     % Get scattered pilot locations
%     spLoc = SP_LOC(mod(symbInFrame,SP_PATTLEN)+1, :);
%     spLoc = spLoc(find(spLoc>0));
%     
%     % Get received pilots scattered and edge
%     sym = zeros(1,C_PS);
%     sym(spLoc) = 1;
%     sym(EDGE_LOC) = 1;
%     pil_loc = find(sym);   
%     pil_loc_sym = pil_loc + C_L; 
%     pilot_rx_my = DataIn(symbIdx,C_L+ pil_loc);    
%     rx_sym = DataIn(symbIdx,:);  % received symbol
%   
%     
%     % Get transmitted pilots
%     refSequence = xor(prbs, PN_SEQ(symbInFrame + 1));
%     MISOInversionData(1:C_PS) = 1;
%     scatteredPilotMap = t2_tx_dvbt2blfadapt_bpsk_sp(DVBT2, refSequence) .* MISOInversionData;
%     sym = nan(1,C_PS);
%     sym(spLoc) = scatteredPilotMap(spLoc);
%     sym(EDGE_LOC) = EDGE_tx_m_array(symbIdx,:);   
%     pilots_tx_my = sym(find(~isnan(sym)));
%     
%     % linear regression based phase tracking
%     avg_mag = mean(abs(pilot_rx_my));
%     phase_diff = angle(pilot_rx_my) -  angle(pilots_tx_my);
%     my = mean(phase_diff);
%     mx = mean(pil_loc_sym);
%     var = mean(pil_loc_sym.*pil_loc_sym) - mx*mx;
%     cov = mean(phase_diff.*pil_loc_sym) - mx*my;
%     beta = cov/var;
%     alpha = my - beta*mx;
%     
%     %%% Correcting phase for all the subcarriers
%     ind = 0:NFFT-1;
%     sym_out = rx_sym.*exp(1j*(ind*beta-alpha))/avg_mag;
%     
% %     sym_out = nan(1,NFFT);    
% %     for n = 1:NFFT
% %         sym_out(n) = rx_sym(n)*exp(1j*((n-1)*beta-alpha))/avg_mag;
% %     end
%       
%     data_phcorr(symbIdx,:) = sym_out; % data which has the corrected phase
%     
% end
% data = data_phcorr(:, C_LOC);

data = DataIn(:, C_LOC);                                        %%% Comment for phase tracking

num_pil = size(SP_LOC,2) + size(EDGE_LOC,2);
spLoc_rx_m_array = nan(numSymb,num_pil);
spLoc_tx_m_array = nan(numSymb,num_pil);
spLoc_chan_array = nan(numSymb,num_pil);
spLoc_chan_estim_array = nan(numSymb,C_PS);

%%%% Channel Tracking for Amplitude
for symbIdx = (N_P2+1):(numSymb-L_FC)   % for each symbol
    symbInFrame = mod(symbIdx-1, L_F);
    % Get scattered pilot locations
    spLoc = SP_LOC(mod(symbInFrame,SP_PATTLEN)+1, :);
    spLoc = spLoc(find(spLoc>0));
    % Get received pilots scattered and edge
    sym = zeros(1,C_PS);
    sym(spLoc) = 1;
    sym(EDGE_LOC) = 1;
    pil_loc = find(sym);

    spLoc_rx_my = data(symbIdx, pil_loc);    
    spLoc_rx_m_array(symbIdx,1:length(spLoc_rx_my)) = spLoc_rx_my;
    
    % Get transmitted pilots
    refSequence = xor(prbs, PN_SEQ(symbInFrame + 1));
    MISOInversionData(1:C_PS) = 1;
    scatteredPilotMap = t2_tx_dvbt2blfadapt_bpsk_sp(DVBT2, refSequence) .* MISOInversionData;
    % Adding the Edge pilot values
    sym = nan(1,C_PS);
    sym(spLoc) = scatteredPilotMap(spLoc);
    sym(EDGE_LOC) = EDGE_tx_m_array(symbIdx,:);
    
%     pilots_tx_my = [EDGE_tx_m_array(symbIdx,1) scatteredPilotMap(spLoc) EDGE_tx_m_array(symbIdx,2)];
    pilots_tx_my = sym(find(~isnan(sym)));
    spLoc_tx_m_array(symbIdx,1:length(pilots_tx_my)) = pilots_tx_my;
    
    
    % Get LS estimate
    spLoc_chan = spLoc_rx_my./pilots_tx_my;
    spLoc_chan_array(symbIdx,1:length(spLoc_chan)) = spLoc_chan;
    
    % Perform Linear Interpolation
    chan_estim = nan(1,C_PS);
    for pil_val = 1:(length(pil_loc)-1)
        pil_diff = pil_loc(pil_val+1) -  pil_loc(pil_val);
        for t = 0:(pil_diff-1)
           chan_estim(pil_loc(pil_val) + t) = spLoc_chan(pil_val)+ (spLoc_chan(pil_val+1) - spLoc_chan(pil_val))*(t/pil_diff);
        end
    end
    pil_val = pil_val +1;
    chan_estim(pil_loc(pil_val)) = spLoc_chan(pil_val);

    
    spLoc_chan_estim_array(symbIdx,1:length(chan_estim)) = chan_estim;
    
    DataOut(symbIdx,C_LOC) = data(symbIdx,:) ./ spLoc_chan_estim_array(symbIdx,:);
    
end

end

% Chan_real = real(spLoc_chan_array(3,1:length(pil_loc)));
% plot(pil_loc,Chan_real(find(~isnan(Chan_real))),'+b')
% hold on
% ChanEstim_real = real(spLoc_chan_estim_array(3,:));
% 
% plot(car_loc,ChanEstim_real,'-r')
% hold off

% real_phdiff = real(phase_diff);
% plot(C_L+ pil_loc,real_phdiff,'+b')
% hold on
% y = alpha +beta*(0:NFFT-1);
% plot(1:NFFT,y,'-r')



%     %%% Extrapoloation also needed if edge pilots are not used
%     %%% Extrapolating the subcarriers before the first pilot
%     pil_diff = spLoc(1) - 1;
%     for t = 1:(pil_diff)
%         chan_estim(t) = chan_estim(spLoc(1))+ (chan_estim(spLoc(1)+1) - chan_estim(spLoc(1)))*(t-spLoc(1));
%     end
%     
%     %%% Extrapolating the subcarriers after the last pilot
%     for t = (spLoc(end)+1):C_PS
%         chan_estim(t) = chan_estim(spLoc(end)-1)+ (chan_estim(spLoc(end)) - chan_estim(spLoc(end)-1))*(t-(spLoc(end)-1));
%     end