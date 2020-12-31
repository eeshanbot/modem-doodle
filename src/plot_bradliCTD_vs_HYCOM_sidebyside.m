%% make_env_plots.m
% eeshan bhatt
% eesh@mit.edu

%% prep workspace
clear; clc;

%% load data

% load Bradli's CTDs
load('~/.dropboxmit/icex_2020_mat/bradli_casts_cleaned_ecb.mat');
request_lat = 71.183; request_lon = -142.405 + 360;

% prep HYCOM
hycom_file_path = '~/.dropboxmit/icex_2020_mat/hycom-files/ts3z-hindcast-Mar3-Mar13.nc4';
hycom_lon = ncread(hycom_file_path,'lon');
hycom_lat = ncread(hycom_file_path,'lat');
hycom_depth = ncread(hycom_file_path,'depth');

hycom_time = ncread(hycom_file_path,'time');
att_time = ncreadatt(hycom_file_path,'time','units');
time0 = datevec(att_time(13:end-4));
for tt = 1:length(hycom_time)
    hycom_time(tt) = datenum([time0(1) time0(2) time0(3) time0(4)+hycom_time(tt) time0(5) time0(6)]);
end
clear tt;


%% make transect style plot
% transect(x,t,v) --- x = array, d = cell array, v = cell array

for p = 1:length(CTD)
    
    %% ctd info
    ind_below = find(CTD(p).raw_z > 1);
    
    ctd_z{p} = CTD(p).raw_z(ind_below);
    ctd_c{p} = CTD(p).raw_c(ind_below);
    ctd_t(p) = datenum(CTD(p).time,'DD-mmm-yy HHMM');
    
    request_depth = max(CTD(p).raw_z);
    request_time = datenum(ctd_t(p));
    
    %% hycom info    
    idx_lat = find_start(hycom_lat,request_lat);
    idx_lon = find_start(hycom_lon,request_lon);
    idx_z = find_start(hycom_depth,request_depth);
    idx_t = find_start(hycom_time,request_time);
    
    start = [idx_lat; idx_lon;       1;idx_t];
    count = [      2;       2; idx_z;      2];
    stride = [1; 1; 1; 1];
    
    S = ncread(hycom_file_path,'salinity',start,count,stride);
    T = ncread(hycom_file_path,'water_temp',start,count,stride);
    Z = hycom_depth(start(3):count(3));
    
    % convert to sound speed
    sizeSal = size(S);
    zmat = repmat(Z,[1 sizeSal([1 2 4])]);
    zmat = permute(zmat,[2 3 1 4]);
    
    filler = size(Z);
    
    C = snd_spd(zmat,T,S,'mackenzie',hycom_lat);
    
    % backup
    meanC = squeeze(mean(mean(mean(permute(C,[1 2 4 3]),'omitnan'),'omitnan'),'omitnan'));
    
    Cq = interpn(hycom_lat(idx_lat:idx_lat+1),hycom_lon(idx_lon:idx_lon+1),Z,hycom_time(idx_t:idx_t+1),...
        C,...
        request_lat.*ones(filler),request_lon.*ones(filler),Z,request_time.*ones(filler));
    
    if sum(isnan(Cq))>0
        Cq = meanC;
    end
    
    % write to cell array
    hycom_z{p} = squeeze(zmat(1,1,:,1));
    hycom_c{p} = Cq;
    
end

%% make a figure

figure(1); clf;
subplot(1,2,1)
hold on
for p = 1:length(ctd_z)
    plot(ctd_c{p},ctd_z{p},'color',[0.2 0.2 0.8 0.2],'linewidth',4)
end
hold off
beautify_plot();
title('CTD data')

subplot(1,2,2)
hold on
for p = 1:length(ctd_z)
    plot(hycom_c{p},hycom_z{p},'color',[0.2 0.2 0.8 0.2],'linewidth',4);
end
hold off
beautify_plot();
title('HYCOM hindcast');

%% helper function: find_start
function [loc] = find_start(list,val)
[~,loc] = min(abs(list-val));
end

%% helper function: beautify_plot()
function [] = beautify_plot();
set(gca,'ydir','reverse')
grid on
ylim([0 600])
xlim([1430 1465])
xlabel('c [m/s]')
ylabel('depth [m]')
end











