%% main_collate_toby_test_data.m

% runs through each toby_test file and creates new working files by event
% outputs a new mat file for each toby test:
% tx: x,y,z,lat,lon,name,id,time
% rx: x,y,z,lat,lon,name,id,time
% info: range, gvel, gvelstd

clear; clc;

%% load group velocity data
dir_group_velocity = '~/.dropboxmit/icex_ipynb/gvels_by_node.mat';
load(dir_group_velocity);
gvels_topside = gvels_by_node.hydrohole;
gvels_macrura = gvels_by_node.macrura;
clear gvels_by_node

%% load toby test data
dir_toby_test = '~/.dropboxmit/icex_2020_mat/toby_test_sorted/*.mat';
listing_toby_test = dir(dir_toby_test);
nTobyTest = length(listing_toby_test);

%% loop through each toby test

comm_lbls = {'h1','h2','h3','h4','macrura_10k'};
comm_ids  = [  10  11   12   13        4       ];
num_comm_ids = length(comm_lbls);

for itt = 1
    A = load([listing_toby_test(itt).folder '/' listing_toby_test(itt).name]);
    
    % fix naming convention
    nameString = extractBefore(listing_toby_test(itt).name,'.');
    nameString = split(nameString,'_');
    if length(nameString) == 4
        nameString = sprintf('toby test %s',nameString{4});
    else
        nameString = sprintf('toby test %s.%s',nameString{4},nameString{5});
    end
    
    % go by event for each comm id
    count = 0;
    for iNCI = 1:num_comm_ids
        temp_id = comm_lbls{iNCI};
        
        if isfield(A.comms,temp_id)
            
            num_events = length(A.comms.(temp_id).event);
            
            for iNE = 1:num_events
                count = count + 1;
                
                % information from comms.(*).event
                event(count).info.time  = h_convertTime(A.comms.(temp_id).event{iNE}.arr_time,0);
                event(count).info.tstr  = h_convertTime(A.comms.(temp_id).event{iNE}.arr_time,1);
                event(count).info.src   = A.comms.(temp_id).event{iNE}.src;
                event(count).info.dest  = A.comms.(temp_id).event{iNE}.dest;
                event(count).info.rec   = comm_ids(iNCI);
                event(count).info.owtt  = A.comms.(temp_id).event{iNE}.travel_time;
                
                event(count).tx.id = A.comms.(temp_id).event{iNE}.src;
               
                % information from comms.(*).nav
                
                event(count).rx.id      = comm_ids(iNCI);
                event(count).rx.name    = A.comms.(temp_id).nav{iNE}.name;
                event(count).rx.x       = str2double(A.comms.(temp_id).nav{iNE}.x);
                event(count).rx.y       = str2double(A.comms.(temp_id).nav{iNE}.y);
                event(count).rx.z       = A.comms.(temp_id).nav{iNE}.z;
                event(count).rx.lat     = str2double(A.comms.(temp_id).nav{iNE}.lat);
                event(count).rx.lon     = str2double(A.comms.(temp_id).nav{iNE}.lon);
                event(count).rx.depth   = str2double(A.comms.(temp_id).nav{iNE}.depth);
                event(count).rx.time    = h_convertTime(A.comms.(temp_id).nav{iNE}.time,0);

                % information from comms.(*).src_nav
                event(count).tx.name    = A.comms.(temp_id).src_nav{iNE}.name;
                event(count).tx.x       = str2double(A.comms.(temp_id).src_nav{iNE}.x);
                event(count).tx.y       = str2double(A.comms.(temp_id).src_nav{iNE}.y);
                event(count).tx.z       = A.comms.(temp_id).src_nav{iNE}.z;
                event(count).tx.lat     = str2double(A.comms.(temp_id).src_nav{iNE}.lat);
                event(count).tx.lon     = str2double(A.comms.(temp_id).src_nav{iNE}.lon);
                event(count).tx.depth   = A.comms.(temp_id).src_nav{iNE}.depth;
                event(count).tx.time    = h_convertTime(A.comms.(temp_id).src_nav{iNE}.time,0);
                
                % book keeping tag
                event(count).tag = nameString;
            end       
        end 
    end
end