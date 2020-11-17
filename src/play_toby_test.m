%% play_toby_test.m

%% directory
dir_toby_test = '~/.dropboxmit/icex_2020_mat/toby_test_sorted/*.mat';
listing = dir(dir_toby_test);

% macrura   modem ID = 4  -- ignore this for now?
% h1        modem ID = 10
% h2        modem ID = 11
% h3        modem ID = 12
% h4        modem ID = 13

dir_group_velocity = '~/.dropboxmit/icex_ipynb/gvels_by_node.mat';
load(dir_group_velocity);
gvels_topside = gvels_by_node.hydrohole;
gvels_macrura = gvels_by_node.macrura;

%% plot -- group velocities



%% plot -- grid of tx/rx

for ld = 4
    
    filename = [listing(ld).folder '/' listing(ld).name];
    
    disp(listing(ld).name);
    
    A = load(filename);
    
    % print time?
    t0 = A.nav.toby_test.time(1);
    tf = A.nav.toby_test.time(end);
    
    fprintf('%s to %s \n', h_convertTime(t0,1), h_convertTime(tf,1));
    
    tx_rx_owtt=cell(5,5);
    
    % sort h1, h2, h3, h4
    [tx_rx_owtt] = h_sort_tx_rx(A.comms.h1,1,tx_rx_owtt);
    [tx_rx_owtt] = h_sort_tx_rx(A.comms.h2,2,tx_rx_owtt);
    [tx_rx_owtt] = h_sort_tx_rx(A.comms.h3,3,tx_rx_owtt);
    [tx_rx_owtt] = h_sort_tx_rx(A.comms.h4,4,tx_rx_owtt);
    [tx_rx_owtt] = h_sort_tx_rx(A.comms.macrura_10k,5,tx_rx_owtt);
    
end

%% plot

figure(1);clf;

ha = tight_subplot(5,5,.05,.08,.08);

count_rr_tt = 0;
for rr = 1:5
    for tt = 1:5
        
        count_rr_tt = count_rr_tt + 1;
        
        axes(ha(count_rr_tt));
        
        num_contacts = length(tx_rx_owtt{rr,tt});
        
        
        if num_contacts > 0
            vals = tx_rx_owtt{rr,tt};
            histogram(vals,ceil(exp(1).*sqrt(num_contacts)))
        end
        
        if rr == 1
            title(['tx_' num2str(tt)])
        end
        
        if tt == 1
            ylabel(['rx_' num2str(rr)])
        end
        
    end
end

%% helper function : h_sort_tx_rx
function [tx_rx_owtt] = h_sort_tx_rx(H,n,tx_rx_owtt)

num_contacts = length(H.event);

% srcID = [10 11 12 13];
%          h1 h2 h3 h4

for nc = 1:num_contacts
    src = H.event{nc}.src;
    
    if src == 4
        src = 5;
    elseif src > 9
        src = src - 9;
    end
    
    tt = H.event{nc}.travel_time;
    tx_rx_owtt{src,n}(end+1) = tt;
    
end
end