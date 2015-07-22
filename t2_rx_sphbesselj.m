function js = t2_rx_sphbesselj(DVBT2, FidLogFile,nu,x)
%------------------------------------------------------------------------------
switch(nargin)
  case 4,
  otherwise,
    error('t2_rx_sphbesselj SYNTAX');
end
%------------------------------------------------------------------------------
%%%     Copyright: (c) Guoping TAN, 2014-2014
%%%
%%%    Compute the spherical Bessel function of the first kind
%%%
%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%     we implement: the source code is from the Internet
%%%     http://stackoverflow.com/posts/20525505/revisions
%%%

if isscalar(nu) && isscalar(x)
    js = 0;
elseif isscalar(nu)
    js = zeros(size(x));
    nu = js+nu;
else
    js = zeros(size(nu));
    x = js+x;
end
x0 = (abs(x) < realmin);
x0nult0 = (x0 & nu < 0);
x0nueq0 = (x0 & nu == 0);
js(x0nult0) = Inf;          % Re(Nu) < 0, X == 0
js(x0nueq0) = 1;            % Re(Nu) == 0, X == 0
i = ~x0nult0 & ~x0nueq0 & ~(x0 & nu > 0) & (abs(x) < realmax);
js(i) = sign(x(i)).*sqrt(pi./(2*x(i))).*besselj(nu(i)+0.5,x(i));
