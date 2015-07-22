function DataOut = t2_tx_dvbt2bldatagen(DVBT2, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    FidLogFile = 1; % Standard output
  case 2,
  otherwise,
    error('t2_tx_dvbt2bldatagen SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
SEED       = DVBT2.TX.DATAGEN.SEED;     % Random seed
NUM_PLPS   = DVBT2.NUM_PLPS;

%------------------------------------------------------------------------------
% PLP Loop
%------------------------------------------------------------------------------

for plp = 1:NUM_PLPS
    %------------------------------------------------------------------------------
    % PLP-specific Parameters Definition
    %------------------------------------------------------------------------------
    START_INT_FRAME = DVBT2.STANDARD.PLP(plp).START_INT_FRAME; % First Interleaving Frame to generate
    NUM_INT_FRAMES = DVBT2.STANDARD.PLP(plp).NUM_INT_FRAMES; % Number of Interleving Frames to generate (may be zero)
    NBLOCKS = DVBT2.PLP(plp).NBLOCKS(START_INT_FRAME+1:START_INT_FRAME+NUM_INT_FRAMES); % #FEC blocks in each I/L frame
    NUM_FBLOCK = sum(NBLOCKS); % Total number of FEC blocks to generate
    CR         = DVBT2.STANDARD.PLP(plp).ICOD.CR;    % Coding rate
    FECLEN     = DVBT2.PLP(plp).FECLEN;              %the inner fec length

    %------------------------------------------------------------------------------
    % Procedure
    %------------------------------------------------------------------------------
   
    numBytes = ceil(FECLEN*CR*NUM_FBLOCK/8);

    % Generate random data
    %data = randint(numBytes, 1, 256, SEED); % Stream
    SEED = 0;

    fprintf(FidLogFile,'\t\t%d SEED is: \n', SEED);

    data = randint(numBytes, 1, 256, SEED); % Stream
    fprintf(FidLogFile,'\t\t%d Bytes generated\n', numBytes);

    DataOut{plp} = data;
end