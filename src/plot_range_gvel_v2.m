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

%% plot

figure('name','gvel-by-range','renderer','painters','position',[108 108 1300 800]);
t = tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

%% gvel vs range for naive
nexttile;

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
                    200,'filled','MarkerFaceColor',colorDepth(zs),'MarkerEdgeColor',colorDepth(zr),...
                   'LineWidth',3,'handlevisibility','off');
            end
            hold off
        end
    end
end

title('Naive calculation of group velocity');
h_common_plot();

%% gvel vs range for in situ
nexttile;
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
                    200,'filled','MarkerFaceColor',colorDepth(zs),'MarkerEdgeColor',colorDepth(zr),...
                    'LineWidth',3,'handlevisibility','off');
            end
            hold off
        end
    end
end

title('In situ prediction of group velocity');
h_common_plot();
xlabel('range [m]');

h_printThesisPNG('gvel-by-range');

%% helper function
function [] = h_common_plot()
grid on
xlim([1400 2200]);
%xlim([1 1.5]);
ylim([1420 1450]);

set(gca,'fontsize',13);
ylabel('group velocity [m/s]');
end

