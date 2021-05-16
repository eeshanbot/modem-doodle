%% plot_range_gvel_v2.m

clear; clc; close all;

%% load data
A = load('./data-prep/tobytest-recap-full.mat'); % loads "event"
A = h_unpack_experiment(A.event);

% remove crazy 11 second event, event that is nominally 1.58* seconds
indBad1 = A.data_owtt > 3;
indBad2 = strcmp(A.tag_rx,'East') & A.data_owtt > 1.55;
indBad = indBad1 | indBad2;

% 1.587 events, had clock errors + Bellhop can't resolve these
A.sim_gvel(indBad) = NaN;

colorDepth = containers.Map([20 30 90],{[70 240 240]./256,[0 130 200]./256,[0 0 128]./256});
sourceDepth = containers.Map([30 90],{'^','v'});
alphaDepth = containers.Map([20 30 90],[.3 .2 .1]);

%% plot

figure('name','gvel-by-range','renderer','painters','position',[108 108 1100 800]);
t = tiledlayout(2,6,'TileSpacing','compact','Padding','default');

%% gvel vs range for naive
nexttile([1 4]);

for zs = [20 30 90]
    index1 = A.tx_z == zs;
    
    for zr = [30 90]
        index2 = A.rx_z == zr;
        
        % in situ values
        index3 = ~isnan(A.sim_gvel);
        index = boolean(index1.*index2.*index3);
        
        if sum(index)>=1
            % plot
            hold on
            
            plotIndex = find(index == 1);
            for k = plotIndex
                txNode = A.tag_tx(k);
                txNode = txNode{1};
                scatter(A.data_range(k),A.data_range(k)./A.data_owtt(k),...
                    200,'filled',sourceDepth(zr),'MarkerFaceColor',colorDepth(zs),...
                    'handlevisibility','off','MarkerFaceAlpha',alphaDepth(zs));
            end
            hold off
        end
    end
end

title('Naive calculation of group velocity');
h_common_plot();

%% inset
nexttile([1 2]);

for zs = [20 30 90]
    index1 = A.tx_z == zs;
    
    for zr = [30 90]
        index2 = A.rx_z == zr;
        
        % in situ values
        index3 = ~isnan(A.sim_gvel);
        index = boolean(index1.*index2.*index3);
        
        if sum(index)>=1
            % plot
            hold on
            
            plotIndex = find(index == 1);
            for k = plotIndex
                txNode = A.tag_tx(k);
                txNode = txNode{1};
                scatter(A.data_range(k),A.data_range(k)./A.data_owtt(k),...
                    200,'filled',sourceDepth(zr),'MarkerFaceColor',colorDepth(zs),...
                    'handlevisibility','off','MarkerFaceAlpha',alphaDepth(zs));
            end
            hold off
        end
    end
end

grid on
xlim([2147 2151]);
ylim([1420 1450]);
yticklabels([]);
set(gca,'fontsize',10);

title('Zoomed in on furthest range');


%% gvel vs range for in situ
nexttile([1 4]);
for zs = [20 30 90]
    index1 = A.tx_z == zs;
    
    for zr = [30 90]
        index2 = A.rx_z == zr;
        
        % in situ values
        index3 = ~isnan(A.sim_gvel);
        index = boolean(index1.*index2.*index3);
        
        if sum(index)>=1
            % plot
            hold on
            
            plotIndex = find(index == 1);
            for k = plotIndex
                txNode = A.tag_tx(k);
                txNode = txNode{1};
                scatter(A.data_range(k),A.sim_gvel(k),...
                    200,'filled',sourceDepth(zr),'MarkerFaceColor',colorDepth(zs),...
                    'handlevisibility','off','MarkerFaceAlpha',alphaDepth(zs));
            end
            hold off
        end
    end
end

title('In situ prediction of group velocity');
h_common_plot();
xlabel('range [m]');

% legend
% add legend
hold on
for s = [20 30 90]
    plot(NaN,NaN,'color',colorDepth(s),'linewidth',6);
end

plot(NaN,NaN,'w');

for r = [30 90]
    plot(NaN,NaN,sourceDepth(r),'color','k')
end
hold off
lgdstr = {' 20 m',' 30 m',' 90 m','',' 30 m',' 90 m'};

lg1 = legend(lgdstr,'location','south','NumColumns',2,'fontsize',11);
title(lg1,'   source depth & receiver depth');

%% inset
nexttile([1 2]);

for zs = [20 30 90]
    index1 = A.tx_z == zs;
    
    for zr = [30 90]
        index2 = A.rx_z == zr;
        
        % in situ values
        index3 = ~isnan(A.sim_gvel);
        index = boolean(index1.*index2.*index3);
        
        if sum(index)>=1
            % plot
            hold on
            
            plotIndex = find(index == 1);
            for k = plotIndex
                txNode = A.tag_tx(k);
                txNode = txNode{1};
                scatter(A.data_range(k),A.sim_gvel(k),...
                    200,'filled',sourceDepth(zr),'MarkerFaceColor',colorDepth(zs),...
                    'handlevisibility','off','MarkerFaceAlpha',alphaDepth(zs));
            end
            hold off
        end
    end
end

grid on
xlim([2147 2151]);
ylim([1420 1450]);
yticklabels([]);
set(gca,'fontsize',10);
xlabel('range [m]');
title('Zoomed in on furthest range');

%% export

h_printThesisPNG('gvel-by-range');

%% helper function
function [] = h_common_plot()
grid on
xlim([1400 2200]);
ylim([1420 1450]);

set(gca,'fontsize',13);
ylabel('group velocity [m/s]');
end

