%% prep workspace
clear; clc; close all;

%% unpack Bellhop gvel table
[DATA,INDEX] = h_unpack_bellhop('../bellhop-gvel-gridded/gveltable.csv');

%% load simulation
listing = dir('../bellhop-gvel-gridded/csv_arr/*gridded.csv');
[T,colorSet] = h_get_nbc(listing,DATA,INDEX);

%% isovelocity case - loads "iso"
load isovelocity-ssp.mat

%% statistics

for s = [0 5 3 4]
    
    if s == 0
        yval = iso.avg .* DATA.owtt(INDEX.valid) - DATA.recRange(INDEX.valid);
    else
        %yval = T{s}.gvel(INDEX.valid) .* DATA.owtt(INDEX.valid) - DATA.recRange(INDEX.valid);
        yval = T{s}.gvel .* DATA.owtt - DATA.recRange;

    end
    
    % print statistics
    fprintf('%d \n',s);
    fprintf('median = %3.2f \n', median(yval,'omitnan'));
    
    
    
    fprintf('\n \n');
end
    