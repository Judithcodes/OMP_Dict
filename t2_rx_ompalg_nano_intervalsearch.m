function DataOut = t2_rx_ompalg_nano_intervalsearch(DVBT2, FidLogFile, loc1, dataCP, y, c_s1, x1_estimated, tau, fd, numSymb, index, type, K, L, p)

%------------------------------------------------------------------------------
switch(nargin)
  case 15,
  otherwise,
    error('t2_rx_dvbt2 interval search SYNTAX');
end

%------------------------------------------------------------------------------
SP_FNAME   = DVBT2.RX.SP_FDO;        % SP file
%------------------------------------------------------------------------------
global name0;
global DICTIONARY;
global time;

if p==1
        name0 = cellstr('');
        DICTIONARY = zeros(1024, numSymb);
end

k_10000n = ceil(K/10000);
t_gi = floor(K/1000);
band = 1*9;

if length(time)>0
else
    time = k_10000n;
end

[LEN0 NUM0] = size(y);
%------------------------------------------------------------------------------
  l_num = 1;
  k_num = length(time);
  dictionary = zeros(l_num*k_num,1,numSymb+1);
  iiii = 1;
  ll = 0;
  for kk = 0:(k_num-1) % Create time taps for 1000ns
      kk0 = time(kk+1) * 10/1;
      SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(kk0),'L',num2str(ll),'.mat');  
      pos = strcmp(name0,SPRX_FNAME);
      if isempty(find(pos,1))
      dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, kk0, ll); % generate dict
      dictionary(iiii,1,1:length(dict_element)) = dict_element;
      iiii = iiii + 1;
      name0(length(name0)+1) = cellstr(SPRX_FNAME);
      DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
      else
      dict_element(1,1:NUM0) = DICTIONARY(find(pos==1),1:NUM0);
      dictionary(iiii,1,1:NUM0) = dict_element;
      iiii = iiii + 1;
      end
  end % end of K taps

% Basic Matching Pursuit algorithm
% Initialization
r0 = y(1:numSymb);

% Calculate b0_j for L Doppler shifts
ratio = zeros(1,l_num*k_num);
b0_j = zeros(1,l_num*k_num);
b1_j = zeros(1,l_num*k_num);

for lll = 1:l_num*k_num
    c_j(1,1:numSymb) = dictionary(lll,1,1:numSymb);
if 1%isempty(find(lll==tau))
    if c_s1 == 0
        b0_j(lll) = single(r0*ctranspose(c_j));
        ratio(lll) = single(abs(b0_j(lll))^2/single(norm(c_j,2)^2));
    else
        b0_j(lll) = single(r0*ctranspose(c_j));
        for i0 = 1:length(x1_estimated)
        SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(tau(i0)),'L',num2str(fd(i0)),'.mat');
        pos = strcmp(name0,SPRX_FNAME);
        if isempty(find(pos,1))
            dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, tau(i0), fd(i0)); % generate dict
            name0(length(name0)+1) = cellstr(SPRX_FNAME);
            DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
            c_s10(1,1:numSymb) = dict_element(1:numSymb);
        else
            c_s10(1,1:numSymb) = DICTIONARY(find(pos==1),1:numSymb);
        end
        b0_j(lll) = b0_j(lll)-single(x1_estimated(i0)*single(c_s10*ctranspose(c_j)));
        end
        b1_j(lll) = b0_j(lll);
        ratio(lll) = single(abs(b1_j(lll))^2/single(norm(c_j,2)^2));
    end
end
end

% argmax function
ratio_max = max(ratio);
s1_10000n = (find(ratio == ratio_max)-1)*10*1;
s1_10000n = s1_10000n(1);
    
