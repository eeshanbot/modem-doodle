%% main_plot_bellhop_gvel

%% prep workspace
clear; clc; close all;

% load data
A = readtable('./bellhop-gvel-gridded/gveltable.csv');
% only simGvel
A.gvel = A.recRange ./ A.owtt;

% remove crazy 11 second event
indBad = find(A.owtt > 4);
load outlierIndex.mat

indBad = [indBad; outlier];
A.gvel(indBad) = NaN;

% load simulation
listing = dir('./bellhop-gvel-gridded/csv_arr/*gridded.csv');

for k = 1:numel(listing)
    T0 = readtable([listing(k).folder '/' listing(k).name]);
    T0.index = T0.index + 1;
    b = split(listing(k).name,'.');
    tName{k} = b{1};
    
    % assign gvel for each index by closest time comparison
    for j = 1:numel(T0.index)
        delay = A.owtt(j);
        tableDelay = table2array(T0(j,2:6));
        [~,here] = min(abs(tableDelay - delay));
        T0.gvel(j) = A.recRange(j)./tableDelay(here);
        T0.owtt(j) = tableDelay(here);
        if sum(j == indBad) == 1
            T0.gvel(j) = NaN;
        end
    end
    T{k} = T0;
end

% 1 = artifact-baseval
% 2 = artifact-eeof
% 3 = fixed-baseval
% 4 = fixed-eeof
% 5 = hycom

% load modem marker information
load p_modemMarkerDetails

%% plot all data group velocity

figure('name','gvel-by-owtt','renderer','painters','position',[108 108 1200 1000]);
t = tiledlayout(3,2,'TileSpacing','none','Padding','compact');

colorSet = {[0 0 0],[0 0 0],[232, 153, 35]./256,[0 85 135]./256,[152 134 117]./256};

count = 0;
for zs = [20 30 90]
    index1 = A.sourceDepth == zs;
    
    for zr = [30 90]
        index2 = A.recDepth == zr;
        
        count = count + 1;
        nexttile;
        
        index = boolean(index1.*index2);
        
        if sum(index)>=1
            % plot
            hold on
            for s = [3 4 5]
                xval = A.owtt(index);
                yval = T{s}.gvel(index);
                
                % remove nans
                xval = xval(~isnan(yval));
                yval = yval(~isnan(yval));
                
                [xval,shuffle] = sort(xval);
                plot(xval,yval(shuffle),'-o','color',[colorSet{s} 0.8],'linewidth',3);
            end
            hold off
        end
        set(gca,'fontsize',13)
        
        % for all grids
        title(sprintf('source depth = %u m',zs),'fontsize',14,'fontweight','normal');
        text(0.95,1445,sprintf('rx depth = %u m',zr),'HorizontalAlignment','left','VerticalAlignment','top','fontsize',12);
        
        if sum(index)>1
            text(0.95,1445,sprintf('n = %u events',sum(index)),'HorizontalAlignment','left','VerticalAlignment','bottom','fontsize',12);
        else
            text(0.95,1445,sprintf('n = %u event',sum(index)),'HorizontalAlignment','left','VerticalAlignment','bottom','fontsize',12);
        end
        grid on
        
        xlim([0.9 2.26])
        ylim([1425 1446])
        
        yticks([1425:5:1445]);
        if mod(count,2)~=1
            yticklabels([])
        else
            ylabel('group velocity [m/s]');
        end
        
        if count >=5
            xlabel('one way travel time [s]');
        else
            xticklabels([]);
        end
    end
end

% add legend
nexttile(1);
hold on
for s = [3 4 5]
    plot(NaN,NaN,'-','color',colorSet{s});
end
lg = legend('Mean','Chosen Weights','HYCOM','location','southeast');
title(lg,'Sound Speed Inputs');

% title
sgtitle('Group velocity estimates by source (20,30,90 m) and receiver (30,90 m) depths','fontsize',17,'fontweight','bold')

% save plot
% h_printThesisPNG('gvel-owtt-newalgorithm.png');

%% plot all data RANGE ANOMALY

figure('name','rangeanomaly-by-owtt','renderer','painters','position',[108 108 1200 1000]);
t = tiledlayout(3,2,'TileSpacing','none','Padding','compact');

colorSet = {[0 0 0],[0 0 0],[232, 153, 35]./256,[0 85 135]./256,[152 134 117]./256};

count = 0;
for zs = [20 30 90]
    index1 = A.sourceDepth == zs;
    
    for zr = [30 90]
        index2 = A.recDepth == zr;
        
        count = count + 1;
        nexttile;
        
        index = boolean(index1.*index2);
        
        if sum(index)>=1
            % plot
            hold on
            plot([0 4],[0 0],'--','linewidth',3,'color',[0 0 0 0.6],'handlevisibility','off');

            for s = [5 3 4]
                xval = A.owtt(index);
                yval = T{s}.gvel(index) .* A.owtt(index) - A.recRange(index);
                                
                % remove nans
                xval = xval(~isnan(yval));
                yval = yval(~isnan(yval));
                
                % sort
                [xval,shuffle] = sort(xval);
                yval = yval(shuffle);
                
                % make boundary
                b = boundary(xval,yval);
                p = patch(xval(b),yval(b),colorSet{s});
                p.FaceAlpha = .5;
                p.EdgeColor = colorSet{s};
                p.LineWidth = 3;
               
                %plot(xval,yval(shuffle),'o','color',[colorSet{s} 0.8],'linewidth',3);
                %scatter(xval,yval(shuffle),'filled','MarkerFaceColor',colorSet{s},'MarkerFaceAlpha',0.4);
                
            end
            hold off
        end
        set(gca,'fontsize',13)
        
        % for all grids
        title(sprintf('source depth = %u m',zs),'fontsize',14,'fontweight','normal');
        text(2.2,20,sprintf('rx depth = %u m',zr),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
        
        if sum(index)>1
            text(2.2,20,sprintf('n = %u events',sum(index)),'HorizontalAlignment','right','VerticalAlignment','bottom','fontsize',11);
        else
            text(2.2,20,sprintf('n = %u event',sum(index)),'HorizontalAlignment','right','VerticalAlignment','bottom','fontsize',11);
        end
        grid on
        
        xlim([0.9 2.26])
        ylim([-11 21]);
      
        if mod(count,2)~=1
            yticklabels([])
        else
            ylabel('range anomaly [m]');
        end
        
        if count >=5
            xlabel('one way travel time [s]');
        else
            xticklabels([]);
        end
    end
end

% add legend
nexttile(1);
hold on
for s = [3 4 5]
    plot(NaN,NaN,'-','color',colorSet{s});
end
lg = legend('HYCOM','Mean of EOF set','Chosen Weights','location','southeast');
title(lg,'Sound Speed Inputs');

% title
sgtitle('Range anomaly by source (20,30,90 m) and receiver (30,90 m) depths','fontsize',17,'fontweight','bold')
h_printThesisPNG('range-anomaly-owtt-newalgorithm.png')
