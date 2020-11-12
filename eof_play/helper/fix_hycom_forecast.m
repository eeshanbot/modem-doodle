%% fix_hycom_forecast.m
% eeshan bhatt | eesh (at) mit (dot) edu
% LAMSS - Dr. Henrik Schmidt
% Feb 2020

%% setup
clear; clc;

warning('this is dangerous!!');

loc = '../../../../missions-lamss/cruise/icex20/data/environment/ocean_files/*.nc';
[file,path] = uigetfile(loc,'please pick the original TS file');
tsfile = [path file];

[file,path] = uigetfile(loc, 'please pick the original UV file');
uvfile = [path file];

%% duplicate files

new_ts = [path 'hacked_ts.nc'];
new_uv = [path 'hacked_uv.nc'];

copyfile(tsfile,new_ts);
copyfile(uvfile,new_uv);

%% add attributes for ts file

% salinity
fileattrib(new_ts,'+w');
ncwriteatt(new_ts,'salinity','missing_value',-30000);
ncwriteatt(new_ts,'salinity','scale_factor',1);
ncwriteatt(new_ts,'salinity','add_offset',0);

% water_temp
ncwriteatt(new_ts,'water_temp','missing_value',-30000);
ncwriteatt(new_ts,'water_temp','scale_factor',1);
ncwriteatt(new_ts,'water_temp','add_offset',0);

%% add attributes for uv file

% u
fileattrib(new_uv,'+w');
ncwriteatt(new_uv,'water_u','missing_value',-30000);
ncwriteatt(new_uv,'water_u','scale_factor',0.001);
ncwriteatt(new_uv,'water_u','add_offset',0);

% v
ncwriteatt(new_uv,'water_v','missing_value',-30000);
ncwriteatt(new_uv,'water_v','scale_factor',0.001);
ncwriteatt(new_uv,'water_v','add_offset',0);

%% fix time?

ncreadatt(tsfile,'time','units')
ncreadatt(uvfile,'time','units')

bool = input('\n confirm these are the same timestamp: [1/0] ');
if bool
    time = ncread(tsfile,'time');
    n_yr = input('\nplease enter the year: ');
    n_mth = input('\nplease enter the month: ');
    n_day = input('\nplease enter the day: ');
    n_hr = input('\nplease enter the hour: ');
    n_min = input('\nplease enter the min: ');
    n_sec = input('\nplease enter the sec: ');
    
    standard_time = [2000 1 1 0 0 0];
    new_time = [n_yr n_mth n_day n_hr n_min n_sec];
    diff_time = etime(new_time, standard_time)/3600;
    
    ncwrite(new_ts,'time',time+diff_time);
    ncwrite(new_uv,'time',time+diff_time);
    
    ncwriteatt(new_ts,'time','units','hours since 2000-01-01 00:00:00 UTC');
    ncwriteatt(new_uv,'time','units','hours since 2000-01-01 00:00:00 UTC');
    
    fprintf('run the following command for BOTH new files: \n')
    fprintf('cdo -delete,var=time_run <infile> <outfile> \n');
    
else
    warning('do not continue... deleting files');
    delete(new_ts);
    delete(new_uv);
end

% forecast_time_origin = 