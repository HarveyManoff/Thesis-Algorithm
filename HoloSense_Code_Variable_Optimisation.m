clc;
clear;
close all;

%Import the values from the modified CSV file.
Imported_Values = csvread('coordtest1.csv');
Depths = csvread('Depths.csv');

%This will give a (length) * 6 array. The first column is the count from
%the total, second is the depth, 3rd and 4th are the centerpoints
%predectided by the fourier transform, and the 5th and 6th are the manually
%centered points.
Corrected_Values = csvread('Corrected_Data.csv');
Corrected_Count = Corrected_Values(:,1);
Corrected_X = Corrected_Values(:,5);
Corrected_Y = Corrected_Values(:,6);


%This gives a 2x1 vector, with the number of rows and columns.
Import_Size = size(Imported_Values);
Row_Size = Import_Size(1) -1 ;
Column_Size = Import_Size(2);


%Have to minus 1 due to having the center values included.

%Number of unique points will be columns, divide 2 (x and y), and subtract
%1, due to the columns with center values.
Unique_Data = floor(Column_Size/2) -1;
Xvals = zeros(Row_Size+1,Unique_Data);
Yvals = zeros(Row_Size+1,Unique_Data);


Xvals(:,1) = Imported_Values(:,1)';
Yvals(:,1) = Imported_Values(:,2);
for x = 2:Unique_Data+1
    %Get the X and Y values.
    %Note the that data in the CSV file is effectively the transpose of the
    %raw data, meaning each column is all the x values for one reading
    %(plus the centerpoint).
    Xvals(:,x) = Imported_Values(:,x*2 - 1)';
    Yvals(:,x) = Imported_Values(:,x*2);
end
Xvals_Center = Xvals(1,:);
Yvals_Center = Yvals(1,:);

%This is used to determine the radial lengths.
% Could be done more effectly.
Normalised_Xvals = zeros(Row_Size,Unique_Data);
Normalised_Yvals = zeros(Row_Size,Unique_Data);

%Removes the center point values.
Xvals = Xvals(2:end,:);
Yvals = Yvals(2:end,:);



%Normalise the X and Y position values for each sample.
for i = 1:Unique_Data
    Normalised_Xvals(:,i) = Xvals(:,i) - Xvals_Center(i);
    Normalised_Yvals(:,i) = Yvals(:,i) - Yvals_Center(i);
end

Radius_Values = zeros(Row_Size,Unique_Data);

for i = 1:Unique_Data
    Radius_Values(:,i) = sqrt(abs(Normalised_Xvals(:,i)).^2 + abs(Normalised_Yvals(:,i)).^2);
end
figure(1)
%Need to sort the data into 2 categories, good on ceramic and good
%on steel.

%Break the circle (810 readings) into segments of x%.


%Start and Finish points for better testing.
Start_Point = 467;
End_Point = 495;

%Loction to save the processed images to.
folder = 'C:\Users\Harvey\Documents\Thesis\test6\6.5';

%This allows for the values used to be saved to an excel file at the end of
%run-time
Tolerance = [];
Step_Size = [];
B_Multiplier = [];
C_Multiplier = [];
Average_Error = [];
Median_Error = [];
Fourier_Error = [];
Perc_Amount = [];

for Perc = [1,2,3,4,5]
    
    for Tol = [10,12,14,16,18]
        
        for B_mult = [.2,.3,.5,.4]
            for C_mult = [.6,.75,.8,.85,.9]
                for Req_Perc = [10, 20, 30, 40, 50]
                Segment_Size = floor(810*(Perc/100));
                
                %Initialise values and arrays.
                In_Loc_Used = 0;
                Out_Loc_Used = 0;
                
                Error_Av_accum = [];
                Error_Med_accum = [];
                fourier_err_accum = [];
                
                for Graph_Number = [387:466,707:813]
                    %Set the first track to be the "good ceramic" this is not always true,
                    %but is irrelevant.
                    In_Out = 1;
                    
                    %Clear the vectors.
                    In_Locations = [];
                    Out_Locations = [];
                    
                    
                    %NOTE: many of the commented out sections were used to
                    %generate graphs to test accuracy by eye in the early
                    %stages. These can be added back in for final run.
                    
                    
                    %Open a figure, and name it accordingly.
