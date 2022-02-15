%% prep workspace
clear; clc; close all;

%% load data
A = load('../../data/tobytest-recap-clean.mat'); % loads "event"
A = h_unpack_experiment(A.event);
A = h_clean_simgvel(A);

load p_sspColorDetails
%% figure 1 -- all events in 3x2 grid

figure('name','rangeanomaly-by-owtt','renderer','painters','position',[108 108 1100 900]);
t = tiledlayout(3,2,'TileSpacing','none','Padding','compact');

index3 = ~isnan(A.sim_gvel);
count = 0;
for zs = [20 30 90]
    index1 = A.tx_z == zs;
    
    for zr = [30 90]
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
            title(sprintf('source depth = %u m',zs),'fontsize',14,'fontweight','bold');
            text(2.2,25,sprintf('rx depth = %u m',zr),'HorizontalAlignment','right','VerticalAlignment','bottom','fontsize',11);
            
            if sum(index)~=1
                text(2.2,25-3.*eof_status,sprintf('%s = %u events',eof_str,sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
            else
                text(2.2,25,sprintf('%s = %u event',eof_str,sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
            end
            grid on
            
            xlim([0.9 2.26])
            ylim([-16 26]);
            
            if mod(count,2)~=1
                yticklabels([])
            else
                ylabel('range error [m]');
            end
            
            if count >=5
                xlabel('one way travel time [s]');
            else
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
legend(l2,'Baseline','Chosen Weights','location','northwest');

% title
sgtitle('In situ range error by source (20,30,90 m) and receiver (30,90 m) depths','fontsize',17,'fontweight','bold')
% h_printThesisPNG('range-error-owtt-data-v2');

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
    
    
    
    