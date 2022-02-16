%% prep workspace
clear; clc; close all;

% load modem marker information
load p_modemMarkerDetails

%% load data

[DATA,INDEX] = h_unpack_bellhop('../bellhop-gvel-gridded/gveltable.csv');

%% load simulation
listing = dir('../bellhop-gvel-gridded/csv_arr/*gridded.csv');
[T,colorSet] = h_get_nbc(listing,DATA,INDEX);

%% plot all data group velocity

figure('name','gvel-by-owtt','renderer','painters','position',[108 108 1100 900]);
tiledlayout(3,2,'TileSpacing','none','Padding','compact');

shapeBounce = {'o','x','s','^','d'};

count = 0;
for zs = [20 30 90]
    index1 = DATA.sourceDepth == zs;
    
    for zr = [30 90]
        index2 = DATA.recDepth == zr;
        
        count = count + 1;
        nexttile;
        
        index = logical(index1.*index2.*INDEX.valid);
        
        if sum(index)>=1
            % plot
            hold on
            for s = [5 3 4]
                xval = DATA.owtt(index);
                yval = T{s}.gvel(index);
                
                numBounces = T{s}.numBounces(index);
                
                % remove nans
                numBounces = numBounces(~isnan(yval));
                xval = xval(~isnan(yval));
                yval = yval(~isnan(yval));
                
                for nb = 0:4
                    indBounce = find(numBounces == nb);
                    scatter(xval(indBounce),yval(indBounce),150,shapeBounce{nb+1},'MarkerEdgeColor',[colorSet{s}],'linewidth',2,'handlevisibility','off');
                end
                
            end
            hold off
        end
        set(gca,'fontsize',13)
        
        % for all grids
        title(sprintf('source depth = %u m',zs),'fontsize',14,'fontweight','bold');
        text(0.95,1445,sprintf('rx depth = %u m',zr),'HorizontalAlignment','left','VerticalAlignment','bottom','fontsize',12);
        
        if sum(index)>1
            text(0.95,1445,sprintf('n = %u events',sum(index)),'HorizontalAlignment','left','VerticalAlignment','top','fontsize',12);
        else
            text(0.95,1445,sprintf('n = %u event',sum(index)),'HorizontalAlignment','left','VerticalAlignment','top','fontsize',12);
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

% add legend 1 -- color
hold on
for s = [5 3 4]
    plot(NaN,NaN,'color',colorSet{s},'linewidth',5);
end
plot(NaN,NaN,'w');
plot(NaN,NaN,'w');

% add legend 2 -- shape
for nb = 0:4
    scatter(NaN,NaN,shapeBounce{nb+1},'MarkerEdgeColor','k');
end

lgdstr = {'HYCOM','Baseline','Chosen Weights','','','direct path','1 bounce','2 bounces','3 bounces','4 bounces'};
lgd = legend(lgdstr,'numcolumns',2,'fontsize',11,'location','SouthEast');
title(lgd,'SSP Source & Multipath Structure');
hold off

% title
sgtitle('Post-processed group velocity estimates by source and receiver depths','fontsize',17,'fontweight','bold')

%% save plot
% h_printThesisPNG('gvel-owtt-newalgorithm');