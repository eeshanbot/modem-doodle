%% test_bathy
clear; clc;

% filename
bathyfile = '~/missions-lamss/cruise/icex20/data/environment/noaa_bathy_file.nc';

lat = ncread(bathyfile,'lat');
lon = ncread(bathyfile,'lon');
bathy = ncread(bathyfile,'Band1');



