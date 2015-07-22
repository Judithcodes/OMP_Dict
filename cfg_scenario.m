function scenario = cfg_scenario()


%---------------------------------------------
%Define Scenarios


%                  --Mod-----Cod.Rate-----Initial SNR ----Noise------ChE----
Test_scenario =   {'QPSK'    '2/3'           2.9        'AWGN'    'Ideal'};


%                  --Mod-----Cod.Rate-----Initial SNR----Noise-----
AWGN_scenario     = {

%                     'QPSK'     '1/2'   0.9  'AWGN'  'Ideal'; %     
%                     'QPSK'     '3/5'   2.1  'AWGN'  'Ideal';    
%                     'QPSK'     '2/3'   2.9  'AWGN'  'Ideal';      
%                     'QPSK'     '3/4'   3.9  'AWGN'  'Ideal';      
%                     'QPSK'     '4/5'   4.5  'AWGN'  'Ideal';     
%                     'QPSK'     '5/6'   5.0  'AWGN'  'Ideal';      
                    
                     %'16-QAM'   '1/2'   5.7  'AWGN'  'Ideal'; %    
%                     '16-QAM'   '3/5'   7.4  'AWGN'  'Ideal';     
%                     '16-QAM'   '2/3'   8.6  'AWGN'  'Ideal';      
%                     '16-QAM'   '3/4'   9.8  'AWGN'  'Ideal';      
%                     '16-QAM'   '4/5'  10.6  'AWGN'  'Ideal'; 
%                     '16-QAM'   '5/6'  11.2  'AWGN'  'Ideal';   
                                       
                     %'64-QAM'    '1/2'  9.6  'AWGN'  'Ideal';  
                     %'64-QAM'    '3/5' 11.7  'AWGN'  'Ideal'; 
                     %'64-QAM'    '2/3' 13.2  'AWGN'  'Ideal';   
                     %'64-QAM'    '3/4' 14.9  'AWGN'  'Ideal'; 
                     %'64-QAM'    '4/5' 15.9  'AWGN'  'Ideal'; 
                     %'64-QAM'    '5/6' 16.6  'AWGN'  'Ideal';   
                                      
                     %'256-QAM'   '1/2' 12.8  'AWGN'  'Ideal';
                     %'256-QAM'   '3/5' 15.6  'AWGN'  'Ideal';  
                     %'256-QAM'   '2/3' 17.5  'AWGN'  'Ideal';   
                     %'256-QAM'   '3/4' 19.7  'AWGN'  'Ideal';   
                     %'256-QAM'   '4/5' 21.1  'AWGN'  'Ideal';  
                     %'256-QAM'   '5/6' 21.8  'AWGN'  'Ideal';
                     };

F1_scenario     = {
%                     'QPSK'     '1/2'   1.0  'DVBT-F'  'Ideal'; %     
%                     'QPSK'     '3/5'   2.4  'DVBT-F'  'Ideal';    
%                     'QPSK'     '2/3'   3.3  'DVBT-F'  'Ideal';      
%                     'QPSK'     '3/4'   4.3  'DVBT-F'  'Ideal';      
%                     'QPSK'     '4/5'   5.0  'DVBT-F'  'Ideal';     
%                     'QPSK'     '5/6'   5.6  'DVBT-F'  'Ideal';      
                                                    
%                     '16-QAM'   '1/2'   6.1  'DVBT-F'  'Ideal'; %    
%                     '16-QAM'   '3/5'   7.7  'DVBT-F'  'Ideal';     
%                     '16-QAM'   '2/3'   8.9  'DVBT-F'  'Ideal';      
%                     '16-QAM'   '3/4'  10.3  'DVBT-F'  'Ideal';      
%                     '16-QAM'   '4/5'  11.1  'DVBT-F'  'Ideal'; 
%                     '16-QAM'   '5/6'  11.8  'DVBT-F'  'Ideal';   
                                                    
                     %'64-QAM'    '1/2' 10.0  'DVBT-F'  'Ideal';  
                     %'64-QAM'    '3/5' 12.1  'DVBT-F'  'Ideal'; 
                     %'64-QAM'    '2/3' 13.6  'DVBT-F'  'Ideal';   
                     %'64-QAM'    '3/4' 15.3  'DVBT-F'  'Ideal'; 
                     %'64-QAM'    '4/5' 16.4  'DVBT-F'  'Ideal'; 
                     %'64-QAM'    '5/6' 17.2  'DVBT-F'  'Ideal';   
                                                    
%                     '256-QAM'   '1/2' 13.3  'DVBT-F'  'Ideal';
                     %'256-QAM'   '3/5' 16.0  'DVBT-F'  'Ideal';  
                     %'256-QAM'   '2/3' 17.8  'DVBT-F'  'Ideal';   
                     %'256-QAM'   '3/4' 20.2  'DVBT-F'  'Ideal';   
                     %'256-QAM'   '4/5' 21.5  'DVBT-F'  'Ideal';  
                     %'256-QAM'   '5/6' 22.3  'DVBT-F'  'Ideal';
                     };


P1_scenario     = {
%                     'QPSK'     '1/2'   1.8  'DVBT-P'  'Ideal'; %     
%                     'QPSK'     '3/5'   3.4  'DVBT-P'  'Ideal';    
%                     'QPSK'     '2/3'   4.6  'DVBT-P'  'Ideal';      
%                     'QPSK'     '3/4'   5.9  'DVBT-P'  'Ideal';      
%                     'QPSK'     '4/5'   6.8  'DVBT-P'  'Ideal';     
%                     'QPSK'     '5/6'   7.2  'DVBT-P'  'Ideal';      
                                               
                      '16-QAM'   '1/2'   7.3  'DVBT-P'  'Ideal'; %    
%                     '16-QAM'   '3/5'   9.1  'DVBT-P'  'Ideal';     
%                     '16-QAM'   '2/3'  10.5  'DVBT-P'  'Ideal';      
%                     '16-QAM'   '3/4'  12.2  'DVBT-P'  'Ideal';      
%                     '16-QAM'   '4/5'  13.4  'DVBT-P'  'Ideal'; 
%                     '16-QAM'   '5/6'  14.4  'DVBT-P'  'Ideal';   
                                               
                     %'64-QAM'    '1/2' 11.7  'DVBT-P'  'Ideal';  
                     %'64-QAM'    '3/5' 13.8  'DVBT-P'  'Ideal'; 
                     %'64-QAM'    '2/3' 15.4  'DVBT-P'  'Ideal';   
                     %'64-QAM'    '3/4' 17.5  'DVBT-P'  'Ideal'; 
                     %'64-QAM'    '4/5' 19.0  'DVBT-P'  'Ideal'; 
                     %'64-QAM'    '5/6' 19.9  'DVBT-P'  'Ideal';   
                                               
                     %'256-QAM'   '1/2' 15.4  'DVBT-P'  'Ideal';
                     %'256-QAM'   '3/5' 18.1  'DVBT-P'  'Ideal';  
                     %'256-QAM'   '2/3' 20.0  'DVBT-P'  'Ideal';   
                     %'256-QAM'   '3/4' 22.5  'DVBT-P'  'Ideal';   
                     %'256-QAM'   '4/5' 24.2  'DVBT-P'  'Ideal';  
                     %'256-QAM'   '5/6' 25.3  'DVBT-P'  'Ideal';
                     };


%----------------------------------------------

%Select scenario
%scenario = Test_scenario;
%scenario =  AWGN_scenario;
scenario =  P1_scenario;
%scenario =  F1_scenario;
