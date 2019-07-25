function [ filelist ] = LM_filelist( folder )
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
       
%Builds a list of files in a specified folder as a cell array.

    files=dir(folder);
    
    if isempty(files)
        disp('Path not found. Typo?');
    end
    
    nfiles=size(files,1);
    
    filelist=cell(nfiles,1);
    
    %filelist=cellstr(filelist);
    
    for i=1:nfiles;        
        if (not(isempty(strfind(lower(files(i).name),'tif'))))
            filelist{i}=fullfile(folder, files(i).name);
        end
    end
    
    filelist=filelist(cellfun('length',filelist)>0);
    
end