% +++++++++++++++++++++++++++++++
% Here we search for 1000 nano sec
  l_num = 1;
  C = cellstr('');
  iiii = 1;
  ll = 0;
  if s1_10000n==0
      start = 0;
  else
      start = -band;%-((s1_1000n-1)*10-1);%
  end
  if s1_10000n==k_10000n*10
      endd = 0;
  else
      def_et = t_gi-s1_10000n*10;
      if def_et > band
          endd = band;%(k_1000n-(s1_1000n-1))*10-1;%
      else
          endd = def_et;%(k_1000n-(s1_1000n-1))*10-1;%
      end
  end
  k_num = abs(start)+abs(endd) + 1;
  tau_here = zeros(1,k_num);
  dictionary = zeros(l_num*k_num,1,numSymb+1);
  for kk = start:endd % Create time taps for 100ns     
      kk0 = s1_10000n + kk;
      tau_here(iiii) = kk0;
      SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(kk0),'L',num2str(ll),'.mat');  
      pos = strcmp(name0,SPRX_FNAME);
      if isempty(find(pos,1))
      dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, kk0, ll); % generate dict
      dictionary(iiii,1,1:length(dict_element)) = dict_element;
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      name0(length(name0)+1) = cellstr(SPRX_FNAME);
      DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
      else
      dict_element(1,1:NUM0) = DICTIONARY(find(pos==1),1:NUM0);
      dictionary(iiii,1,1:NUM0) = dict_element;
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      end
  end % end of K tap
  
% Calculate b0_j for L Doppler shifts
ratio = zeros(1,l_num*k_num);
b0_j = zeros(1,l_num*k_num);
b1_j = zeros(1,l_num*k_num);

for lll = 1:l_num*k_num
if 1%isempty(find(tau_here(lll)==tau))
    c_j(1,1:numSymb) = dictionary(lll,1,1:numSymb);
    if c_s1 == 0
        b0_j(lll) = single(r0*ctranspose(c_j));
        ratio(lll) = single(abs(b0_j(lll))^2/single(norm(c_j,2)^2));
    else
        b0_j(lll) = single(r0*ctranspose(c_j));
        for i0 = 1:length(x1_estimated)
        SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(tau(i0)),'L',num2str(fd(i0)),'.mat');
        pos = strcmp(name0,SPRX_FNAME);
        if isempty(find(pos,1))
            dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, tau(i0), fd(i0)); % generate dict
            name0(length(name0)+1) = cellstr(SPRX_FNAME);
            DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
            c_s10(1,1:numSymb) = dict_element(1:numSymb);
        else
            c_s10(1,1:numSymb) = DICTIONARY(find(pos==1),1:numSymb);
        end
        b0_j(lll) = b0_j(lll)-single(x1_estimated(i0)*single(c_s10*ctranspose(c_j)));
        end
        b1_j(lll) = b0_j(lll);
        ratio(lll) = single(abs(b1_j(lll))^2/single(norm(c_j,2)^2));
    end
end
end
% argmax function
ratio_max = max(ratio);
s = C(find(ratio_max==ratio)+1);
s = s{1};
pos1 = strfind(s,'K');
pos2 = strfind(s,'L');
s1_1000n = str2num(s(pos1+1:pos2-1));
s1_1000n = s1_1000n(1);

% +++++++++++++++++++++++++++++++
% Here we search for 100 nano sec
  l_num = 1;
  C = cellstr('');
  iiii = 1;
  ll = 0;
  if s1_1000n==0
      start = 0;
  else
      start = -(band+9*2);
      %if (band+9)/10>s1_1000n start=-(floor(s1_1000n*10)-1); else start = -(band+9); end%-((s1_1000n-1)*10-1);%
  end
  if s1_1000n==t_gi
      endd = 0;
  else
      endd = (band+9*2);
      %if (band+9)>t_gi endd = t_gi; else endd = (band+9); end
  end
  k_num = abs(start)+abs(endd) + 1;
  tau_here = zeros(1,k_num);
  dictionary = zeros(l_num*k_num,1,numSymb+1);
  for kk = start:endd % Create time taps for 100ns     
      kk0 = s1_1000n + kk/10;
      tau_here(iiii) = kk0;
      SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(kk0),'L',num2str(ll),'.mat');  
      pos = strcmp(name0,SPRX_FNAME);
      if isempty(find(pos,1))
      dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, kk0, ll); % generate dict
      dictionary(iiii,1,1:length(dict_element)) = dict_element;
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      name0(length(name0)+1) = cellstr(SPRX_FNAME);
      DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
      else
      dict_element(1,1:NUM0) = DICTIONARY(find(pos==1),1:NUM0);
      dictionary(iiii,1,1:NUM0) = dict_element(1:NUM0);
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      end
  end % end of K tap
  
  % Calculate b0_j for L Doppler shifts
