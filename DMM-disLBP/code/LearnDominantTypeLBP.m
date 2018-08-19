function [Dominant_Hist] = LearnDominantTypeLBP(G,row_blk, col_blk,R,N,threshold,mapping)


G = double(G);

Hist = get_LBP_fea_global(G,row_blk, col_blk,R,N,mapping);
Block_Num = size(Hist,1)/mapping.num;
Dominant_Hist = cell(Block_Num,1);
Num_Total = mapping.num;

ID = 0:Num_Total - 1;
ID = ID';

Hist = reshape(Hist,Num_Total,Block_Num);

for i = 1:Block_Num
    Block_Hist = Hist(:,i);
    Total_Num_Pattern = sum(Block_Hist);

    Threshold_Num = floor(Total_Num_Pattern*threshold);


    M = [ID, Block_Hist];

    Des_M = sortrows(M, -2);

    %% Find out the Cut Point
    for index1 = 1:size(Des_M,1)
        if(sum(Des_M(1:index1,2))>=Threshold_Num)
            cut_index = index1;
            break;
        end
    end


    Dominant_Hist{i} = Des_M(1:cut_index,1);
end    






