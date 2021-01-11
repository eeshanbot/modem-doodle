function [plotBathy] = h_unpack_bathy(bathyfile)
%h_unpack_bathy

% from cruise.def --- March 10th 1530 (only used for plotting purposes)
plotBathy.olat = 71.17733;
plotBathy.olon = -142.40413;

% manual controls
min_lat = 71.15; max_lat = 71.2;
min_lon = -142.48; max_lon = -142.33;

% load
lat = ncread(bathyfile,'lat');
lon = ncread(bathyfile,'lon');
bathy = ncread(bathyfile,'Band1');

% index
ilat1 = find(lat<=min_lat,1,'last');
ilat2 = find(lat>=max_lat,1,'first');
ilon1 = find(lon<=min_lon,1,'last');
ilon2 = find(lon>=max_lon,1,'first');
plot_lon = lon(ilon1:ilon2);
plot_lat = lat(ilat1:ilat2);
[latgrid,longrid] = meshgrid(plot_lat,plot_lon);

% object
plotBathy.zz = abs(bathy(ilon1:ilon2,ilat1:ilat2));
plotBathy.mean = round(mean(plotBathy.zz(:)));
[plotBathy.xx,plotBathy.yy] = eb_ll2xy(latgrid,longrid,plotBathy.olat,plotBathy.olon);

%[plotBathy.rxX,plotBathy.rxY] = eb_ll2xy(rx_lat,rx_lon,olat,olon);
%[plotBathy.txX,plotBathy.txY] = eb_ll2xy(tx_lat,tx_lon,olat,olon);
end

