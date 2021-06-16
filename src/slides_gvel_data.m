%% gvel_1_data
% makes plots to explore *data* from ICEX20

%% prep workspace
clear; clc; close all;

% load data
A = readtable('./bellhop-gvel-gridded/gveltable.csv');

% remove crazy 11 second event, event that is nominally 1.58* seconds
indBad1 = find(A.owtt > 4);
indBad2 = find(strcmp(A.rxNode,'East') & A.owtt > 1.55);
indBad = union(indBad1,indBad2);

% 1.587 events, had clock errors + Bellhop can't resolve these
A.simGvel(indBad) = NaN;

% load modem marker information
load p_modemMarkerDetails

%% range anomaly figure for valid in situ estimates

figure('name','rangeanomaly-by-owtt','renderer','painters','position',[108 108 1300 800]);
t = tiledlayout(2,3,'TileSpacing','none','Padding','compact');

index3 = ~isnan(A.simGvel);
count = 0;
for zr = [30 90]
    index2 = A.recDepth == zr;
    
    for zs = [20 30 90]
        index1 = A.sourceDepth == zs;
        
        count = count + 1;
        nexttile;
        
        index = boolean(index1.*index2.*index3);
        
        if sum(index)>=1
            % plot
            hold on
            plot([0 4],[0 0],'--','linewidth',3,'color',[0 0 0 0.6],'handlevisibility','off');
            
            xval = A.owtt(index);
            yval = A.simGvel(index) .* A.owtt(index) - A.recRange(index);
            
            % remove nans
            xval = xval(~isnan(yval));
            yval = yval(~isnan(yval));
            
            % sort
            [xval,shuffle] = sort(xval);
            yval = yval(shuffle);
            
            % make boundary
            b = boundary(xval,yval);
            p = patch(xval(b),yval(b),'k');
            p.FaceAlpha = .1;
            p.EdgeColor = 'w';
            p.LineWidth = 2;
            
            plotIndex = find(index == 1);
            for k = plotIndex.'
                scatter(A.owtt(k),A.simGvel(k) .* A.owtt(k) - A.recRange(k),...
                    150,markerModemMap(A.rxNode{k}),markerShape(A.recDepth(k)),...
                    'filled','MarkerFaceAlpha',0.4,'handlevisibility','off');
            end
            
            
            hold off
        end
        set(gca,'fontsize',13)
        
        % for all grids
        if count<=3
            title(sprintf('source depth = %u m',zs),'fontsize',14,'fontweight','normal');
        end
        text(2.2,22.8,sprintf('rx depth = %u m',zr),'HorizontalAlignment','right','VerticalAlignment','bottom','fontsize',12,'fontweight','bold');
        
        if sum(index)>1
            text(2.2,22.8,sprintf('n = %u events',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
        else
            text(2.2,22.8,sprintf('n = %u event',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
        end
        grid on
        
        xlim([0.9 2.26])
        ylim([-16 26]);
        yticks(-20:5:25);
        xticks(1:0.2:2.2);
        
        if mod(count,3)~=1
            yticklabels([])
        else
            ylabel('range error [m]');
        end
        
        if count >=4
            xlabel('one way travel time [s]');
        else
            xticklabels([]);
        end
    end
end

% title
sgtitle('Range error by source (20,30,90 m) and receiver (30,90 m) depths','fontsize',17,'fontweight','bold')
h_printThesisPNG('SLIDES-range-error-owtt-data')