%                     h = figure();
%                     if(Graph_Number<10)
%                         ImageName = sprintf('processed_video 000%g.jpg',Graph_Number);
%                     elseif(Graph_Number<100)
%                         ImageName = sprintf('processed_video 00%g.jpg',Graph_Number);
%                     elseif(Graph_Number<1000)
%                         ImageName = sprintf('processed_video 0%g.jpg',Graph_Number);
%                     else
%                         ImageName = sprintf('processed_video %g.jpg',Graph_Number);
%                     end
                    
                    %This is the location of the base images, taken from the processed
                    %video.
%                     filepath = fullfile('E:\HoloSense\Video to Picture\Prominent Hill 0-140\Harvey Test V2\processed_video (3-7-2018 4-03-23 PM)/',ImageName);
%                     img = imread(filepath);
%                     
%                     imagesc(img);
%                     
%                     hold on
                    
                    %This is an array that was used to check that switching between
                    %arrays was occurring.
                    In_Out_Array = zeros(1,floor(1/Perc));
                    In_Out_Array(1) = 1;
                    %This is an array used to determine when a switch has occurred.
                    switchtime = [];
                    switchtime(1) = 0;
                    for i = 2:floor(100/Perc)
                        dr = abs(Radius_Values((Segment_Size*(i-1)+1),Graph_Number) - Radius_Values((Segment_Size*i),Graph_Number));
                        %If the difference in radii is greater than the tollerance switch
                        %arrays.
                        if dr>Tol
                            if In_Out ==1
                                In_Out = 2;
                                switchtime = [switchtime, i];
                            else
                                In_Out = 1;
                                switchtime = [switchtime, i];
                                
                            end
                        end
                        
                        
                        In_Out_Array(i) = In_Out;
                        
                        %This checks to see if two switches have occurred one after the
                        %other. This indicates a long transition period (across multiple
                        %segments)
                        
                        if numel(switchtime)>=2
                            if switchtime(end) - switchtime(end-1) == 1
                                In_Out = In_Out_Array(i-1);
                                
                            end
                        end
                        
                        
                        
                        
                        %This is determining which array to store the data in, and removing
                        %points if a break has been detected.
                        if (dr<=Tol && In_Out == 1 && switchtime(end)~= i-1)
                            In_Locations = [In_Locations,(Segment_Size*(i-1)+1):Segment_Size*(i)];
%                             plot(Xvals((Segment_Size*(i-1)+1):Segment_Size*(i),Graph_Number),Yvals((Segment_Size*(i-1)+1):Segment_Size*(i),Graph_Number),'b');
                            disp(i)
                        elseif (dr<=Tol && In_Out == 2 && switchtime(end)~= i-1)
                            Out_Locations = [Out_Locations,(Segment_Size*(i-1)+1):Segment_Size*(i)];
