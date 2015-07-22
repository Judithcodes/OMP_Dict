function DataOut = t2_tx_dvbt2blfadapt_bpsk_cp(DVBT2, DataIn)


%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
MODE  = DVBT2.MODE; % FFT size

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

switch MODE
    case '1k'
        C = 4/3;    % Normalization factor
    case '2k'
        C = 4/3;    % Normalization factor
    case '4k'
        C = 4*sqrt(2)/3;    % Normalization factor
    case '8k'
        C = 8/3;    % Normalization factor
    case '16k'
        C = 8/3;    % Normalization factor
    case '32k'
        C = 8/3;    % Normalization factor
    otherwise, error('t2_dvbt2fbuild_scatloc UNKNOWN MODE');
end

C_POINTS    = [1 -1]*C; % Constellation points

DataOut = C_POINTS(DataIn+1);
