%% play_owtt_range_gvel.m
clear;

% eeshan bhatt

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

%% loop through toby tests

for itt = 1:nTobyTest
    
    %% comms
    A = load([listing_toby_test(itt).folder '/' listing_toby_test(itt).name]);
    
    nameString = extractBefore(listing_toby_test(itt).name,'.');
    nameString = split(nameString,'_');
    if length(nameString) == 4
        nameString = sprintf('toby test %s',nameString{4});
    else
        nameString = sprintf('toby test %s.%s',nameString{4},nameString{5});
    end
    
    % A.comms.h*.event   : src, dest, arr_time, ref_sec, travel_time 
    % A.comms.h*.nav     : time, lat, lon, depth, x, y, z
    % A.comms.h*.src_nav : time, lat, lon, depth, x, y, z
    
    comm_ids = {'h1','h2','h3','h4','macrura_10k'};
    nIDs = length(comm_ids);
    tx_rx_owtt=cell(5,5);
    oneWayTravelTime = [];
    
    for k = 1:nIDs
        
        %[tx_rx_owtt] = h_sort_tx_rx(A.comms,comm_ids,tx_rx_owtt);
        
        [owttByReceiver{k}] = h_get_owtt(A.comms, comm_ids{k});
        oneWayTravelTime = [oneWayTravelTime owttByReceiver{k}];
    end

    
    %% make KDE
    [F,XI]=ksdensity(oneWayTravelTime,'support','positive','NumPoints',1000,'function','pdf','bandwidth',2.^(-5));
    
    % subplot
    subplot(3,3,itt)
    plot(XI,F);
    title(nameString)
    
end

% subplot 1: map of h* lat/lon





% subplot 2: map of tx/rx by depth



% subplot 3: 



% subplot 4:






%% helper function
function [owtt] = h_get_owtt(modem,id)

if isfield(modem,id)
    for k = 1:length(modem.(id).event)
        owtt(k) = modem.(id).event{k}.travel_time;
    end
else
    owtt = [];
end

end

%% helper function : h_sort_tx_rx
function [tx_rx_owtt] = h_sort_tx_rx(modem,id,tx_rx_owtt)

num_id = length(id);

for ni = 1:num_id
    % check if modem id exists in batch
    
    temp_id = id{ni};
    if isfield(modem,temp_id)
        num_contacts = length(modem.(temp_id).event);
        
        for nc = 1:num_contacts
            src = modem.(temp_id).event{nc}.src;
            
            % map back modem ids to array index
            % h1,h2,h3,h4,macrura_10k
            if src == 4
                src = 5;
            elseif src > 9
                src = src - 9;
            end
            
            tt = modem.(temp_id).event{nc}.travel_time;
            tx_rx_owtt{src,ni}(end+1) = tt;
        end
    end
end
end
