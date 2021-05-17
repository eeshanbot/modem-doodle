%% main_plot_raytrace_v2.m
% plots raytraces by each source depth for the three ssps

%% prep workspace
clear; clc; close all;

lg_font_size = 14;

myGray = [0.6 0.6 0.6];
alphaColor   = .2;

% depth_switch = [20 30 90];
zs = 90;

%% load modem marker info
load p_modemMarkerDetails

%% load all events
load('../data/tobytest-recap-clean.mat');
A = h_unpack_experiment(event);

load bellhop-eigenrays-3ssp/eigentable_flat.mat

%% load all sound speeds
path = './bellhop-gvel-gridded/';

file{1} = 'ssp-hycom.csv';
file{2} = 'ssp-fixed-baseval.csv';
file{3} = 'ssp-fixed-eeof.csv';

fileNames = {'HYCOM','Baseline','Chosen Weights'};
colorSet = {[152 134 117]./256,[232, 153, 35]./256,[0 85 135]./256};

for k = 1:3
    T = readtable([path file{k}]);
    ssp(k).depth = T.Var1;
    ssp(k).ssp   = T.Var2;
    ssp(k).name = fileNames{k};
    ssp(k).color = colorSet{k};
    temp = split(file{k},'.');
    ssp(k).filestr = temp{1};
end

%% make plot

figure('name','raytrace-all','renderer','painters','position',[108 108 1300 1050]);
t = tiledlayout(3,9,'TileSpacing','compact');

theta = [-49:2:-31 -30:1:30 31:2:49];
numstep = 1100;
sstep = 5;

for k = 1:3
    
    %% sound speed plot
    nexttile([1 2]);
    
    plot(ssp(k).ssp,ssp(k).depth,'linewidth',3,'color',myGray);
    set(gca,'ydir','reverse');
    grid on
    ylim([0 300]);
    xlim([1431 1463]);
    set(gca,'fontsize',12)
    ylabel('depth [m]');
    title(sprintf('SSP from %s',ssp(k).name));
    
    if k == 3
        xlabel('c [m/s]');
    end
    
    %% raytrace plot
    nexttile([1 7]);
    [R,Z,~] = eb_raytrace(zs,theta,numstep,sstep,ssp(k).depth,ssp(k).ssp,0,max(ssp(k).depth));
    
    plot(R.'/1000,Z.','color',[myGray alphaColor],'linewidth',2);
    set(gca,'ydir','reverse');
    ylim([0 300]);
    set(gca,'fontsize',12);
    yticklabels([]);
    
    if zs == 20
        xlim([0 2]);
    else
        xlim([0 3.5]);
    end
    
    title(sprintf('Raytrace with a source depth = %u m',zs));
    
    if k == 3
        xlabel('range [km]');
    end
    
    hold on
    
    % add eigenrays
    num_eigentable = numel(eigentable);
    for ne = 1:num_eigentable
        
        if strcmp(eigentable{ne}.env,ssp(k).filestr)
            tx_z = double(eigentable{ne}.tx_z);
            
            if tx_z == zs
                
                if ~strcmp(eigentable{ne}.ray,'None')
                    
                    plot(eigentable{ne}.ray.r./1000,eigentable{ne}.ray.z,...
                        'color',[markerModemMap(eigentable{ne}.rx_node) 0.5],'linewidth',2,'handlevisibility','off')
                end
            end
        end
    end
    
    % add source
    scatter(0,zs,markerSize,'k','s','linewidth',2);
    
    % add modem shapes
    for node = A.unique_rx
        node = node{1}; % change from cell to char
        
        for imd = modem_rx_depth
            index = find(strcmp(A.tag_rx,node) & A.rx_z == imd & A.tx_z == zs);
            
            if ~isempty(index)
                scatter(A.data_range(index)./1000,A.rx_z(index),...
                    markerSize-25,markerModemMap(node),markerShape(imd),'filled');
                
                tx_nodes = A.tag_tx(index);
                unq_tx_nodes = unique(tx_nodes);
                
                % report amount at each rx modem node
                for utn = unq_tx_nodes
                    subindex = find(strcmp(A.tag_tx,utn{1}));
                    subindex = intersect(index,subindex);
                    
                    text(mean(A.data_range(subindex))./1000,imd+14,num2str(numel(subindex)),...
                        'HorizontalAlignment','center','VerticalAlignment','top','fontsize',9,'color',markerModemMap(node));
                end
            end
        end
    end
    

    hold off
end

h_printThesisPNG(sprintf('raytrace-3env-zs-%u',zs));


