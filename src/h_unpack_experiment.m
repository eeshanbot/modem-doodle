function [OBJ] = h_unpack_experiment(experiment)
%h_load_ttrecap
%   loads toby test recap in a format to easily play with

% one way travel time data
OBJ.data_owtt = h_get_nested_val_filter(experiment,'tag','owtt');

% gps data to range
OBJ.tx_x    = h_get_nested_val_filter(experiment,'tx','x');
OBJ.tx_y    = h_get_nested_val_filter(experiment,'tx','y');
OBJ.tx_z    = h_get_nested_val_filter(experiment,'tx','depth');

OBJ.rx_x    = h_get_nested_val_filter(experiment,'rx','x');
OBJ.rx_y    = h_get_nested_val_filter(experiment,'rx','y');
OBJ.rx_z    = h_get_nested_val_filter(experiment,'rx','depth');

dist3 = @(px,py,pz,qx,qy,qz) ...
    sqrt((px - qx).^2 + ...
    (py - qy).^2 + ...
    (pz - qz).^2 );

OBJ.data_3D_range = dist3(OBJ.tx_x,OBJ.tx_y,OBJ.tx_z,OBJ.rx_x,OBJ.rx_y,OBJ.rx_z);
OBJ.data_range = dist3(OBJ.tx_x,OBJ.tx_y,zeros(size(OBJ.tx_x)),OBJ.rx_x,OBJ.rx_y,zeros(size(OBJ.rx_x)));

OBJ.sim_owtt = h_get_nested_val_filter(experiment,'gvel','delay');

% lat/lon data
OBJ.tx_lat          = h_get_nested_val_filter(experiment,'tx','lat');
OBJ.tx_lon          = h_get_nested_val_filter(experiment,'tx','lon');
OBJ.rx_lat          = h_get_nested_val_filter(experiment,'rx','lat');
OBJ.rx_lon          = h_get_nested_val_filter(experiment,'rx','lon');

OBJ.data_time = h_get_nested_val_filter(experiment,'tag','time');

% get in-situ simulation data
OBJ.sim_range       = h_get_nested_val_filter(experiment,'gvel','range');
OBJ.sim_owtt        = h_get_nested_val_filter(experiment,'gvel','delay');
OBJ.sim_gvel        = h_get_nested_val_filter(experiment,'gvel','gvel');
OBJ.sim_gvel_std    = h_get_nested_val_filter(experiment,'gvel','gvelstd');
OBJ.sim_time        = h_get_nested_val_filter(experiment,'gvel','time');

OBJ.gvel_med        = median(OBJ.sim_gvel,'omitnan');
OBJ.gvel_mean       = mean(OBJ.sim_gvel,'omitnan');
OBJ.gvel_num        = sum(~isnan(OBJ.sim_gvel));

% get tx/rx tags
OBJ.tag_tx          = h_get_nested_val_filter(experiment,'tag','src');
OBJ.unique_tx       = sort(unique(OBJ.tag_tx));
OBJ.tag_rx          = h_get_nested_val_filter(experiment,'tag','rec');
OBJ.unique_rx       = sort(unique(OBJ.tag_rx));
OBJ.num_events      = numel(OBJ.tag_tx);

% sound speed estimate
toby_test_eof_bool = h_get_nested_val_filter(experiment,'tag','eeof');
OBJ.eof_bool = boolean(toby_test_eof_bool);
eof_bool = toby_test_eof_bool(1);
OBJ_EOF = eb_read_eeof('eeof_itp_Mar2013.nc',true);
weights = [-10 -9.257 -1.023 3.312 -5.067 1.968 1.47].'; % manually written down weights from Toby's notes
OBJ.ssp_estimate = OBJ_EOF.baseval + (OBJ_EOF.eofs * weights).*eof_bool;
OBJ.ssp_depth    = OBJ_EOF.depth;
end

