function DataOut = t2_tx_dvbt2blfreqint(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_tx_dvbt2blfreqint SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
MODE     = DVBT2.MODE;               % DVBT mode
C_DATA  = DVBT2.STANDARD.C_DATA; % Data carriers per normal symbol
C_P2	= DVBT2.STANDARD.C_P2; % Data carriers in P2 symbols
N_FC	= DVBT2.STANDARD.N_FC; % Data carriers in frame closing symbols (including the thinning cells)
L_F     = DVBT2.STANDARD.L_F; % symbols per T2-frame
N_P2    = DVBT2.STANDARD.N_P2; % Number of P2 symbols per T2-frame
L_FC    = DVBT2.STANDARD.L_FC; % Number of Frame Closing symbols

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

data = DataIn(:);
  
fprintf(FidLogFile,'\t\tMode=%s \n', MODE);
        
% Symbol permutation matrices
[hSEven, hSOdd, hSEvenP2, hSOddP2, hSEvenFC, hSOddFC] = t2_tx_dvbt2blfreqint_spermat(DVBT2);


% TODO: apply the P2 and Frame Closing values in those symbols
if(~DVBT2.TX.FBUILD.ENABLE && N_P2 > 0)
    dumDataWid = C_DATA-C_P2
    dumDataLen = length(data) + N_P2*dumDataWid;
    % DummyData = nan(1,dumDataWid) %% Not needed since matrix already has NAN

    Data_new = nan(1,dumDataLen);

    for i=0:(N_P2-1)
        Data_new((i*C_DATA + 1):(i*C_DATA + C_P2)) = data((i*C_P2+1):(i*C_P2+C_P2));
    %     Data_new((i*C_DATA + C_P2+1): (i*C_DATA + C_DATA)) = DummyData;  %% Not needed since matrix already has NAN
    end
    i=i+1;
    Data_new((i*C_DATA + 1):end) = data((i*C_P2+1):end);

    data = Data_new.';
    clear Data_new dumDataWid dumDataLen;
end
% TODO: Consider adding dummy data here

% TODO: apply thinning in frame closing symbol

% Only complete OFDM symbols can be interleaved
% (A symbol is made of V*DCPS bits)
numSymb = floor(length(data)/C_DATA);
data = data(1:numSymb*C_DATA);

data = reshape(data, C_DATA, numSymb).'; % each row is a symbol

% Indices for each symbol
symbols = 0:numSymb-1;
symbolIndices = mod(symbols, L_F);
evenSymbols = symbols(mod(symbolIndices, 2) == 0);
oddSymbols = symbols(mod(symbolIndices, 2) == 1);
evenP2Symbols = evenSymbols(mod(evenSymbols, L_F)<N_P2);
oddP2Symbols = oddSymbols(mod(oddSymbols, L_F)<N_P2);
evenFCSymbols = evenSymbols(mod(evenSymbols, L_F)==L_F-L_FC);
oddFCSymbols = oddSymbols(mod(oddSymbols, L_F)==L_F-L_FC);
evenNormalSymbols = evenSymbols(mod(evenSymbols, L_F)>=N_P2 & mod(evenSymbols, L_F)<L_F-L_FC);
oddNormalSymbols = oddSymbols(mod(oddSymbols, L_F)>=N_P2 & mod(oddSymbols, L_F)<L_F-L_FC);

% Symbol interleaver  

symIntlvOut                   = zeros(numSymb, C_DATA);

symIntlvOut(evenP2Symbols+1,1:C_P2) = data(evenP2Symbols+1,hSEvenP2+1);    % Even P2
symIntlvOut(oddP2Symbols+1,1:C_P2)    = data(oddP2Symbols+1,hSOddP2+1); % Odd P2

symIntlvOut(evenNormalSymbols+1,:) = data(evenNormalSymbols+1,hSEven+1);    % Even
symIntlvOut(oddNormalSymbols+1,:)    = data(oddNormalSymbols+1,hSOdd+1); % Odd

symIntlvOut(evenFCSymbols+1,1:N_FC) = data(evenFCSymbols+1,hSEvenFC+1);    % Even FCS
symIntlvOut(oddFCSymbols+1,1:N_FC)    = data(oddFCSymbols+1,hSOddFC+1); % Odd FCS

% Put NaNs in unused elements (useful for writing V&V test points)
symIntlvOut(evenP2Symbols+1,C_P2+1:end) = NaN;    % Even P2
symIntlvOut(oddP2Symbols+1,C_P2+1:end) = NaN; % Odd P2

symIntlvOut(evenFCSymbols+1,N_FC+1:end) = NaN;    % Even FCS
symIntlvOut(oddFCSymbols+1,N_FC+1:end) = NaN; % Odd FCS


data = reshape(symIntlvOut.', C_DATA*numSymb, 1);

% Write V&V point
write_vv_test_point(data, C_DATA, L_F, '13', 'complex', DVBT2, 1, DVBT2.START_T2_FRAME+1)


fprintf(FidLogFile,'\t\tSymbol interleaver: %d interleaved symbols\n',... 
        numSymb);

DataOut = data.';
