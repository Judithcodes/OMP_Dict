function DataOut = t2_tx_dvbt2blofdm(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbtofdm SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
MODE     = DVBT2.MODE;           % DVBT mode
C_PS     = DVBT2.STANDARD.C_PS;  % Number of carriers per symbol
C_LOC    = DVBT2.STANDARD.C_LOC; % Carriers location
NFFT     = DVBT2.STANDARD.NFFT;  % FFT number of points
MISO_ENABLED = DVBT2.MISO_ENABLED; % 1=MISO 0=SISO
GUARD_INT = 1/DVBT2.GI_FRACTION; % Guard interval 
nCP = fix(NFFT/GUARD_INT); % Number of samples of cyclic prefix

N_P2           = DVBT2.STANDARD.N_P2;  %Number of P2 symbols
NUM_SIM_T2_FRAMES  = DVBT2.NUM_SIM_T2_FRAMES;  %Number of frames
START_T2_FRAME = DVBT2.START_T2_FRAME; %First frame
L_F            = DVBT2.STANDARD.L_F;   %Number of data symbols per frame
NFFT     = DVBT2.STANDARD.NFFT;  % FFT number of points
C_PS     = DVBT2.STANDARD.C_PS;
C_L = 0;%(NFFT - C_PS - 1)/2;

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

fprintf(FidLogFile,'\t\tMode=%s\n', MODE);         

if (MISO_ENABLED)
    misoGroups = 2;
else
    misoGroups = 1;
end

for misoGroup = 1:misoGroups
    
    % Format input
    fftDI = zeros(size(DataIn{misoGroup},1), NFFT);
    fftDI(:, C_LOC) = DataIn{misoGroup};
    
    % FFT shift
    fftDI = fftshift(fftDI, 2);

    % IFFT
    DataOut{misoGroup} = 5/sqrt(27*C_PS)*NFFT*ifft(fftDI, NFFT, 2); % multiplying by NFFT undoes the scale factor applied by ifft()

    for m = 0:NUM_SIM_T2_FRAMES-1
        for s = 1:N_P2
            p2Symbol = DataOut{misoGroup}(m*L_F+s,:);
            rms = 20 *log10(sqrt(mean(abs(p2Symbol).^2)));
            papr = 20*log10(max(abs(p2Symbol))) - rms;
            fprintf (FidLogFile, '\t\tFrame %d P2 symbol %d - PAPR = %.2fdB (Average %.2fdBW)\n', START_T2_FRAME+m+1, s, papr, rms);
        end
    end

    % Write V&V point
    if (MISO_ENABLED)
        write_vv_test_point(DataOut{misoGroup}.', NFFT, L_F, sprintf('16Tx%d',misoGroup), 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)
    else
        write_vv_test_point(DataOut{misoGroup}.', NFFT, L_F, '16', 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)
    end
end

