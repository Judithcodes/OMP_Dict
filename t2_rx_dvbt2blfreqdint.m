function DataOut = t2_rx_dvbt2blfreqdint(DVBT2, FidLogFile, DataIn)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 3,
    ;
  otherwise,
    error('t2_rx_dvbt2blfreqdint SYNTAX');
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

fprintf(FidLogFile,'\t\tMode=%s \n', MODE);
          
dataAux = DataIn.data.';
hest = DataIn.h_est.';

numSymb = size(dataAux,2);

% Symbol permutation matrices
[hSEven, hSOdd, hSEvenP2, hSOddP2, hSEvenFC, hSOddFC] = t2_rx_dvbt2blfreqdint_spermat(DVBT2);

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

% Data
symDeintlv = nan(C_DATA, numSymb);

symDeintlv(1+hSEvenP2,evenP2Symbols+1) = dataAux(1:C_P2,evenP2Symbols+1); % Even P2
symDeintlv(1+hSOddP2,oddP2Symbols+1) = dataAux(1:C_P2,oddP2Symbols+1); %Odd P2

symDeintlv(1+hSEven,evenNormalSymbols+1) = dataAux(:,evenNormalSymbols+1); % Even Normal
symDeintlv(1+hSOdd,oddNormalSymbols+1) = dataAux(:,oddNormalSymbols+1); %Odd Normal

%evenFCSymbols
symDeintlv(1+hSEvenFC,evenFCSymbols+1) = dataAux(1:N_FC,evenFCSymbols+1); % Even Frame Closing
symDeintlv(1+hSOddFC,oddFCSymbols+1) = dataAux(1:N_FC,oddFCSymbols+1); %Odd Frame Closing

% Channel estimate
hest_symDeintlv = nan(C_DATA, numSymb);

hest_symDeintlv(1+hSEvenP2,evenP2Symbols+1) = hest(1:C_P2,evenP2Symbols+1); % Even P2
hest_symDeintlv(1+hSOddP2,oddP2Symbols+1) = hest(1:C_P2,oddP2Symbols+1); %Odd P2

hest_symDeintlv(1+hSEven,evenNormalSymbols+1) = hest(:,evenNormalSymbols+1); % Even Normal
hest_symDeintlv(1+hSOdd,oddNormalSymbols+1) = hest(:,oddNormalSymbols+1); %Odd Normal

%hest_symDeintlv(1+hSEvenFC,evenFCSymbols+1) = hest(1:N_FC,evenFCSymbols+1); % Even Frame Closing
%hest_symDeintlv(1+hSOddFC,oddFCSymbols+1) = hest(1:N_FC,oddFCSymbols+1); %Odd Frame Closing

dataAux = reshape(symDeintlv, C_DATA*numSymb, 1);
if(~DVBT2.TX.FBUILD.ENABLE && N_P2 > 0) 
%%% Consider the unused elements when recovering data back
    ind1 = find(isnan(symDeintlv));
    dataAux(ind1) = [];  
    dataAux = [dataAux; nan(length(ind1),1)];
    % dataAux = [dataAux(1:20250); nan(length(ind1),1); dataAux(20251:end)];
end
clear symDeintlv;

hest = reshape(hest_symDeintlv, C_DATA*numSymb, 1);
if(~DVBT2.TX.FBUILD.ENABLE && N_P2 > 0)
%%% Consider the unused elements when recovering data back
    ind1 =find(isnan(hest_symDeintlv)); 
    hest(ind1) = [];   
    hest = [hest; nan(length(ind1),1)];
    % hest = [hest(1:20250); nan(length(ind1),1); hest(20251:end)];
end
clear hest_symDeintlv;

fprintf(FidLogFile,'\t\tSymbol de-interlv: %d de-interleaved symbols\n',... 
        numSymb);        

DataOut.data = dataAux.';

DataOut.h_est = hest.';