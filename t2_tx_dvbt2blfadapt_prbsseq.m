function Prbs = t2_tx_dvbt2blfadapt_prbsseq(DVBT2)


%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
C_PS        = DVBT2.STANDARD.C_PS;
EXTENDED    = DVBT2.EXTENDED;            % Extended BW mode
K_EXT       = DVBT2.STANDARD.K_EXT;      % Extra carriers each side in ext BW mode

%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

% Initialize variables
srBin = ones(1,11); % Shift register content
prbsBin = zeros(1,C_PS); % Initialize output

% Generates PRBS sequence
for n=1:C_PS + K_EXT;
  prbsBin(n) = srBin(11); % Output
  
  tran = xor(srBin(11), srBin(9)); % XOR bits 11 and 9
  srBin = [tran srBin(1:10)];
end

if EXTENDED
    Prbs = prbsBin(1:C_PS);
else
    Prbs = prbsBin(K_EXT+1:end);
end