ratio = zeros(1,l_num*k_num);
b0_j = zeros(1,l_num*k_num);
b1_j = zeros(1,l_num*k_num);

for lll = 1:l_num*k_num
if 1%isempty(find(tau_here(lll)==tau))
    c_j(1,1:numSymb) = dictionary(lll,1,1:numSymb);
    if c_s1 == 0
        b0_j(lll) = single(r0*ctranspose(c_j));
        ratio(lll) = single(abs(b0_j(lll))^2/single(norm(c_j,2)^2));
    else
        b0_j(lll) = single(r0*ctranspose(c_j));
        for i0 = 1:length(x1_estimated)
        SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(tau(i0)),'L',num2str(fd(i0)),'.mat');
        pos = strcmp(name0,SPRX_FNAME);
        if isempty(find(pos,1))
            dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, tau(i0), fd(i0)); % generate dict
            name0(length(name0)+1) = cellstr(SPRX_FNAME);
            DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
            c_s10(1,1:numSymb) = dict_element(1:numSymb);
        else
            c_s10(1,1:numSymb) = DICTIONARY(find(pos==1),1:numSymb);
        end
        b0_j(lll) = b0_j(lll)-single(x1_estimated(i0)*single(c_s10*ctranspose(c_j)));
        end
        b1_j(lll) = b0_j(lll);
        ratio(lll) = single(abs(b1_j(lll))^2/single(norm(c_j,2)^2));
    end
end
end
% argmax function
ratio_max = max(ratio);
s = C(find(ratio_max==ratio)+1);
s = s{1};
pos1 = strfind(s,'K');
pos2 = strfind(s,'L');
s1_100n = str2num(s(pos1+1:pos2-1));
s1_100n = s1_100n(1);
%plot(tau_here,ratio)

%%{
% +++++++++++++++++++++++++++++++
% Here we search for 10 nano sec
  l_num = 1;
  C = cellstr('');
  iiii = 1;
  ll = 0;
  if s1_100n==0
      start = 0;
  else
      start = -(band + 0);
  end
  if s1_100n==t_gi
      endd = 0;
  else
      endd = (band + 0);
  end
  k_num = abs(start)+abs(endd) + 1;
  tau_here = zeros(1,k_num);
  dictionary = zeros(l_num*k_num,1,numSymb+1);
  for kk = start:endd % Create time taps for 10ns
      kk0 = s1_100n + kk/100;
      tau_here(iiii) = kk0;
      SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(kk0),'L',num2str(ll),'.mat');  
      pos = strcmp(name0,SPRX_FNAME);
      if isempty(find(pos,1))
      dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, kk0, ll); % generate dict
      dictionary(iiii,1,1:length(dict_element)) = dict_element;
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      name0(length(name0)+1) = cellstr(SPRX_FNAME);
      DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
      else
      dict_element(1,1:NUM0) = DICTIONARY(find(pos==1),1:NUM0);
      dictionary(iiii,1,1:NUM0) = dict_element(1:NUM0);
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      end
  end % end of K tap
  
% Calculate b0_j for L Doppler shifts
ratio = zeros(1,l_num*k_num);
b0_j = zeros(1,l_num*k_num);
b1_j = zeros(1,l_num*k_num);

for lll = 1:l_num*k_num
if 1%isempty(find(tau_here(lll)==tau))
    c_j(1,1:numSymb) = dictionary(lll,1,1:numSymb);
    if c_s1 ==0
        b0_j(lll) = single(r0*ctranspose(c_j));
        ratio(lll) = single(abs(b0_j(lll))^2/single(norm(c_j,2)^2));
    else
        b0_j(lll) = single(r0*ctranspose(c_j));
        for i0 = 1:length(x1_estimated)
        SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(tau(i0)),'L',num2str(fd(i0)),'.mat');
        pos = strcmp(name0,SPRX_FNAME);
        if isempty(find(pos,1))
            dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, tau(i0), fd(i0)); % generate dict
            name0(length(name0)+1) = cellstr(SPRX_FNAME);
            DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
            c_s10(1,1:numSymb) = dict_element(1:numSymb);
        else
            c_s10(1,1:numSymb) = DICTIONARY(find(pos==1),1:numSymb);
        end
        b0_j(lll) = b0_j(lll)-single(x1_estimated(i0)*single(c_s10*ctranspose(c_j)));
        end
        b1_j(lll) = b0_j(lll);
        ratio(lll) = single(abs(b1_j(lll))^2/single(norm(c_j,2)^2));
    end