%                            plot(Xvals((Segment_Size*(i-1)+1):Segment_Size*(i),Graph_Number),Yvals((Segment_Size*(i-1)+1):Segment_Size*(i),Graph_Number),'y');
                            disp(i)
                        elseif (dr<=Tol && In_Out == 1 && switchtime(end)== i-1)
                            disp(numel(Out_Locations));
                            Out_Locations = Out_Locations(1:(end-Segment_Size));
                            disp(numel(Out_Locations));
                            disp('removed points Out');
                        elseif (dr<=Tol && In_Out == 2 && switchtime(end)== i-1)
                            disp(numel(In_Locations));
                            In_Locations = In_Locations(1:(end-Segment_Size));
                            disp(numel(In_Locations));
                            disp('removed points In');
                        end
                        
                        
                        
                        
                        
                    end
                    
                    
                    %IMPORTANT NOTE: WHEN LOOKING AT THE MATLAB FIGURE, THE PLOTTED POINTS
                    %ARE SELECTED CLOCKWISE. MEANING THE FIRST POINT IS AT THE RIGHT, AND
                    %THEN MOVES DOWN AND TO THE LEFT.
                    
                    In_Weights = numel(In_Locations)/Segment_Size;
                    Out_Weights = numel(Out_Locations)/Segment_Size;
                    
                    X_Center_Out = [];
                    X_Center_In = [];
                    
                    Y_Center_In = [];
                    Y_Center_Out = [];
                    if 100*numel(In_Locations)/810 > Req_Perc
                        
                        
                        In_Loc_Used = 1;
                        
                        A_X = zeros(1,numel(In_Locations));
                        A_Y = zeros(1,numel(In_Locations));
                        B_X = zeros(1,numel(In_Locations));
                        B_Y = zeros(1,numel(In_Locations));
                        C_X = zeros(1,numel(In_Locations));
                        C_Y = zeros(1,numel(In_Locations));
                        M_ABX = zeros(1,numel(In_Locations));
                        M_ABY = zeros(1,numel(In_Locations));
                        M_BCX = zeros(1,numel(In_Locations));
                        M_BCY= zeros(1,numel(In_Locations));
                        S_AB= zeros(1,numel(In_Locations));
                        S_BC = zeros(1,numel(In_Locations));
                        PS_AB = zeros(1,numel(In_Locations));
                        PS_BC = zeros(1,numel(In_Locations));
                        AB_Const = zeros(1,numel(In_Locations));
                        BC_Const = zeros(1,numel(In_Locations));
                        X_Center_In = zeros(1,numel(In_Locations));
                        Y_Center_In = zeros(1,numel(In_Locations));
                        
                        
                        for itlop = 1:numel(In_Locations)
                            B_loc = floor(length(In_Locations)*B_mult)+itlop - 1;
                            if B_loc > numel(In_Locations)
                                B_loc = B_loc - numel(In_Locations);
                            end
                            
                            C_loc = floor(length(In_Locations)*C_mult)+itlop -1;
                            if C_loc > numel(In_Locations)
                                C_loc = C_loc - numel(In_Locations);
                            end
                            
                            
                            A_X(itlop) = Xvals(In_Locations(itlop),Graph_Number);
                            A_Y(itlop) = Yvals(In_Locations(itlop),Graph_Number);
                            
                            
                            B_X(itlop) = Xvals(In_Locations(B_loc),Graph_Number);
                            B_Y(itlop) = Yvals(In_Locations(B_loc),Graph_Number);
                            
                            C_X(itlop) = Xvals(In_Locations(C_loc),Graph_Number);
                            C_Y(itlop) = Yvals(In_Locations(C_loc),Graph_Number);
                            
                            
                            M_ABX(itlop) = (A_X(itlop) + B_X(itlop))/2;
                            M_ABY(itlop) = (A_Y(itlop) + B_Y(itlop))/2;
                            
                            M_BCX(itlop) = (B_X(itlop) + C_X(itlop))/2;
                            M_BCY(itlop)= (B_Y(itlop) + C_Y(itlop))/2;
                            
                            S_AB(itlop)= (B_Y(itlop) - A_Y(itlop))/(B_X(itlop) - A_X(itlop));
                            S_BC(itlop) = (C_Y(itlop) - B_Y(itlop))/(C_X(itlop) - B_X(itlop));
                            
                            PS_AB(itlop) = -1/S_AB(itlop);
                            PS_BC(itlop) = -1/S_BC(itlop);
                            
                            AB_Const(itlop) = M_ABY(itlop) - M_ABX(itlop)*PS_AB(itlop);
                            BC_Const(itlop) = M_BCY(itlop) - M_BCX(itlop)*PS_BC(itlop);
                            
                            
                            
                            
                            
                            X_Center_In(itlop) = (BC_Const(itlop)-AB_Const(itlop))/(PS_AB(itlop)-PS_BC(itlop));
                            Y_Center_In(itlop) = PS_AB(itlop)*X_Center_In(itlop) + AB_Const(itlop);
                            
                        end
                        
                        
                        X_Center_In = X_Center_In';
                        Y_Center_In = Y_Center_In';
                        
                        %Get NaNs appearing, I beleive this is due to the rotation, and
                        %getting divide by 0 when two points are along the horizontal
                        X_Center_In = X_Center_In(~isnan(X_Center_In));
                        Y_Center_In = Y_Center_In(~isnan(Y_Center_In));
                        
                        %         plot(median(X_Center_In),median(Y_Center_In),'r*','MarkerSize',30);
                        %         plot(A_X(1,Graph_Number),A_Y(1,Graph_Number),'r*','MarkerSize',30);
                        %         plot(B_X(1,Graph_Number),B_Y(1,Graph_Number),'r*','MarkerSize',30);
                        %         plot(C_X(1,Graph_Number),C_Y(1,Graph_Number),'r*','MarkerSize',30);
                    end
                    
                    if 100*numel(Out_Locations)/810 > Req_Perc
                        
                        Out_Loc_Used = 1;
                        
                        A_X = zeros(1,numel(Out_Locations));
                        A_Y = zeros(1,numel(Out_Locations));
                        B_X = zeros(1,numel(Out_Locations));
                        B_Y = zeros(1,numel(Out_Locations));
                        C_X = zeros(1,numel(Out_Locations));
                        C_Y = zeros(1,numel(Out_Locations));
                        M_ABX = zeros(1,numel(Out_Locations));
                        M_ABY = zeros(1,numel(Out_Locations));
                        M_BCX = zeros(1,numel(Out_Locations));
                        M_BCY= zeros(1,numel(Out_Locations));
                        S_AB= zeros(1,numel(Out_Locations));
                        S_BC = zeros(1,numel(Out_Locations));
                        PS_AB = zeros(1,numel(Out_Locations));
                        PS_BC = zeros(1,numel(Out_Locations));
                        AB_Const = zeros(1,numel(Out_Locations));
                        BC_Const = zeros(1,numel(Out_Locations));
                        X_Center_Out = zeros(1,numel(Out_Locations));
                        Y_Center_Out = zeros(1,numel(Out_Locations));
                        for itlop = 1:numel(Out_Locations)
                            B_loc = floor(length(Out_Locations)/2)+itlop - 1;
                            if B_loc > numel(Out_Locations)
                                B_loc = B_loc - numel(Out_Locations);
                            end
                            
                            C_loc = floor(1.5*length(Out_Locations)/2)+itlop -1;
                            if C_loc > numel(Out_Locations)
                                C_loc = C_loc - numel(Out_Locations);
                            end
                            
                            
                            A_X(itlop) = Xvals(Out_Locations(itlop),Graph_Number);
                            A_Y(itlop) = Yvals(Out_Locations(itlop),Graph_Number);
                            
                            
                            B_X(itlop) = Xvals(Out_Locations(B_loc),Graph_Number);
                            B_Y(itlop) = Yvals(Out_Locations(B_loc),Graph_Number);
                            
                            C_X(itlop) = Xvals(Out_Locations(C_loc),Graph_Number);
                            C_Y(itlop) = Yvals(Out_Locations(C_loc),Graph_Number);
                            
                            
                            M_ABX(itlop) = (A_X(itlop) + B_X(itlop))/2;
                            M_ABY(itlop) = (A_Y(itlop) + B_Y(itlop))/2;
                            
                            M_BCX(itlop) = (B_X(itlop) + C_X(itlop))/2;
                            M_BCY(itlop)= (B_Y(itlop) + C_Y(itlop))/2;
                            
                            S_AB(itlop)= (B_Y(itlop) - A_Y(itlop))/(B_X(itlop) - A_X(itlop));
                            S_BC(itlop) = (C_Y(itlop) - B_Y(itlop))/(C_X(itlop) - B_X(itlop));
                            
                            PS_AB(itlop) = -1/S_AB(itlop);
                            PS_BC(itlop) = -1/S_BC(itlop);
                            
                            AB_Const(itlop) = M_ABY(itlop) - M_ABX(itlop)*PS_AB(itlop);
                            BC_Const(itlop) = M_BCY(itlop) - M_BCX(itlop)*PS_BC(itlop);
                            
                            
                            
                            
                            
                            X_Center_Out(itlop) = (BC_Const(itlop)-AB_Const(itlop))/(PS_AB(itlop)-PS_BC(itlop));
                            Y_Center_Out(itlop) = PS_AB(itlop)*X_Center_Out(itlop) + AB_Const(itlop);
                            
                        end
                        
                        X_Center_Out = X_Center_Out';
                        Y_Center_Out = Y_Center_Out';
                        
                        X_Center_Out = X_Center_Out(~isnan(X_Center_Out));
                        Y_Center_Out = Y_Center_Out(~isnan(Y_Center_Out));
                        
                       
                        
                        
                        
                    end
                    Total_Y = [];
                    Total_X = [];
                    Total_Y = [Y_Center_Out',Y_Center_In'];
                    Total_X = [X_Center_Out',X_Center_In'];
                    
                    Bad_X_Locs = abs(Total_X - mean(Total_X)) > std(Total_X);
                    Total_X(Bad_X_Locs) = [];
                    Bad_Y_Locs = abs(Total_Y - mean(Total_Y)) > std(Total_Y);
                    Total_Y(Bad_Y_Locs) = [];
                    
                    
 %                   med_plot = plot(median(Total_X), median(Total_Y),'k*','MarkerSize',30);
                    
                    Corrected_Location = find(Corrected_Count == Graph_Number);
 %                   true_plot = plot(Corrected_X(Corrected_Location),Corrected_Y(Corrected_Location),'r+','MarkerSize',30);
                    
                    
 %                   [lgd, objh] = legend([med_plot,true_plot],{'Median Value','Manually Centered Value'}, 'Location', 'NorthEast');
  %                  objhl = findobj(objh, 'type', 'line'); %// objects of legend of type line
   %                 set(objhl, 'Markersize', 12); %// set marker size as desired
                    
 %                   dim = [.15, 0, 0.3, 0.3];
                    av_err = sqrt((mean(Total_X) - Corrected_X(Corrected_Location))^2 + (mean(Total_Y) - Corrected_Y(Corrected_Location))^2);
                    Error_Av_accum = [Error_Av_accum,av_err];
                    Av_av_err = mean(Error_Av_accum);
                    %             av_err_str = sprintf('Accumlative Average Error (using mean) = %g\nAccumlative Average Error (using mean) = %g',Av_av_err,Av_av_err);
                    %             annotation('textbox',dim,'String',av_err_str,'FitBoxToText','on','BackgroundColor','w');
                    
                    med_err = sqrt((median(Total_X) - Corrected_X(Corrected_Location))^2 + (median(Total_Y) - Corrected_Y(Corrected_Location))^2);
                    Error_Med_accum = [Error_Med_accum,med_err];
                    Av_med_err = mean(Error_Med_accum);
                    %             med_err_str = sprintf('Accumlative Average Error (using median) = %g',Av_med_err);
                    
                    fourier_err = sqrt((Xvals_Center(Corrected_Location) - Corrected_X(Corrected_Location))^2 +(Yvals_Center(Corrected_Location) -  Corrected_Y(Corrected_Location))^2 );
                    fourier_err_accum = [fourier_err_accum,fourier_err];
                    av_fourier_err = mean(fourier_err_accum);
                    
                    
                    
