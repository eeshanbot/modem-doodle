%% plot_raw_locs.m

%% prep workspace
clear; clc;

%% get raw loc filenames
listing = dir('~/.dropboxmit/icex_2020_mat/itp-files/itp*rawlocs.dat');

%% figure

figure(2); clf;

gray = [0.2 0.2 0.2 0.2];

camptime = datenum([2020 2 20 0 0 0]);

newcolors = distinguishable_colors(7);

for l = 1:length(listing)
    filepath = fullfile([listing(l).folder '/' listing(l).name]);
    
    [timestamp, lon, lat] = itp_import_rawloc(filepath);
    
    fprintf('%s | %s | %s \n',listing(l).name(1:6),datestr(min(timestamp)),datestr(max(timestamp))) 
    
    numDays = 151;
    window = find(abs(timestamp - camptime) <= numDays);
    
    geoplot(lat(window),lon(window),'linewidth',2,'color',newcolors(l,:));
    hold on
    geoplot(lat(window(end)),lon(window(end)),'o','MarkerSize',12,...
        'color',newcolors(l,:),'HandleVisibility','off');
    
    lgdstr{l} = listing(l).name(4:6);
end

minDate = camptime - numDays;
maxDate = camptime + numDays;
titlestr = sprintf('Active ITP profilers from %s to %s',datestr(minDate),datestr(maxDate));
title(titlestr)

% seadragon
g0 = geoplot(71.18, -142.41, 'rd','MarkerSize',12);
hold off

lgdstr{l+1} = 'Seadragon';
lgd = legend(lgdstr,'location','NorthOutside','orientation','horizontal'); title(lgd,'ITP')


% plot features
geobasemap grayland
geolimits([68 78],[-160 -120]);