end
end

% argmax function
ratio_max = max(ratio);
s = C(find(ratio_max==ratio)+1);
s = s{1};
pos1 = strfind(s,'K');
pos2 = strfind(s,'L');
s1_10n = str2num(s(pos1+1:pos2-1));
s1_10n = s1_10n(1);
%}

%%{
% Here we search for nano sec
  l_num = 1;
  C = cellstr('');
  iiii = 1;
  ll = 0;
  if (s1_10n)==0
      start = 0;
  else
      start = -band;
  end
  if s1_10n==t_gi
      endd = 0;
  else
      endd = band;
  end
  k_num = abs(start)+abs(endd) + 1;
  tau_here = zeros(1,k_num);
  dictionary = zeros(l_num*k_num,1,numSymb+1);
  for kk = start:endd % Create time taps for 1ns
      kk0 = s1_10n + kk/1000;
      tau_here(iiii) = kk0;
      SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(kk0),'L',num2str(ll),'.mat');   
      pos = strcmp(name0,SPRX_FNAME);
      if isempty(find(pos,1))
      dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, kk0, ll); % generate dict
      dictionary(iiii,1,1:length(dict_element)) = dict_element;
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      name0(length(name0)+1) = cellstr(SPRX_FNAME);
      DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
      else
      dict_element(1,1:NUM0) = DICTIONARY(find(pos==1),1:NUM0);
      dictionary(iiii,1,1:NUM0) = dict_element(1:NUM0);
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      end
  end % end of K tap
% Calculate b0_j for L Doppler shifts
ratio = zeros(1,l_num*k_num);
b0_j = zeros(1,l_num*k_num);
b1_j = zeros(1,l_num*k_num);

for lll = 1:l_num*k_num
if 1%isempty(find(tau_here(lll)==tau))
    c_j(1,1:numSymb) = dictionary(lll,1,1:numSymb);
    if c_s1 == 0
        b0_j(lll) = single(r0*ctranspose(c_j));
        ratio(lll) = single(abs(b0_j(lll))^2/single(norm(c_j,2)^2));
    else
        b0_j(lll) = single(r0*ctranspose(c_j));
        for i0 = 1:length(x1_estimated)
        SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(tau(i0)),'L',num2str(fd(i0)),'.mat');
        pos = strcmp(name0,SPRX_FNAME);
        if isempty(find(pos,1))
            dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, tau(i0), fd(i0)); % generate dict
            name0(length(name0)+1) = cellstr(SPRX_FNAME);
            DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
            c_s10(1,1:numSymb) = dict_element(1:numSymb);
        else
            c_s10(1,1:numSymb) = DICTIONARY(find(pos==1),1:numSymb);
        end
        b0_j(lll) = b0_j(lll)-single(x1_estimated(i0)*single(c_s10*ctranspose(c_j)));
        end
        b1_j(lll) = b0_j(lll);
        ratio(lll) = single(abs(b1_j(lll))^2/single(norm(c_j,2)^2));
    end
end
end
% argmax function
norm_ratio = norm(ratio,2);
ratio_max = max(ratio);
s = C(find(ratio_max==ratio)+1);
s = s{1};
pos1 = strfind(s,'K');
pos2 = strfind(s,'L');
s1_1n = str2num(s(pos1+1:pos2-1));
s1_1n = s1_1n(1);
%}
% +++++++++++++++++++++++++++++++
% +++++++++++++++++++++++++++++++
% +++++++++++++++++++++++++++++++
% Here we search for 1000 DS
  band_d = 1;
  l_num = ceil(L/1000);
  k_num = 1;
  dictionary = zeros(l_num*k_num,1,numSymb+1);
  iiii = 1;
  fd_here = zeros(1,l_num);
  for ll = 0:(l_num-1)
  %for ll = -(l_num-1):(l_num-1)
      kk0 = s1_1n;
      ll0 = ll*1000;
      fd_here(iiii) = ll0;
      SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(kk0),'L',num2str(ll0),'.mat');       
      pos = strcmp(name0,SPRX_FNAME);
      if isempty(find(pos,1))
      dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, kk0, ll0); % generate dict
      dictionary(iiii,1,1:length(dict_element)) = dict_element;
      name0(length(name0)+1) = cellstr(SPRX_FNAME);
      DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
      iiii = iiii + 1;
      else
      dict_element(1,1:NUM0) = DICTIONARY(find(pos==1),1:NUM0);
      dictionary(iiii,1,1:NUM0) = dict_element(1:NUM0);
      iiii = iiii + 1;
      end
  end % end of K tap
  