%                    av_err_str = sprintf('Error (using mean) = %g\nError (using median) = %g\nFourier Error = %g',av_err,med_err,fourier_err);
%                    annotation('textbox',dim,'String',av_err_str,'FitBoxToText','on','BackgroundColor','w');
                    
%                    mean_err_str = sprintf('Av Er (mean) = %g\nAv Er(median) = %g\nAv Er(fourier) = %g',Av_av_err,Av_med_err,av_fourier_err);
                    
                    dim2 = [.6, 0, 0.3, 0.3];
%                    annotation('textbox',dim2,'String',mean_err_str,'FitBoxToText','on','BackgroundColor','w');
                    
                    
                    
                    
                    
%                     Title_Text = sprintf('Median Graph of Sample: %g (Depth: %gm) Perc: %g Tol: %g B mult:%g C mult:%g',Graph_Number, Depths(Graph_Number),Perc,Tol,B_mult, C_mult);
%                     title(Title_Text)
%                     Image_Text = sprintf('Median_Graph_of_Sample_%g_Depth_%gm_Perc_%g_Tol_%g_B_mult_%g_C_mult_%g.png',Graph_Number, Depths(Graph_Number),Perc,Tol,B_mult, C_mult);
%                     print(Image_Text, '-dpng')
%                     fullFileName = fullfile(folder,Image_Text);
                    
%                     saveas(gcf,fullFileName);
%                     close all
                    
                    if Graph_Number==813
                        Tolerance = [Tolerance,Tol];
                        Step_Size = [Step_Size,Perc];
                        B_Multiplier = [B_Multiplier,B_mult];
                        C_Multiplier = [C_Multiplier,C_mult];
                        Average_Error = [Average_Error,Av_av_err];
                        Median_Error = [Median_Error,Av_med_err];
                        Fourier_Error = [Fourier_Error,av_fourier_err];
                        Perc_Amount = [Perc_Amount,Req_Perc];
                        
                        varNames = {'Step_Size','Tolerance' , 'B_Multiplier', 'C_Multiplier', 'Perc_Required', 'Average_Error', 'Median_Error','Fourier_Error'};
                        
                        T = table(Step_Size',Tolerance',B_Multiplier',C_Multiplier', Perc_Amount', Average_Error', Median_Error', Fourier_Error','VariableNames',varNames);
                                              
                    end
                end
                end
            end
        end
    end
end

filename = 'Error_Values5stel.xlsx';
writetable(T,filename,'Sheet',1,'Range','A1')