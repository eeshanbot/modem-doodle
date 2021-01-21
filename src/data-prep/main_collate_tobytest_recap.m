%% main_collate_tobytest_recap.m

% runs through tobytest_recap and creates new working files by
% tx depth and EOF status
% outputs a new mat file for each comparison
%
% tag       owtt, src, dest, rec, ttNum, tstr, time, eeof
% tx        id, name, x, y, z, lat, lon, depth, time
% rx        id, name, x, y, z, lat, lon, depth, time
% sim       owtt, range, gvel, gvelstd

clear; clc;

%% load toby test recap
load('~/.dropboxmit/icex_2020_mat/toby_test_recap.mat');
A = good_events;
clear good_events;
num_events = length(A);

addpath('../');

%% convert to indexed structure (helper script reads this style)
no_gvel_info_count = 0;
for k = 1:num_events

   % information for event.tag 
   event(k).tag.owtt    = smartI2D(A{k}.travel_time);
   event(k).tag.src     = A{k}.tx;
   event(k).tag.dest    = smartI2D(A{k}.dest);
   event(k).tag.rec     = A{k}.rx;
   event(k).tag.ttNum   = A{k}.test_num;
   event(k).tag.tstr    = h_convertTime(A{k}.arr_time,1);
   event(k).tag.time    = h_convertTime(A{k}.arr_time,0);
   
   if strcmp(A{k}.test_mode,'eeof')
        event(k).tag.eeof    = 1;
   elseif strcmp(A{k}.test_mode,'base')
        event(k).tag.eeof    = 0;
   end
   
   % information for event.tx
   event(k).tx.name     = A{k}.tx_nav.name;
   event(k).tx.x        = A{k}.tx_nav.x;
   event(k).tx.y        = A{k}.tx_nav.y;
   event(k).tx.z        = A{k}.tx_depth;
   event(k).tx.lat      = A{k}.tx_nav.lat;
   event(k).tx.lon      = A{k}.tx_nav.lon;
   event(k).tx.depth    = smartI2D(A{k}.tx_depth);
   event(k).tx.time     = A{k}.tx_nav.time;
   
   % information for event.rx
   event(k).rx.name     = A{k}.rx_nav.name;
   event(k).rx.x        = A{k}.rx_nav.x;
   event(k).rx.y        = A{k}.rx_nav.y;
   event(k).rx.z        = A{k}.rx_nav.z;
   event(k).rx.lat      = A{k}.rx_nav.lat;
   event(k).rx.lon      = A{k}.rx_nav.lon;
   event(k).rx.depth    = smartI2D(A{k}.rx_nav.depth);
   event(k).rx.time     = A{k}.rx_nav.time;
   
   % information for event.gvel
   if isfield(A{k},'gvel')
       event(k).gvel.range  = smartI2D(A{k}.gvel.range);
       event(k).gvel.delay  = smartI2D(A{k}.gvel.delay);
       event(k).gvel.gvel   = smartI2D(A{k}.gvel.group_velocity);
       event(k).gvel.gvelstd= smartI2D(A{k}.gvel.group_velocity_std);
       event(k).gvel.src    = A{k}.gvel.source;
       event(k).gvel.rec    = A{k}.gvel.receiver;
       event(k).gvel.time   = h_convertTime(A{k}.gvel.timestamp,0);
       event(k).gvel.status = true;
   else
       event(k).gvel.range  = NaN;
       event(k).gvel.delay  = NaN;
       event(k).gvel.gvel   = NaN;
       event(k).gvel.gvelstd= NaN;
       event(k).gvel.src    = NaN;
       event(k).gvel.rec    = NaN;
       event(k).gvel.time   = NaN;
       event(k).gvel.status = false;
       no_gvel_info_count = no_gvel_info_count + 1;
   end
end

%% some manual cleaning of dataset
bad_events = [];
for k = 1:num_events
    node = event(k).tag.rec;
    owtt = event(k).tag.owtt;
    
    % clock error that can't be corrected by CAIRE messages
    % CAMP RX, owtt = 2.0577 (should be 1.0577ish)
    if strcmp(node,'Camp') && owtt > 2.05
        warn_str = sprintf('1: removed k = %d, rx node = %s, owtt = %2.4f',k,node,owtt);
        warning(warn_str);
        
        bad_events(end+1) = k;
    end
    
    % event that is 0.7601 seconds, Bellhop cannot find arrival, must be
    % clock error
    if strcmp(node,'West') && owtt < 0.8
        warn_str = sprintf('2: removed k = %d, rx node = %s, owtt = %2.4f',k,node,owtt);
        warning(warn_str);
        
        bad_events(end+1) = k;
    end
end

event(bad_events) = [];

%% save file
save('tobytest-recap-clean','event');

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