% Calculate b0_j for L Doppler shifts
ratio = zeros(1,l_num*k_num);
b0_j = zeros(1,l_num*k_num);
b1_j = zeros(1,l_num*k_num);

for lll = 1:l_num*k_num
    tau_fp = find(s1_1n==tau);
if isempty(find(fd_here(lll)==fd(tau_fp)))
    c_j(1,1:numSymb) = dictionary(lll,1,1:numSymb);
    if c_s1 == 0
        b0_j(lll) = single(r0*ctranspose(c_j));
        ratio(lll) = single(abs(b0_j(lll))^2/single(norm(c_j,2)^2));
    else
        b0_j(lll) = single(r0*ctranspose(c_j));
        for i0 = 1:length(x1_estimated)   
        SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(tau(i0)),'L',num2str(fd(i0)),'.mat');
        pos = strcmp(name0,SPRX_FNAME);
        if isempty(find(pos,1))
            dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, tau(i0), fd(i0)); % generate dict
            name0(length(name0)+1) = cellstr(SPRX_FNAME);
            DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
            c_s10(1,1:numSymb) = dict_element(1:numSymb);
        else
            c_s10(1,1:numSymb) = DICTIONARY(find(pos==1),1:numSymb);
        end 
        b0_j(lll) = b0_j(lll)-single(x1_estimated(i0)*single(c_s10*ctranspose(c_j)));
        end
        b1_j(lll) = b0_j(lll);
        ratio(lll) = single(abs(b1_j(lll))^2/single(norm(c_j,2)^2));
    end
end
end

% argmax function
%ratio.'
ratio_max = max(ratio);
f = find(ratio_max==ratio);
s1_ds1000 = (f(1)-1)*1000;

% -------------------------------------------------------------------------
% Here we search for 100 DS
  k_num = 1;
  C = cellstr('');
  iiii = 1;
  if (s1_ds1000)==0
      start = 0;
      %start = -band_d;
  else
      start = -band_d;
  end
  if s1_ds1000==l_num*1000 || s1_ds1000 > L
      s1_ds1000 = L; endd = 0;
  else
      endd = floor(abs(L - s1_ds1000)/100); if endd > band_d endd = band_d; end
  end
  l_num = abs(start)+abs(endd) + 1;
  fd_here = zeros(1,l_num);
  dictionary = zeros(l_num*k_num,1,numSymb+1);
  for ll = start:endd % Create time taps for 1ns
      kk0 = s1_1n;
      ll0 = s1_ds1000 + ll*100;
      fd_here(iiii) = ll0;
      %%{
      SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(kk0),'L',num2str(ll0),'.mat');     
      pos = strcmp(name0,SPRX_FNAME);
      if isempty(find(pos,1))
      dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, kk0, ll0); % generate dict
      dictionary(iiii,1,1:length(dict_element)) = dict_element;
      name0(length(name0)+1) = cellstr(SPRX_FNAME);
      DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      else
      dict_element(1,1:NUM0) = DICTIONARY(find(pos==1),1:NUM0);
      dictionary(iiii,1,1:NUM0) = dict_element(1:NUM0);
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      end
      %}
  end % end of K tap
  
% Calculate b0_j for L Doppler shifts
ratio = zeros(1,l_num*k_num);
x1_est = zeros(1,l_num*k_num);
b0_j = zeros(1,l_num*k_num);
b1_j = zeros(1,l_num*k_num);

for lll = 1:l_num*k_num
    tau_fp = find(s1_1n==tau);
