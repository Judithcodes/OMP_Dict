%*******************************************************************************
%* Copyright (c) 2011 AICIA, BBC, Pace, Panasonic, SIDSA
%* 
%* Permission is hereby granted, free of charge, to any person obtaining a copy
%* of this software and associated documentation files (the "Software"), to deal
%* in the Software without restriction, including without limitation the rights
%* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%* copies of the Software, and to permit persons to whom the Software is
%* furnished to do so, subject to the following conditions:
%*
%* The above copyright notice and this permission notice shall be included in
%* all copies or substantial portions of the Software.
%*
%* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%* THE SOFTWARE.
%* 
%* This notice contains a licence of copyright only and does not grant 
%* (implicitly or otherwise) any patent licence and no permission is given 
%* under this notice with regards to any third party intellectual property 
%* rights that might be used for the implementation of the Software.  
%*
%******************************************************************************
%* Project     : DVB-T2 Common Simulation Platform 
%* URL         : http://dvb-t2-csp.sourceforge.net
%* Date        : $Date$
%* Version     : $Revision$
%* Description : T2_CH_DVBTPSCEN_GETCH Channel Generation.
%*               [RO, TAU, PHI, FD] = T2_CH_DVBTPSCEN_GETCH(DVBT2) generates
%*               the channel attenuation, delay, phase, and doppler frequency
%*               for the echoes of a channel specified by the DVBT structure.
%*
%*               [RO, TAU, PHI, FD] = T2_CH_DVBTPSCEN_GETCH(DVBT2, RSEED) uses
%*               RSEED as an initial seed for the random number generator.
%*
%*               [RO, TAU, PHI, FD] = T2_CH_DVBTPSCEN_GETCH(DVBT2, RSEED, FID)
%*               specifies the file identifier in FID where any debug message
%*               is sent. 
%******************************************************************************

function ch = t2_ch_dvbtpscen_getch(DVBT2, Rseed, FidLogFile)

%------------------------------------------------------------------------------
% Input arguments checking
%------------------------------------------------------------------------------
switch(nargin)
  case 1,
    Rseed      = 0; % Random seed
    FidLogFile = 1; % Standard output
  case 2,        
    FidLogFile = 1; % Standard output
  case 3,          
    ;
  otherwise,
    error('t2_ch_dvbtpscen_getch SYNTAX');
end

%------------------------------------------------------------------------------
% Parameters Definition
%------------------------------------------------------------------------------
CHSTR = DVBT2.CH.PSCEN.CHSTR; % Channel structure 
MISO_ENABLED = DVBT2.MISO_ENABLED; % 1=MISO 0=SISO
%------------------------------------------------------------------------------
% Procedure
%------------------------------------------------------------------------------

chanType = CHSTR.TYPE;
chanType = upper(chanType);

ch.format = 'Paths'; % default
switch(chanType) 
  case 'AWGN'
    %[ch_name, ch.ro, ch.tau, ch.phi, ch.fd] = t2_ch_dvbtpscen_getch_awgn();
  case 'DVBT-F'  
    %[ch_name, ch.ro, ch.tau, ch.phi, ch.fd] = t2_ch_dvbtpscen_getch_dvbtf();
  case 'DVBT-P'
    [ch_name, ch.ro, ch.tau, ch.phi, ch.fd] = t2_ch_dvbtpscen_getch_dvbtp(DVBT2);
  case '0DBECHO'
    %[ch_name, ch.ro, ch.tau, ch.phi, ch.fd] = t2_ch_dvbtpscen_getch_0dBecho(DVBT2, Rseed); 
  case 'DTGSHORT'
    %[ch_name, ch.ro, ch.tau, ch.phi, ch.fd] = t2_ch_dvbtpscen_getch_dtgshort(); 
  case 'DTGLONG'
    %[ch_name, ch.ro, ch.tau, ch.phi, ch.fd] = t2_ch_dvbtpscen_getch_dtglong(); 
  case 'DTGMEDIUM'
    %[ch_name, ch.ro, ch.tau, ch.phi, ch.fd] = t2_ch_dvbtpscen_getch_dtgmedium();
  case 'TXFILTER'
    %[ch_name, ch.freq, ch.ampl, ch.phase] = t2_ch_dvbt2pscen_getch_txfilter(DVBT2);
    %ch.format = 'FreqResponse'; % default
  case 'DTG-II'
    %[ch_name, Ro, Tau, Phi, Fd] = t2_ch_dvbtpscen_getch_awgn();
        
    
  otherwise  
    error('Unknown propagation scenario %s', chanType);
end

if MISO_ENABLED    % MISO channels: return parameters in two columns
  switch(chanType)
      case 'AWGN'
        [ch_name, ch.ro(:,2), ch.tau(:,2), ch.phi(:,2), ch.fd(:,2)] = t2_ch_dvbtpscen_getch_awgn();
      case 'DVBT-F'  
        [ch_name, ch.ro(:,2), ch.tau(:,2), ch.phi(:,2), ch.fd(:,2)] = t2_ch_dvbtpscen_getch_dvbtf_misotx2();
      case 'DVBT-P'
        [ch_name, ch.ro(:,2), ch.tau(:,2), ch.phi(:,2), ch.fd(:,2)] = t2_ch_dvbtpscen_getch_dvbtp_misotx2();
      case 'DTG-II'
        [ch_name, Ro(:,2), Tau(:,2), Phi(:,2), Fd(:,2)] = t2_ch_dvbtpscen_getch_awgn();
      otherwise  
        error('Propagation scenario not defined for MISO: %s', chanType);
  end
end    
  
%------------------------------------------------------------------------------
% Display some info about the channel
%------------------------------------------------------------------------------
if strcmp(ch.format, 'Paths')
    meanDelayUS = mean(ch.tau(:));  % Mean delay
    delSpreadUS = std(ch.tau(:));   % Delay spread

    fprintf(FidLogFile,'\tInfo: Parameters of a %s channel\n', ch_name);
    fprintf(FidLogFile,'\t  Echo delay times:\n');
    fprintf(FidLogFile,'\t    - range :%6.2fus <= tau <= %6.2fus\n', ...
            min(ch.tau(:)), max(ch.tau(:)));
    fprintf(FidLogFile,'\t    - mean  :%6.2fus\n', meanDelayUS);
    fprintf(FidLogFile,'\t    - stddev:%6.2fus\n', delSpreadUS);
    fprintf(FidLogFile,'\t  Doppler Frequencies:\n');
    fprintf(FidLogFile,'\t    - range :  %g <= |fD| <= %g\n', min(abs(ch.fd(:))), ...
            max(abs(ch.fd(:))));
end
