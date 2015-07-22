function [s1, s2] = GenerateS1S2(DVBT2)
% Generate the S1 and S2 fields for the T2-frames

if DVBT2.MISO_ENABLED
    s1 = 1;
else
    s1 = 0;
end

if strcmp(DVBT2.PROFILE,'T2-LITE')
    s1 = s1+3;
end

if strcmp(DVBT2.PROFILE,'T2-BASE')
    
    switch DVBT2.MODE
     case '2k'
      s2=0;
     case '8k'
      if ~isempty(find([1/128 19/256 19/128] == DVBT2.GI_FRACTION, 1, 'first')) && ~strcmp(DVBT2.SPEC_VERSION,'1.0.1')
          s2 = 12;
      else
          s2=2;
      end
     case '4k'
      s2=4;
     case '1k'
      s2=6;
     case '16k'
      s2=8;
     case '32k'
      if ~isempty(find([1/128 19/256 19/128] == DVBT2.GI_FRACTION, 1, 'first')) && ~strcmp(DVBT2.SPEC_VERSION,'1.0.1')
          s2 = 14;
      else
          s2=10;
      end
    end
    
else % T2-LITE - these values to be confirmed
    switch DVBT2.MODE
     case '2k'
      s2=0;
     case '8k'
      if ~isempty(find([1/128 19/256 19/128] == DVBT2.GI_FRACTION, 1, 'first'))
          s2 = 12; % earlier draft had 6;
      else
          s2=2; % earlier draft had 4;
      end
     case '4k'
      s2=4; % earlier draft had 2;
     case '1k'
         error('1k not allowed in T2-LITE');
     case '16k'
         if ~isempty(find([1/128 19/256 19/128] == DVBT2.GI_FRACTION, 1, 'first'))
             s2 = 6; % earlier draft had 10;
         else
             s2 = 8;
         end

     case '32k'
         error('32k not allowed in T2-LITE');
    end
end

if DVBT2.FEF_ENABLED % FEF_ENABLED is the same as MIXED for this model (since there is always DVB-T2)
    s2 = s2 + 1;
end


end

