function [ reconset ] = LM_dlgreconset( varargin )
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

%A dialog box to make it easy to specify reconstruction settings.

%Threhold: How bright must a part of the image be to be considered for
%fitting?
%Spacing: How far apart must birght parts of the image be?
%Filter: What noise reducing and feature enhancing filter should be used?
%Options are 'off', 'gaussian' or 'LOG' (Laplacian of Gaussian).
%Filter Width: Essentially how big the molecules appear in the image, in
%pixels.
%Graphics: Should LM display graphics (annoated source frames) while reconstructing?
%Display min and max: If displaying frames what colour scale should be
%used.
%Avrage Frames: Should groups of frames be averaged whilst reconstructing?
%Start and Stop frames: Specify a subset of frames for analysis.

    if size(varargin)==0
        reconset.threshold=5;
        reconset.spacing=10;
        reconset.filter='LOG'; %'off', 'gaussian', 'LOG
        reconset.filter_width=5;
        reconset.graphics='on'; %'on', 'off'
        reconset.displaymin=1500;
        reconset.displaymax=4000;
        reconset.averageframes=1;
        reconset.startframe=1;
        reconset.stopframe=100000000000;  
    else
        reconset=varargin{1};
    end
        
    
    dlg_title = 'Change reconstruction parameters';
    prompt = {'Threshold:', 'Spacing:', 'Filter:', 'Filter width;', 'Graphics', 'Display min:', 'Display max:', 'Average frame:', 'Start frame', 'Stop frame:'};
    num_lines = ones(10,1);
    
    %ensure everything is a number.
    str_threshold=num2str(reconset.threshold);
    str_spacing=num2str(reconset.spacing);
    str_filter=reconset.filter;
    str_filter_width=num2str(reconset.filter_width);
    str_graphics=reconset.graphics;
    str_displaymin=num2str(reconset.displaymin);
    str_displaymax=num2str(reconset.displaymax);
    str_averageframes=num2str(reconset.averageframes);
    str_startframe=num2str(reconset.startframe);    
    str_stopframe=num2str(reconset.stopframe);
    
    def = {str_threshold, str_spacing, str_filter, str_filter_width, str_graphics, str_displaymin, str_displaymax, str_averageframes, str_startframe, str_stopframe};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    
    if not(isempty(answer))
        reconset.threshold=str2double(answer{1});
        reconset.spacing=str2double(answer{2});
        reconset.filter=answer{3};
        reconset.filter_width=str2double(answer{4});
        reconset.graphics=answer{5};
        reconset.displaymin=str2double(answer{6});
        reconset.displaymax=str2double(answer{7});
        reconset.averageframes=str2double(answer{8});
        reconset.startframe=str2double(answer{9});
        reconset.stopframe=str2double(answer{10});
    end
    
end

