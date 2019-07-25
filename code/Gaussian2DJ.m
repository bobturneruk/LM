function [F, J] = Gaussian2DJ(p,xdata)

% This file is part of LM.
% 
% LM is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% Foobar is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with LM.  If not, see <http://www.gnu.org/licenses/>.

%This is the Gaussian function to which the pattern of light emitted from a
%single molecule is fitted. It includes a Jacobian matrix to improve the
%efficiency of fitting.

a=p(1);
b=p(2);
c=p(3);
d=p(4);
e=p(5);
f=p(6);

x=xdata(:,1);
y=xdata(:,2);

%Gaussian

F = (a.*exp(-1.*((((x-b)/c).^2)+((y-d)/e).^2)))+f;

%Jacobian

Ja=exp(- (b - x).^2/c.^2 - (d - y).^2/e.^2);
Jb=-(a.*exp(- (b - x).^2/c.^2 - (d - y).^2/e.^2).*(2.*b - 2.*x))/c.^2;
Jc=(2.*a.*exp(- (b - x).^2/c.^2 - (d - y).^2/e.^2).*(b - x).^2)/c.^3;
Jd=-(a.*exp(- (b - x).^2/c.^2 - (d - y).^2/e.^2).*(2.*d - 2.*y))/e.^2;
Je=(2.*a.*exp(- (b - x).^2/c.^2 - (d - y).^2/e.^2).*(d - y).^2)/e.^3;
Jf(1:size(xdata,1),1)=1;


J = [Ja, Jb, Jc, Jd, Je, Jf];


end