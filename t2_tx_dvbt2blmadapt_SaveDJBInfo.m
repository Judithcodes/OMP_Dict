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
%* Description : t2_tx_dvbt2blmadapt_SaveDJBInfo 
%*               Save information for use by the DJB model
%******************************************************************************

function t2_tx_dvbt2blmadapt_SaveDJBInfo(isNull, dflList, plp, ILFrameIndex, DVBT2)

    if ~DVBT2.SIM.EN_DJB_FILES
        return;
    end
    
    % Save sequence of null packets
    nullSequenceFilename = sprintf('%s/%s_NullSequence%d.txt', DVBT2.SIM.SIMDIR, DVBT2.SIM.VV_CONFIG_NAME, plp);
    
    if ILFrameIndex==0
        fid=fopen(nullSequenceFilename, 'w');
    else
        fid=fopen(nullSequenceFilename, 'a');
    end
    fprintf(fid, '%d',isNull);
    fclose(fid);

    % Save sequence of DFLs
    dflFilename = sprintf('%s/%s_dfl%d.mat', DVBT2.SIM.SIMDIR, DVBT2.SIM.VV_CONFIG_NAME, plp);
    
    if ILFrameIndex==0
        dflAll = [];
    else % recover dflAll from file and append
        load(dflFilename, 'dflAll');
    end
    
    dflAll = [dflAll dflList];

    save(dflFilename, 'dflAll');
end
