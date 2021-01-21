function [OBJ] = h_unpack_experiment(experiment)
% h_unpack_experiment
%   loads toby test recap in a format to easily play with

% one way travel time data
OBJ.data_owtt = h_get_nested_val_filter(experiment,'tag','owtt');
OBJ.sim_owtt = h_get_nested_val_filter(experiment,'gvel','delay');

data_filter = OBJ.data_owtt >= 0.8 & OBJ.data_owtt <= 3; % hack to isolate direct path -- need to specify non-direct vs direct path
sim_filter = OBJ.sim_owtt ~= 0;
t_filter = boolean(data_filter .* sim_filter);

OBJ.data_owtt = h_get_nested_val_filter(experiment,'tag','owtt',t_filter);

% gps data to range
OBJ.tx_x    = h_get_nested_val_filter(experiment,'tx','x',t_filter);
OBJ.tx_y    = h_get_nested_val_filter(experiment,'tx','y',t_filter);
OBJ.tx_z    = h_get_nested_val_filter(experiment,'tx','depth',t_filter);

OBJ.rx_x    = h_get_nested_val_filter(experiment,'rx','x',t_filter);
OBJ.rx_y    = h_get_nested_val_filter(experiment,'rx','y',t_filter);
OBJ.rx_z    = h_get_nested_val_filter(experiment,'rx','depth',t_filter);

dist3 = @(px,py,pz,qx,qy,qz) ...
    sqrt((px - qx).^2 + ...
    (py - qy).^2 + ...
    (pz - qz).^2 );

OBJ.data_3D_range = dist3(OBJ.tx_x,OBJ.tx_y,OBJ.tx_z,OBJ.rx_x,OBJ.rx_y,OBJ.rx_z);
OBJ.data_range = dist3(OBJ.tx_x,OBJ.tx_y,zeros(size(OBJ.tx_x)),OBJ.rx_x,OBJ.rx_y,zeros(size(OBJ.rx_x)));

OBJ.sim_owtt = h_get_nested_val_filter(experiment,'gvel','delay',t_filter);

% lat/lon data
OBJ.tx_lat          = h_get_nested_val_filter(experiment,'tx','lat',t_filter);
OBJ.tx_lon          = h_get_nested_val_filter(experiment,'tx','lon',t_filter);
OBJ.rx_lat          = h_get_nested_val_filter(experiment,'rx','lat',t_filter);
OBJ.rx_lon          = h_get_nested_val_filter(experiment,'rx','lon',t_filter);

OBJ.data_time = h_get_nested_val_filter(experiment,'tag','time',t_filter);

% get in-situ simulation data
OBJ.sim_range       = h_get_nested_val_filter(experiment,'gvel','range',t_filter);
OBJ.sim_owtt        = h_get_nested_val_filter(experiment,'gvel','delay',t_filter);
OBJ.sim_gvel        = h_get_nested_val_filter(experiment,'gvel','gvel',t_filter);
OBJ.sim_gvel_std    = h_get_nested_val_filter(experiment,'gvel','gvelstd',t_filter);
OBJ.sim_time        = h_get_nested_val_filter(experiment,'gvel','time',t_filter);

OBJ.gvel_med        = median(OBJ.sim_gvel,'omitnan');
OBJ.gvel_mean       = mean(OBJ.sim_gvel,'omitnan');
OBJ.gvel_num        = sum(~isnan(OBJ.sim_gvel));

% get tx/rx tags
OBJ.tag_tx          = h_get_nested_val_filter(experiment,'tag','src',t_filter);
OBJ.unique_tx       = sort(unique(OBJ.tag_tx));
OBJ.tag_rx          = h_get_nested_val_filter(experiment,'tag','rec',t_filter);
OBJ.unique_rx       = sort(unique(OBJ.tag_rx));
OBJ.num_events      = numel(OBJ.tag_tx);

% sound speed estimate
toby_test_eof_bool = h_get_nested_val_filter(experiment,'tag','eeof',t_filter);
OBJ.eof_bool = boolean(toby_test_eof_bool);
if mode(toby_test_eof_bool) == mean(toby_test_eof_bool)
    eof_bool = toby_test_eof_bool(1);
    OBJ_EOF = eb_read_eeof('eeof_itp_Mar2013.nc',true);
    weights = [-10 -9.257 -1.023 3.312 -5.067 1.968 1.47].'; % manually written down weights from Toby's notes
    OBJ.ssp_estimate = OBJ_EOF.baseval + (OBJ_EOF.eofs * weights).*eof_bool;
    OBJ.ssp_depth    = OBJ_EOF.depth;
end

end



