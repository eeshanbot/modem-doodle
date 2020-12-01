%% main_collate_toby_test_data.m

% runs through each toby_test file and creates new working files by event
% outputs a new mat file for each toby test:
% 
% tag       owtt, src, dest, rec, name, gvelNode, tstr, time
% tx        id, name, x, y, z, lat, lon, depth, time
% rx        id, name, x, y, z, lat, lon, depth, time
% sim       owtt, range, gvel, gvelstd

clear; clc;

%% load group velocity data
dir_group_velocity = '~/.dropboxmit/icex_ipynb/gvels_by_node.mat';
load(dir_group_velocity);
gvel_macrura = gvels_by_node.macrura;
clear gvels_by_node

% transform gvel_macrura structure, so it can be easily searched
gvel_lbls = {'h1','h2','h3','h4'};
num_gvel_lbls = length(gvel_lbls);

for iGL = 1:num_gvel_lbls
    temp = [gvel_macrura.(gvel_lbls{iGL}){:}];
    gvel_macrura.(gvel_lbls{iGL}) = temp;
end
clear temp;

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
                event(count).tag.owtt       = A.comms.(temp_id).event{iNE}.travel_time;
                event(count).tag.src        = A.comms.(temp_id).event{iNE}.src;
                event(count).tag.dest       = A.comms.(temp_id).event{iNE}.dest;
                event(count).tag.rec        = comm_ids(iNCI);
                event(count).tag.name       = nameString;
                event(count).tag.tstr       = h_convertTime(A.comms.(temp_id).event{iNE}.arr_time,1);
                event(count).tag.time       = h_convertTime(A.comms.(temp_id).event{iNE}.arr_time,0);
                
                event(count).tx.id          = A.comms.(temp_id).event{iNE}.src;

                % information from comms.(*).src_nav
                event(count).tx.name        = A.comms.(temp_id).src_nav{iNE}.name;
                event(count).tx.x           = smartI2D(A.comms.(temp_id).src_nav{iNE}.x);
                event(count).tx.y           = smartI2D(A.comms.(temp_id).src_nav{iNE}.y);
                event(count).tx.z           = A.comms.(temp_id).src_nav{iNE}.z;
                event(count).tx.lat         = smartI2D(A.comms.(temp_id).src_nav{iNE}.lat);
                event(count).tx.lon         = smartI2D(A.comms.(temp_id).src_nav{iNE}.lon);
                event(count).tx.depth       = A.comms.(temp_id).src_nav{iNE}.depth;
                event(count).tx.time        = h_convertTime(A.comms.(temp_id).src_nav{iNE}.time,0);
                
                % information from comms.(*).nav
                event(count).rx.id          = comm_ids(iNCI);
                event(count).rx.name        = A.comms.(temp_id).nav{iNE}.name;
                event(count).rx.x           = smartI2D(A.comms.(temp_id).nav{iNE}.x);
                event(count).rx.y           = smartI2D(A.comms.(temp_id).nav{iNE}.y);
                event(count).rx.z           = A.comms.(temp_id).nav{iNE}.z;
                event(count).rx.lat         = smartI2D(A.comms.(temp_id).nav{iNE}.lat);
                event(count).rx.lon         = smartI2D(A.comms.(temp_id).nav{iNE}.lon);
                event(count).rx.depth       = smartI2D(A.comms.(temp_id).nav{iNE}.depth);
                event(count).rx.time        = h_convertTime(A.comms.(temp_id).nav{iNE}.time,0);
                
                % necessary variables for getting gvel information
                % t0 = time, pointer = node
                t0 = event(count).tag.time;
                if comm_ids(iNCI) > 5
                    node = event(count).rx.name;
                elseif comm_ids(iNCI) == 4
                    node = event(count).tx.name;
                end
        
                % information from gvels_macrura - filter by src AND time
                event(count).sim.gvelNode  = node; 
                
                time_array = h_convertTime(get_nested_val(gvel_macrura,node,'timestamp'),0);
                [~,index] = min(abs(time_array-t0));
                
                event(count).sim.range     = gvel_macrura.(node)(index).range;
                event(count).sim.delay     = gvel_macrura.(node)(index).delay;
                event(count).sim.gvel      = gvel_macrura.(node)(index).group_velocity;
                event(count).sim.gvelstd   = gvel_macrura.(node)(index).group_velocity_std;
                event(count).sim.src       = gvel_macrura.(node)(index).source;
                event(count).sim.rec       = gvel_macrura.(node)(index).receiver;
                event(count).sim.time      = h_convertTime(gvel_macrura.(node)(index).timestamp,0);
            end       
        end 
    end
end

%% helper function : get_nested_val();
% get a nested value as an array over all structs
function [array] = get_nested_val(obj,lvl1,lvl2)
stuff = [obj.(lvl1)];
array = [stuff.(lvl2)];
end

%% helper function : smart_input2double();
% not all data inputs are saved as strings... this checks before
% converting, otherwise you get a NaN
function [dbl] = smartI2D(input)

% class(input)

if isa(input,'char')
   dbl = str2double(input);
elseif isa(input,'double')
   dbl = input;
else
   dbl = double(input);
end

end