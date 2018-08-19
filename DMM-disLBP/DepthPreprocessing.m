% This code is used for changing the depth data from the 'bin' format to 'mat' format.
for i = 1:20
    idxcls = sprintf('a%02d', i);
    
    for j = 1:10
        idxsbj = sprintf('s%02d', j);
        
        for k = 1:3
            idxemp = sprintf('e%02d', k);
            fp = fopen(['MSRAction3D/Depth/',idxcls ,'_', idxsbj, '_', idxemp, '_sdepth.bin'], 'rb');

            if fp > 0
                    header = fread(fp, 3, 'int32');
                    nfrms = header(1); 
                    ncols = header(2); 
                    nrows = header(3);

                    depth = zeros(nrows, ncols, nfrms);

                    for i = 1:nfrms
                        temp = fread(fp, [ncols, nrows], 'int32');
                        depth(:, :, i) = temp';
                        savename = ['DMM-disLBP/data/Action3D-bak/', idxcls ,'_', idxsbj, '_', idxemp, '_sdepth.mat'];
                        disp(savename);
                        save(savename,'depth');
                    end
                    
                    fclose(fp);
            end
        end
    end
end
