classdef LM_stack
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
    
%An object that represents a series of images.

    properties
        %shared properties
        type %type 1 is multiple TIFF files, type 2 is RAW, type 3 is ND2
        nframes %number of frames       
        dimension_x %x dimension
        dimension_y %y dimension      
        
        %type 1 properties
        filelist %list of TIFF files
        
        %type 2 properties        
        metafilename %path to meta file
        rawfile %file object representing raw file
        rawfilename %path to raw file
        metamatrix %matrix containing metadata
        
        %type 3 properties
        ND2filename  %path to nd2 file
        ND2filereader %reader object representing nd2 file
        ND2meta %matrix containing metadata (expect just piezo position)
        
    end
    
    methods
        function stack = LM_stack(type)
            %constructs a stack object requiring the type of stack to be
            %set
            stack.type=type;
        end
        function stack = initialiseTIFF(stack, filelist)
            stack.filelist=filelist;
            %check dimensions
            testimage=getframe(stack, 1);
            stack.dimension_x=size(testimage,1);
            stack.dimension_y=size(testimage,2);
            %check number of files
            stack.nframes=size(filelist,1);            
        end
        function stack = initialiseRAW(stack, rawfilename, metafilename)
            stack.rawfilename=rawfilename;
            stack.metafilename=metafilename;
            stack.metamatrix=dlmread(metafilename,'\t');
            stack.dimension_x=stack.metamatrix(1,5);
            stack.dimension_y=stack.metamatrix(1,6);
            stack.nframes=size(stack.metamatrix,1);
            stack.rawfile=fopen(rawfilename,'r','b');
        end
        function stack = initialiseND2(stack, ND2filename)
            stack.ND2filename=ND2filename;
            stack.ND2filereader=bfGetReader(ND2filename);
            stack.ND2meta=getND2meta(stack);
            stack.nframes=size(stack.ND2meta,1);
            %check dimensions
            testimage=getframe(stack, 3);
            stack.dimension_x=size(testimage,1);
            stack.dimension_y=size(testimage,2);            
        end
        function stack = reinitialise(stack)
            if stack.type==1
                stack = initialiseTIFF(stack, stack.filelist);
            elseif stack.type==2
                stack = initialiseRAW(stack, stack.rawfilename, stack.metafilename);
            end
        end
        function [image, frameID, meta] = getframe(stack, framenumber)
            if stack.type==1
                filepath=stack.filelist{framenumber};
                %get image
                image = imread(filepath); 
                %get some file naming info
                [folder,filenameonly,~]=fileparts(filepath);
                %get frameID
                frameID=str2double(regexp(filenameonly,'[0-9]+','match'));
                %get metadata (if it exists)                
                TIFFmetafilename=strcat(filenameonly, '_Z.tsv');
                metafile=fullfile(folder, TIFFmetafilename);
                if exist(metafile, 'file')
                    meta=double(dlmread(char(metafile)));
                else
                    meta=[];
                end
            elseif stack.type==2
                %find the right index in the raw file and pull out a chunk
                %of data that is the image
                byteindex=(stack.dimension_x*stack.dimension_y*(framenumber-1)*2);
                fseek(stack.rawfile,byteindex,'bof');
                image=fread(stack.rawfile,stack.dimension_x*stack.dimension_y,'uint16=>uint16');
                image=reshape(image, stack.dimension_x, stack.dimension_y);
                image=image';
                frameID=squeeze(stack.metamatrix(framenumber,1));
                meta=stack.metamatrix(framenumber,2:4);
            elseif stack.type==3
                image=bfGetPlane(stack.ND2filereader, framenumber);
                frameID=framenumber;
                meta=stack.ND2meta(framenumber,:);
            end
        end
        
        function [image, frameID, meta] = getaverage(stack, startframe, navframes)
           %allocate first frame number in the block as frame ID
           %And use metadata from first frame in block as metadata for
           %whole block (i.e. assume metadata is contastnt for block)
           [~,frameID,meta]=getframe(stack,startframe);
           images=zeros(navframes,stack.dimension_x,stack.dimension_y);
           for i=1:navframes               
               [images(i,:,:),~,~]=getframe(stack,startframe+i-1);                   
           end
           image=squeeze(mean(images));        
        end
        
        function meta = getND2meta(stack)            
            metadata = stack.ND2filereader.getSeriesMetadata();
            metadataKeys = metadata.keySet().iterator();
            for i=1:metadata.size()
              key = metadataKeys.nextElement();
              value = metadata.get(key);
              if not(isempty(strfind(key,'Z position')))
                 plane_number=str2double(cell2mat(regexp(key,'[0-9]+','match')));
                 piezo_position=value;
                 meta(i,1)=plane_number;
                 meta(i,2)=piezo_position;
              end
            end
            meta(all(meta==0,2),:)=[];
            meta = sortrows(meta,1);
            
        end
    end
end