if isempty(find(fd_here(lll)==fd(tau_fp)))
    c_j(1,1:numSymb) = dictionary(lll,1,1:numSymb);
    if c_s1 ==0
        b0_j(lll) = single(r0*ctranspose(c_j));
        ratio(lll) = single(abs(b0_j(lll))^2/single(norm(c_j,2)^2));
    else
        b0_j(lll) = single(r0*ctranspose(c_j));
        for i0 = 1:length(x1_estimated)  
        SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(tau(i0)),'L',num2str(fd(i0)),'.mat');
        pos = strcmp(name0,SPRX_FNAME);
        if isempty(find(pos,1))
            dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, tau(i0), fd(i0)); % generate dict
            name0(length(name0)+1) = cellstr(SPRX_FNAME);
            DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
            c_s10(1,1:numSymb) = dict_element(1:numSymb);
        else
            c_s10(1,1:numSymb) = DICTIONARY(find(pos==1),1:numSymb);
        end 
        b0_j(lll) = b0_j(lll)-single(x1_estimated(i0)*single(c_s10*ctranspose(c_j)));
        end
        b1_j(lll) = b0_j(lll);
        ratio(lll) = single(abs(b1_j(lll))^2/single(norm(c_j,2)^2));
        x1_est(lll) = single(b1_j(lll)/norm(c_j,2)^2);
    end
end
end

% argmax function
%ratio.'
ratio_max = max(ratio);
f = find(ratio_max==ratio);
s = C(f(1)+1);
s = s{1};
pos2 = strfind(s,'L');
pos3 = strfind(s,'.mat');
s1_ds100 = str2num(s(pos2+1:pos3));

% -------------------------------------------------------------------------
% Here we search for 10 DS
  k_num = 1;
  C = cellstr('');
  iiii = 1;
  if s1_ds100==0
      start = 0;
      %start = -band_d;
  else
      start = -band_d;
  end
  if s1_ds100 > (L-band_d*10)% || s1_ds100 > L
      endd = 0;
  else
      endd = floor(abs(L - s1_ds100)/10); if endd > band_d endd = band_d; end
  end
  l_num = abs(start)+abs(endd) + 1;
  fd_here = zeros(1,l_num);
  dictionary = zeros(l_num*k_num,1,numSymb+1);
  for ll = start:endd % Create time taps for 1ns
      kk0 = s1_1n;
      ll0 = s1_ds100 + ll*10;
      fd_here(iiii) = ll0;
      SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(kk0),'L',num2str(ll0),'.mat');     
      pos = strcmp(name0,SPRX_FNAME);
      if isempty(find(pos,1))
      dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, kk0, ll0); % generate dict
      dictionary(iiii,1,1:length(dict_element)) = dict_element;
      name0(length(name0)+1) = cellstr(SPRX_FNAME);
      DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      else
      dict_element(1,1:NUM0) = DICTIONARY(find(pos==1),1:NUM0);
      dictionary(iiii,1,1:NUM0) = dict_element(1:NUM0);
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      end
  end % end of K tap
  
% Calculate b0_j for L Doppler shifts
ratio = zeros(1,l_num*k_num);
x1_est = zeros(1,l_num*k_num);
b0_j = zeros(1,l_num*k_num);
b1_j = zeros(1,l_num*k_num);

for lll = 1:l_num*k_num
    tau_fp = find(s1_1n==tau);
if isempty(find(fd_here(lll)==fd(tau_fp)))
    c_j(1,1:numSymb) = dictionary(lll,1,1:numSymb);
    if c_s1 ==0
        b0_j(lll) = single(r0*ctranspose(c_j));
        ratio(lll) = single(abs(b0_j(lll))^2/single(norm(c_j,2)^2));
    else
        b0_j(lll) = single(r0*ctranspose(c_j));
        for i0 = 1:length(x1_estimated)  
        SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(tau(i0)),'L',num2str(fd(i0)),'.mat');
        pos = strcmp(name0,SPRX_FNAME);
        if isempty(find(pos,1))
            dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, tau(i0), fd(i0)); % generate dict
            name0(length(name0)+1) = cellstr(SPRX_FNAME);
            DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
            c_s10(1,1:numSymb) = dict_element(1:numSymb);
        else
            c_s10(1,1:numSymb) = DICTIONARY(find(pos==1),1:numSymb);
        end 
        b0_j(lll) = b0_j(lll)-single(x1_estimated(i0)*single(c_s10*ctranspose(c_j)));
        end
        b1_j(lll) = b0_j(lll);
        ratio(lll) = single(abs(b1_j(lll))^2/single(norm(c_j,2)^2));
        x1_est(lll) = single(b1_j(lll)/norm(c_j,2)^2);
    end
