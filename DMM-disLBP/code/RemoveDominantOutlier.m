%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    disCLBP_(S+M) Version 0.1
%    Authors: Yimo Guo, Guoying Zhao, and Matti Pietikainen
%
%   RemoveDominantOutlier(M,N) aims to remove Outlier of the learnt dominant pattern type 
%   for each Class
%   Input: M is the current class Dominant pattern ID list, N is the newly input
%        Dominant pattern ID list for an image
%   Output: The intersaction of the dominant pattern set M and N
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Truncated_Dominant_List] = RemoveDominantOutlier(M,N)

sem = 0;
Config_List = [];
for index1 = 1:size(M,1)
    
    for index2 = 1:size(N,1)
         %%Check if it is an outlier
         if(M(index1,1)==N(index2,1))
             sem = 1;
             break;
         end
    end
            
            
    %%If outlier not found, preserve it temporarily
    if(sem==1)
        Config_List = [Config_List;M(index1,1)];
    end
            
    sem = 0;
end

Truncated_Dominant_List = Config_List;                     
            
                    
                
                