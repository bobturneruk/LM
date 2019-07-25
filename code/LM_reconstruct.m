function [ candidates ] = LM_reconstruct(  stack, reconset, mask )
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
   
    settingsOK=0;
    
    runtime=0;
    
    disp('Initialisng...')

    if strcmp(reconset.graphics,'on')
        fits_overlay=figure;        
    end

    tempfits=[];
    candidates=[]; 
    
    %used later for graphics
    myxlim=[0 stack.dimension_x];
    myylim=[0 stack.dimension_y];
        
    %ensure, if using block averages, that the routine stops before we run
    %out of files.
    %$nfiles=floor(nfiles/reconset.averageframes)*reconset.averageframes;
    
    if stack.nframes>reconset.stopframe
        stopframe=reconset.stopframe;
    else
        stopframe=stack.nframes;
    end
    
    if reconset.averageframes>1
        stopframe=(floor(stopframe/reconset.averageframes)-1)*reconset.averageframes;
    end
    
    framecount=stopframe-reconset.startframe;
    
    for i=reconset.startframe:reconset.averageframes:stopframe
           
        tic;      
        if reconset.averageframes>1
            %reconsturction of block averages
            [rawimage, frameID, meta]=stack.getaverage(i,reconset.averageframes);
        else
            %normal reconstruction  
            [rawimage, frameID, meta]=stack.getframe(i);
        end
        rawimage=double(rawimage);
        
        %check if there is metadata
        if numel(meta)==0
            pz=-1;
        else
            pz=meta(1);
        end
        
        switch reconset.filter
            case 'off'
                activeimage=rawimage;    
            case 'LOG'
                %apply laplacian of gaussian filter
                F = fspecial('LOG',[reconset.filter_width*2 reconset.filter_width*2],reconset.filter_width);
                filteredimage = -1*imfilter(rawimage,F,'replicate');
                activeimage=filteredimage;                
            case 'gaussian'
                %apply laplacian of gaussian filter
                F = fspecial('gaussian',[reconset.filter_width*2 reconset.filter_width*2],reconset.filter_width);
                filteredimage = imfilter(rawimage,F,'replicate');
                activeimage=filteredimage;       
        end
        
        %threshold
        binimage=activeimage>reconset.threshold;
        
        %find regional maxima
        myimage=imimposemin(activeimage, imcomplement(binimage));
        maximage = imregionalmax(myimage);
        %maximage=bwulterode(binimage);   
        
        %don't trepaspass on excluded regions
        if nargin==3
            maximage=maximage.*mask;
        end
            
        %identify regions to fit
        cutsquare = strel('square',reconset.spacing);
        sqimage=imdilate(maximage,cutsquare);
        %exclude any overlapping regions (too large), or close to edge
        %regions (too small)
        sqarea=reconset.spacing^2;
        sqimage = xor(bwareaopen(sqimage,sqarea-1),  bwareaopen(sqimage,sqarea+1));
        sqimage=bwlabel(sqimage);
        
        %number of regions
        nregions=max(max(sqimage));
        
        fitregions=regionprops(sqimage,rawimage,'PixelValues','BoundingBox','WeightedCentroid');
                
        myspacing=reconset.spacing;      
        
        %fit Gaussians to regions
        
        %can change to parfor
        for j=1:nregions
           
            if (size(fitregions(j).PixelValues,1)==myspacing^2)
                
                extract=[];
                
                extract=reshape(fitregions(j).PixelValues,myspacing,myspacing);

            
                myfit=[-1 -1 -1 -1 -1 -1 -1 -1]; 

                rawx=-1;
                rawy=-1;

                myfit=LM_fit(extract);

                %log positions relative to cutout reference frame
                rawx=myfit(2);
                rawy=myfit(4);

                %translate xy position to main reference frame
                bbox=fitregions(j).BoundingBox;
                ulc=bbox(1:2);
                myfit(2)=myfit(2)+ulc(1)-0.5;
                myfit(4)=myfit(4)+ulc(2)-0.5;     

                afit=[myfit(1:6) frameID pz*1000 0 0 0 0 myfit(7:8) fitregions(j).WeightedCentroid];
                afit(19:20)=[rawx rawy];

                tempfits=[tempfits; afit];
            
           else
                strcat('Warning: dodgy region region size in file index ', i);                
            end
                                     
        end

        if size(tempfits,1)>0            
            candidates=[candidates; tempfits];
        end
        
        
        if strcmp(reconset.graphics,'on')           
           clf(fits_overlay);
           
           figure(fits_overlay)
           
           hold on;        
           %set(gca,'position',[0.1 0.1 0.5 0.9]);
           set(gca,'DataAspectRatio',[1 1 1]);
           set(gca,'YDir','reverse');
           xlim(myxlim);
           ylim(myylim);
           
           imagesc(rawimage,[reconset.displaymin reconset.displaymax]);
           %imagesc(filteredimage,[0 5]);  
           
           title(strcat('Raw File: ',int2str(i),'/',int2str(stack.nframes)),'FontWeight','bold');
           colormap('gray');
           colorbar;
           
           B=bwboundaries(binimage);
           for k = 1:length(B)
                boundary = B{k};
                patch(boundary(:,2)+0.5, boundary(:,1)+0.5,'b','FaceAlpha',0.3);                
           end
           
           B=bwboundaries(sqimage);
           for k = 1:length(B)
                boundary = B{k};
                patch(boundary(:,2)+0.5, boundary(:,1)+0.5,'g','FaceAlpha',0.3);                
           end
           
           if size(tempfits,1)>0 
                scatter(tempfits(:,2),tempfits(:,4),'MarkerEdgeColor','y');
           end
           hold off;
           
           drawnow;
           
        end
        
        
        %empty temporary variables
        tempfits=[];
                        
        %progress bar stuff
        runtime=runtime+toc;
        framesdone=i-reconset.startframe+1;
        meanframetime=runtime/framesdone;
        remaintime=((framecount-framesdone)*meanframetime)/60;
        %waitbar(framesdone/framecount,figure_wait,strcat('Mean time per frame (s): ',num2str(meanframetime,5),' Time left (mins):', num2str(remaintime,5)));
        clc;
        disp(strcat('Frame:',int2str(framesdone),' of:', int2str(framecount)))
        disp(strcat('Mean time per frame (s): ',num2str(meanframetime,5)))
        disp(strcat('Time left (mins):', num2str(remaintime,5)))
                
        %runtime tweaking of reconstruction settings
        if settingsOK==0            
            choice = questdlg('Are you happy with the settings?','Settings','Yes', 'Yes switch off graphics', 'No', 'No'); 
            switch choice
                case 'Yes'
                    settingsOK=1;
                case 'Yes switch off graphics'
                    settingsOK=1;
                    reconset.graphics='off';               
                otherwise
                    reconset=LM_dlgreconset(reconset);
            end                
        end  
        
        % Check for Cancel button press
        %if getappdata(figure_wait,'canceling')
        %    break
        %end

    end
    
    
    %remove rows marked with "-1" i.e. no fit returned
    if not(isempty(candidates))
        candidates=candidates(candidates(:,1)>-1,:);
    end
    
    %get rid of visualisations    
    %delete(figure_wait); %waitbar
    if reconset.graphics==1
        delete(fits_overlay);
    end
    
    helpdlg('Reconstruction complete.','LM Information')
    
end

