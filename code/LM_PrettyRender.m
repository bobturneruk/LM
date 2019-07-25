function [ pretty ] = LM_PrettyRender( fits, camera_pixel, render_pixel)
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

    %renders with nice blurry effect

    channel=9;
    
    scale_factor=camera_pixel/render_pixel;
    
    xy_max=max([max(fits(:,2)) max(fits(:,4))]);  
        
    sumimg=zeros(ceil(scale_factor*xy_max),ceil(scale_factor*xy_max));
    peakimg=sumimg;
    chanimg=sumimg;

    for i=1:size(fits,1)
        peakimg(round(scale_factor*fits(i,4)),round(scale_factor*fits(i,2)))=10;
        sumimg(round(scale_factor*fits(i,4)),round(scale_factor*fits(i,2)))=sumimg(round(scale_factor*fits(i,4)),round(scale_factor*fits(i,2)))+10;
        chanimg(round(scale_factor*fits(i,4)),round(scale_factor*fits(i,2)))=fits(i,channel)+1000;
    end
    
    h = fspecial('gaussian', 10, 5);
    pretty_sum=imfilter(uint16(sumimg*1000),h);
    pretty_chan=imfilter(uint16(chanimg*1000),h);
    
    pretty=uint16(pretty_sum);
    
    imagesc(pretty)
    %set 1:1:1 aspect ratio
    set(gca,'DataAspectRatio',[1 1 1])

end

