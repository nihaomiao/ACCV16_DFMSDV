function [F,S,T] = depth_projection(X)

% X: depth map (3D)

%       y
%       |   
%       |  
%       |_ _ _ x
%      /
%     /
%    z
%

[rows,cols,D] = size(X);

% enhance edge
% for i = 1:D
%     tmp = X(:,:,i);
%     E = edge(tmp,'canny');
%     tmp(E) = max(tmp(:));
%     X(:,:,i) = tmp;   
% end

X2D = reshape(X, rows*cols, D);
max_depth = max(X2D(:));

F = zeros(rows, cols);
S = zeros(rows, max_depth);
T = zeros(max_depth, cols);


for k = 1:D   
    front = X(:,:,k);
    side = zeros(rows, max_depth);
    top = zeros(max_depth, cols);
    

    for i = 1:rows
        for j = 1:cols
            if front(i,j) ~= 0
                side(i,front(i,j)) = j;   % side view projection (y-z projection)
                top(front(i,j),j)  = i;   % top view projection  (x-z projection)
            end
        end
    end
    
    if k > 1
        F = F + abs(front - front_pre);
        S = S + abs(side - side_pre);
        T = T + abs(top - top_pre);
    end   
    

    
    front_pre = front;
    side_pre  = side;
    top_pre   = top;
end

F = bounding_box(F);
S = bounding_box(S);
T = bounding_box(T);

% box_size_f = size(F);
% box_size_s = size(S);
% box_size_t = size(T);