end
end

% argmax function
%ratio.'
ratio_max = max(ratio);
f = find(ratio_max==ratio);
s = C(f(1)+1);
s = s{1};
pos2 = strfind(s,'L');
pos3 = strfind(s,'.mat');
s1_ds10 = str2num(s(pos2+1:pos3));

% +++++++++++++++++++++++++++++++
% Here we search for last DS
  k_num = 1;
  C = cellstr('');
  iiii = 1;
  if (s1_ds10)==0
      start = 0;
      %start = -band_d;
  else
      start = -band_d;
  end
  if s1_ds10==(l_num)*1000 || s1_ds10 > L
      endd = 0;
  else
      endd = floor(abs(L - s1_ds10)/1); if endd > band_d endd = band_d; end
  end
  l_num = abs(start)+abs(endd) + 1;
  fd_here = zeros(1,l_num);
  dictionary = zeros(l_num*k_num,1,numSymb+1);
  for ll = start:endd % Create time taps for 1ns
      kk0 = s1_1n;
      ll0 = s1_ds10 + ll;
      fd_here(iiii) = ll0;
      SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(kk0),'L',num2str(ll0),'.mat');     
      pos = strcmp(name0,SPRX_FNAME);
      if isempty(find(pos,1))
      dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, kk0, ll0); % generate dict
      dictionary(iiii,1,1:length(dict_element)) = dict_element;
      name0(length(name0)+1) = cellstr(SPRX_FNAME);
      DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      else
      dict_element(1,1:NUM0) = DICTIONARY(find(pos==1),1:NUM0);
      dictionary(iiii,1,1:NUM0) = dict_element(1:NUM0);
      C(length(C)+1) = cellstr(SPRX_FNAME);
      iiii = iiii + 1;
      end
  end % end of K tap
  
% Calculate b0_j for L Doppler shifts
ratio = zeros(1,l_num*k_num);
x1_est = zeros(1,l_num*k_num);
b0_j = zeros(1,l_num*k_num);
b1_j = zeros(1,l_num*k_num);

for lll = 1:l_num*k_num
    tau_fp = find(s1_1n==tau);
if isempty(find(fd_here(lll)==fd(tau_fp)))
    c_j(1,1:numSymb) = dictionary(lll,1,1:numSymb);
    if c_s1 ==0
        b0_j(lll) = single(r0*ctranspose(c_j));
        ratio(lll) = single(abs(b0_j(lll))^2/single(norm(c_j,2)^2));
    else
        b0_j(lll) = single(r0*ctranspose(c_j));
        for i0 = 1:length(x1_estimated)  
        SPRX_FNAME = strcat(SP_FNAME, 'K', num2str(tau(i0)),'L',num2str(fd(i0)),'.mat');
        pos = strcmp(name0,SPRX_FNAME);
        if isempty(find(pos,1))
            dict_element = t2_rx_dict_tubs(DVBT2, FidLogFile, loc1,dataCP, index, type, tau(i0), fd(i0)); % generate dict
            name0(length(name0)+1) = cellstr(SPRX_FNAME);
            DICTIONARY(length(name0),1:length(dict_element)) = dict_element;
            c_s10(1,1:numSymb) = dict_element(1:numSymb);
        else
            c_s10(1,1:numSymb) = DICTIONARY(find(pos==1),1:numSymb);
        end 
        b0_j(lll) = b0_j(lll)-single(x1_estimated(i0)*single(c_s10*ctranspose(c_j)));
        end
        b1_j(lll) = b0_j(lll);
        ratio(lll) = single(abs(b1_j(lll))^2/single(norm(c_j,2)^2));
        x1_est(lll) = single(b1_j(lll)/norm(c_j,2)^2);
    end
end
end

% argmax function
%ratio.'
ratio_max = max(ratio);
f = find(ratio_max==ratio);
s = C(f(1)+1);
s = s{1};
pos2 = strfind(s,'L');
pos3 = strfind(s,'.mat');
s1_ds1 = str2num(s(pos2+1:pos3));

%DataOut = [s1_1n s1_ds1 ratio_max x1_est(f)];
DataOut = [s1_1n s1_ds1 ratio_max];
