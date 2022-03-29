%% prep workspace
clear; clc; close all;
addpath('../../src');

%% load data
A = load('../../data/tobytest-recap-clean.mat'); % loads "event"
A = h_unpack_experiment(A.event);
A = h_clean_simgvel(A);

load p_sspColorDetails
%% figure 1 -- all events in 3x2 grid
figure('name','rangeanomaly-by-owtt','renderer','painters','position',[108 108 1300 800]);
t = tiledlayout(2,3,'TileSpacing','none','Padding','compact');

index3 = ~isnan(A.sim_gvel);
count = 0;
for zr = [30 90]
    
    for zs = [20 30 90]
        
        index1 = A.tx_z == zs;
        index2 = A.rx_z == zr;
        
        count = count + 1;
        nexttile;
        
        for eof_status = [0 1]
            index4 = A.eof_bool == eof_status;
            
            if eof_status == 1
                eof_str = 'weighted';
            else
                eof_str = 'baseline';
            end
            
            index = logical(index1.*index2.*index3.*index4);
            
            if sum(index)>=1
                % plot
                hold on
                plot([0 4],[0 0],'--','linewidth',3,'color',[0 0 0 0.6],'handlevisibility','off');
                
                xval = A.data_owtt(index);
                yval = A.sim_gvel(index) .* A.data_owtt(index) - A.data_range(index);
                
                % remove nans
                xval = xval(~isnan(yval)).';
                yval = yval(~isnan(yval)).';
                
                % sort
                [xval,shuffle] = sort(xval);
                yval = yval(shuffle);
                
                % make boundary
                b = boundary(xval,yval);
                p = patch(xval(b),yval(b),'k');
                p.FaceAlpha = 0;
                p.EdgeColor = colorSet{eof_status+1};
                p.LineWidth = 3;
                p.EdgeAlpha = 0.7;
                
                plotIndex = find(index == 1);
                for k = plotIndex
                    rxNode = A.tag_rx(k);
                    rxNode = rxNode{1};
                    scatter(A.data_owtt(k),A.sim_gvel(k) .* A.data_owtt(k) - A.data_range(k),...
                        75,colorSet{eof_status+1},...
                        'filled','MarkerFaceAlpha',0.4,'handlevisibility','off');
                end
                hold off
            end
            set(gca,'fontsize',13)
            
            % for all grids
            %title(sprintf('source depth = %u m',zs),'fontsize',14,'fontweight','bold');
            title('  ','fontsize',8);
            text(2.25,23,sprintf('source depth = %u m',zs),'HorizontalAlignment','right','VerticalAlignment','bottom','fontsize',11,'fontweight','bold');
            text(2.25,23,sprintf('receiver depth = %u m',zr),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11,'fontweight','bold');
            
            if eof_status==0
                text(2.25,18,sprintf('%s = %u events',eof_str,sum(index)),'HorizontalAlignment','right','VerticalAlignment','bottom','fontsize',11);
            else
                text(2.25,18,sprintf('%s = %u events',eof_str,sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
            end
            grid on
            
            xlim([0.9 2.29])
            xticks(1:0.2:2.2);

            ylim([-16 27]);
            yticks(-15:5:25);
            
            if count == 4
                xlabel('one way travel time [s]');
                ylabel('pseudorange error [m]');
            else
                yticklabels([]);
                xticklabels([]);
            end
        end
    end
end
% legend
nexttile(1);
hold on
for k = 1:2
    l2(k) = plot([NaN NaN],[NaN NaN],'color',colorSet{k});
end
hold off
legend(l2,'Baseline','Chosen Weights','location','southeast');

% title
sgtitle('Real-time pseudorange error by source and receiver depths','fontsize',17,'fontweight','bold')
h_printThesisPNG('range-error-insitu');

%% find mean, median, etc for baseval vs eof

A.rangeAnomaly = abs(A.sim_gvel.*A.data_owtt - A.data_range);
count = 0;
for eof_status = [0 1]
    indexStat = A.eof_bool == eof_status & ~isnan(A.sim_gvel);
    
    count = count + 1;
    bStat(count).num = sum(indexStat);
    bStat(count).mean = mean(A.rangeAnomaly(indexStat));
    bStat(count).med = median(A.rangeAnomaly(indexStat));
    bStat(count).std = std(A.rangeAnomaly(indexStat));
    bStat(count).max = max(A.rangeAnomaly(indexStat));
end



