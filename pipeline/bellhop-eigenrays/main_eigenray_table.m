%% main_eigenray_table.m

%% prep workspace
clear; clc; close all;

%% load toby test data recap all
addpath('../');

load '../../data/tobytest-recap-clean.mat'
RECAP = h_unpack_experiment(event);

% filters :
filter_eof = unique(RECAP.eof_bool);
filter_txz = unique(RECAP.tx_z);
filter_rxz = unique(RECAP.rx_z);
filter_node = {'North','South','East','West','Camp'};

% report :      eof status
%               source depth
%               rx depth
%               rx node
%               rx range
%               owtt
%               owtt std
%               range

% counter
K = 0;

% over eof status
for fEOF = filter_eof
    index_eof = RECAP.eof_bool == fEOF;
    
    % over tx_depth
    for fTXZ = filter_txz
        index_txz = RECAP.tx_z == fTXZ;
        
        % over rx depth
        for fRXZ = filter_rxz
            index_rxz = RECAP.rx_z == fRXZ;
            
            % over rx node
            for fRXN = filter_node
                index_rxn = strcmp(RECAP.tag_rx,fRXN{1});
                
                for fTXN = filter_node
                    index_txn = strcmp(RECAP.tag_tx,fTXN{1});
                    
                    % compile index
                    index = boolean(index_eof .* index_txz .* index_rxz .* index_rxn .* index_txn);
                    
                    % if index is valid, find clusters and record
                    if sum(index)>=1
                        
                        OWTT = RECAP.data_owtt(index);
                        RANGE = RECAP.data_range(index);
                        
                        rnd_owtt = round(OWTT,2);
                        unq_owtt = unique(rnd_owtt)
                        numUO = numel(unq_owtt);
                        
                        % get cluster statistics
                        clear packet_* owtt_* range_*
                        for n = 1:numUO
                            idx_clust = (rnd_owtt == unq_owtt(n));
                            
                            owtt_mean(n) = mean(OWTT(idx_clust));
                            owtt_std(n)  = std(OWTT(idx_clust));
                            
                            range_mean(n) = mean(RANGE(idx_clust));
                            range_std(n)  = std(RANGE(idx_clust));
                            packet_num(n)  = sum(idx_clust);
                        end
                        
                        % output eigentable message
                        K = K + 1;
                        eigentable{K}.eof_status    = fEOF;
                        eigentable{K}.tx_node       = fTXN{1};
                        eigentable{K}.tx_z          = fTXZ;
                        eigentable{K}.rx_node       = fRXN{1};
                        eigentable{K}.rx_z          = fRXZ;
                        eigentable{K}.rx_r_mean     = range_mean;
                        eigentable{K}.rx_r_std      = range_std;
                        eigentable{K}.owtt_mean     = owtt_mean;
                        eigentable{K}.owtt_std      = owtt_std;
                        eigentable{K}.owtt_num      = packet_num;
                    end
                end
            end
        end
    end
end

clearvars -except eigentable
save('eigentable-v2.mat');