%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    disCLBP_(S+M) Version 0.1
%    Authors: Yimo Guo, Guoying Zhao, and Matti Pietikainen
%
%   MergeDominantType(Ori_ID_List,New_List) aims to merge the learnt dominant pattern type 
%   for each class to construct the final global pattern sets of interest
%   Input: Ori_ID_List is the current estimated global dominant pattern sets
%          New_List is the dominant pattern ID list of a new class
%   Output: The union of the pattern sets Ori_ID_List and New_List
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [Merged_ID_List] = MergeDominantType(Ori_ID_List,New_List)

sem = 0;
for index1 = 1:size(New_List,1)
    sem = 0;
    for index2 = 1:size(Ori_ID_List,1)
        if(New_List(index1,1)==Ori_ID_List(index2,1))
            sem = 1;
            break;
        end
    end
    
    if(sem==0)
        Ori_ID_List = [Ori_ID_List;New_List(index1,1)];
    end
end

Merged_ID_List = Ori_ID_List;
    
            
            