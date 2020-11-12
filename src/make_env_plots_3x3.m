%% make_env_plots.m
% eeshan bhatt
% eesh@mit.edu

%% prep workspace
clear; clc;

%% load CTD data

load('~/.dropboxmit/icex_2020_mat/bradli_casts_cleaned_ecb.mat');
request_lat = 71.183; request_lon = -142.405 + 360;

%% prep HYCOM
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

%% prep ITPs --- ITP103 and ITP119

listing = dir('~/.dropboxmit/icex_2020_mat/itp-files/itp*grd*.dat');

itp_search.filepath = strings(length(listing),1);
itp_search.machine = strings(length(listing),1);
itp_search.lon = zeros(length(listing),1);
itp_search.lat = zeros(length(listing),1);
itp_search.time = zeros(length(listing),1);

% make list of locations, times, and paths
for cc = 1:length(listing)
    dat_file_path = fullfile(listing(cc).folder, listing(cc).name);
    
    itp_search.filepath(cc)   = dat_file_path;
    info                        = itp_import_loc(dat_file_path);
    
    itp_search.lon(cc)        = info.lon;
    itp_search.lat(cc)        = info.lat;
    itp_search.time(cc)       = datenum([info.year 0 info.day 0 0 0]);
    itp_search.machine(cc)    = listing(cc).name(1:6);
end

num_check = 3;
itp_c = cell(length(CTD),num_check);
itp_z = cell(length(CTD),num_check);

disp('finished ITP search! \n');


%% loop through CTDs
for p = 1:length(CTD)
    
    % ctd info
    ind_below = find(CTD(p).raw_z > 2);
    
    ctd_z{p} = CTD(p).raw_z(ind_below);
    ctd_c{p} = CTD(p).raw_c(ind_below);
    ctd_t(p) = datenum(CTD(p).time,'DD-mmm-yy HHMM');
    
    addpath(genpath('./eof_play/'));
    eof_filepath = '~/.dropboxmit/icex_2020_mat/eeof_itp_Mar2013.nc';
    [ctd_weight{p},ctd_eofnum{p},yhat{p}] = generate_coeffs_plot(ctd_z{p},ctd_c{p},eof_filepath);
    
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
    
    %% itp info
    
    % pick "nearest neighbor" by z-score
    
    z_lat = (itp_search.lat - request_lat)./std(itp_search.lat);
    z_lon = (itp_search.lon - (request_lon - 360))./std(itp_search.lon);
    z_time = (itp_search.time - request_time)./std(itp_search.time);
    
    z_total = 1.*abs(z_time) + 3.*abs(z_lat) + abs(z_lon);
    [B,best_index] = sort(z_total,'ascend');
    
    count = 0;
    for lp = 1:num_check
        num_obs = 0;
        while (num_obs < 200)
            count = count + 1;
            [~,~,pressure,temp,salinity,~] = importfile_itp(itp_search.filepath(best_index(count)));
            num_obs = length(pressure);
            
            itp_z{p,lp} = pressureToDepth(pressure,itp_search.lat(best_index(count)));
            itp_c{p,lp} = snd_spd(pressure,temp,salinity,'chen');
            
            best_itp_lat(p,lp) = itp_search.lat(best_index(count));
            best_itp_lon(p,lp) = itp_search.lon(best_index(count));
            best_itp_time(p,lp) = itp_search.time(best_index(count));
            best_itp_name(p,lp) = itp_search.machine(best_index(count));
        end
    end
    
    
    
    
end

%% write to a figure

figure(1); clf;
ha = tight_subplot(1,4,[.06 .03],[.1 .05],[.1 .02]);

eeof_depths  = double(ncread(eof_filepath,'depth'));

pcount = 0;
for p = [1 4 5 8]
    
    pcount = pcount + 1;
    % get figure
    axes(ha(pcount));
    
    if strcmp(CTD(p).type,'rsk')
        color = [153 51 153]./256;
    elseif strcmp(CTD(p).type,'xctd')
        color = [200 87 0]./256;
    end
    
    p_hycom = plot(hycom_c{p},hycom_z{p},'color',[181 181 181 220]./256,'linewidth',3);
    hold on
    for lp = 1:num_check
        p_itp = plot(itp_c{p,lp},itp_z{p,lp},'color',[5 119 177 80]./256,'linewidth',3);
    end
    p_ctd = plot(ctd_c{p},ctd_z{p},'-','color',color,'linewidth',3);
    
    % plot EOF -- 
    p_eof = plot(yhat{p},eeof_depths, 'ko');
    
    hold off
    
    beautify_plot();
    title(datestr(ctd_t(p),'DD mmm yy HHMM'));
    
    if p > 1
        yticklabels('');
    end
    
    
    xlabel('c [m/s]')

    
    if p == 1
        ylabel('depth [m]');
    end
    
    if p == 1
        legend([p_ctd p_hycom p_itp p_eof],'RSK','HYCOM','ITP','EOF','location','best')
    elseif p==5
        legend([p_ctd p_hycom p_itp p_eof],'xCTD','HYCOM','ITP','EOF','location','best');
    end
end

%% helper function: find_start
function [loc] = find_start(list,val)
[~,loc] = min(abs(list-val));
end

%% helper function: beautify_plot()
function [] = beautify_plot();
set(gca,'ydir','reverse')
grid on
ylim([0 500])
xlim([1425 1465])
end