/********************************************************************************
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
%* Description : DVBT2 Outer encoding MEX function
%******************************************************************************/

#include "mex.h"
#include "matrix.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

/*
 Syntax:
   result = function(data, poly)
 where
   data:   data array, of size [n m]
           m is the block size; n is the number of blocks
           first element has the highest power
   poly:   generator polynomial vector, of length k+1, with coefficients in descending order
           k is the degree of the polynomial
           first and last element must be logical 1
   result: computed remainder bits, of size [k m]
*/

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  /* input/output arguments */
  int N; /* number of data bits */
  int K; /* number of result bits */
  int M; /* numbr of blocks */
  bool* data;   /* input data bits */
  bool* poly;   /* generator polynomial */
  bool* result; /* remainder bits */
  
  int n, k, m; /* iterators */
  
  bool* reg; /* shift register */
  bool d;    /* temporary bit */
 
  if (nrhs != 2) {
    mexErrMsgTxt("??? Function takes 2 input arguments.");
  }
  if (nlhs != 1) {
    mexErrMsgTxt("??? Function takes 1 output argument.");
  }

  /* Input 1: data array */
  if (!mxIsLogical(prhs[0]) || mxGetNumberOfDimensions(prhs[0]) > 2) {
    mexErrMsgTxt("??? Input argument 1 (data) must be a logical 2D array.");
  }
  data = (bool*)mxGetData(prhs[0]);
  if (mxGetM(prhs[0])==1 || mxGetN(prhs[0])==1) { /* vector */
    N = mxGetM(prhs[0])*mxGetN(prhs[0]);
    M = 1;
  }
  else { /* 2D array */
    N = mxGetM(prhs[0]);
    M = mxGetN(prhs[0]);
  }
  /* Input 2: generator polynomial */
  if (!mxIsLogical(prhs[1]) || mxGetNumberOfDimensions(prhs[1]) > 2 || (mxGetM(prhs[1]) > 1 && mxGetN(prhs[1]) > 1)) {
    mexErrMsgTxt("??? Input argument 2 (poly) must be a logical vector.");
  }
  poly = (bool*)mxGetData(prhs[1]);
  K = mxGetM(prhs[1])*mxGetN(prhs[1])-1;
  if (poly[K]==0 || poly[0]==0) {
    mexErrMsgTxt("??? First and last element of the generator polynomial must be logical 1.");
  }
  reg = calloc(K, sizeof(bool)); /* allocate register vector */


  /* Output 1: result array */
  plhs[0] = mxCreateLogicalMatrix(K, M);
  result = (bool*)mxGetData(plhs[0]);

  /* for each data block */
  for (m = 0; m < M; m++) {
    /* initialize shift register */
    for (k = 0; k < K; k++) {
      reg[k] = 0;
    }
    /* for each input bit */
    for (n = 0; n < N; n++) {
      d = data[m*N+n] ^ reg[K-1];
      /* update shift register */
      for (k = K-1; k > 0; k--) {
        reg[k] = reg[k-1] ^ (d & poly[K-k]);
      }
      reg[0] = d;
    }
    /* the remainder is the reverse of the shift register */
    for (k = 0; k < K; k++) {
      result[m*K+k] = reg[K-k-1];
    }
  }
  
  free(reg); /* dellocate register vector */
}
