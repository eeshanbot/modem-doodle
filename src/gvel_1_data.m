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

plotbool = [1 1 1 1 1 1];

%% figure --- owtt vs range
if plotbool(1) == 1
    
    figure('name','owtt-range','renderer','painters','position',[108 108 1400 600]);
    
    % all events
    subplot(2,1,1);
    hold on
    for k = 1:numel(A.simGvel)
        
        % plot
        yval = A.owtt(k);
        xval = A.recRange(k);
        scatter(xval,yval,...
            150,markerModemMap(A.rxNode{k}),markerShape(A.recDepth(k)),...
            'filled','MarkerFaceAlpha',0.2,'handlevisibility','off');
    end
    hold off
    grid on
    xlabel('range [m]');
    ylabel('travel time [s]');
    title(sprintf('All valid events, n=%u',numel(A.simGvel)));
    
    
    % only simGvel
    indValid = ~isnan(A.simGvel);
    subplot(2,1,2);
    hold on
    for k = 1:numel(indValid)
        
        % plot if simulation captured gvel information
        if indValid(k)==1
            yval = A.owtt(k);
            xval = A.recRange(k);
            scatter(xval,yval,...
                150,markerModemMap(A.rxNode{k}),markerShape(A.recDepth(k)),...
                'filled','MarkerFaceAlpha',0.2,'handlevisibility','off');
        end
    end
    hold off
    grid on
    xlabel('range [m]');
    ylabel('travel time [s]');
    title(sprintf('Events with in situ group velocity estimate, n=%u',sum(indValid)));
    
end


%% figure --- gvel compared to owtt & range

if plotbool(2) == 1
    figure('name','gvel-data','renderer','painters','position',[108 108 1250 550]);
    
    % get index for gvel data
    indValid = ~isnan(A.simGvel);
    
    hold on
    for k = 1:numel(indValid)
        
        % plot gvel
        if indValid(k)==1
            
            subplot(1,2,1);
            hold on
            xval = A.owtt(k);
            yval = A.simGvel(k);
            scatter(xval,yval,...
                150,markerModemMap(A.rxNode{k}),markerShape(A.recDepth(k)),...
                'filled','MarkerFaceAlpha',0.4,'handlevisibility','off');
            hold off
            
            subplot(1,2,2);
            hold on
            xval = A.recRange(k);
            yval = A.simGvel(k);
            scatter(xval,yval,...
                150,markerModemMap(A.rxNode{k}),markerShape(A.recDepth(k)),...
                'filled','MarkerFaceAlpha',0.4,'handlevisibility','off');
            hold off
        end
    end
    hold off
    
    % beautify plots
    subplot(1,2,1);
    grid on
    xlabel('one way travel time [s]');
    ylabel('group velocity [m/s]');
    sgtitle('Realtime stochastic group velocity estimates from modem experiment','fontsize',18,'fontweight','bold');
    
    subplot(1,2,2);
    grid on
    xlabel('range [m]');
    yticklabels([]);
end

%% gvel (data) compared to gvel (sim)

if plotbool(3) == 1
    figure('name','data-sim-compare','renderer','painters','position',[108 108 900 800]);
    
    % get index for gvel data
    indValid = ~isnan(A.simGvel);
    
    hold on
    for k = 1:numel(indValid)
        
        % plot gvel
        if indValid(k)==1
            
            xval = A.recRange(k) ./ A.owtt(k);
            yval = A.simGvel(k);
            scatter(xval,yval,...
                150,markerModemMap(A.rxNode{k}),markerShape(A.recDepth(k)),...
                'filled','MarkerFaceAlpha',0.4,'handlevisibility','off');
        end
    end
    hold off
    
    % beautify plots
    grid on
    xlabel('simulated group velocity [m/s]');
    xlim([1420 1452]);
    ylim([1420 1452]);
    xlabel('simulated group velocity [s]');
    ylabel('naive group velocity [m/s]');
    title('Naive vs simulated group velocity estimate');
end

h_printThesisPNG('gvel-sim-naive-compare.png');


%% range anomaly vs owtt (all depths?)

if plotbool(4) == 1
    figure('name','gvel-range-anomaly','renderer','painters','position',[108 108 1250 1000]);
    
    % get index for gvel data
    indValid = ~isnan(A.simGvel);
    
    hold on
    for k = 1:numel(indValid)
        
        % plot gvel
        if indValid(k)==1
            
            subplot(1,2,1);
            hold on
            xval = A.owtt(k);
            yval = A.simGvel(k) * A.owtt(k) - A.recRange(k);
            scatter(xval,yval,...
                150,markerModemMap(A.rxNode{k}),markerShape(A.recDepth(k)),...
                'filled','MarkerFaceAlpha',0.4,'handlevisibility','off');
            hold off
            
            subplot(1,2,2);
            hold on
            scatter(xval,yval,...
                150,markerModemMap(A.rxNode{k}),markerShape(A.recDepth(k)),...
                'filled','MarkerFaceAlpha',0.4,'handlevisibility','off');
            hold off
        end
    end
    hold off
    
    % beautify plots
    subplot(1,2,1);
    grid on
    xlabel('one way travel time [s]');
    ylabel('range anomaly [m]');
    sgtitle('Range anomaly for all events with a valid in situ group velocity','fontsize',18,'fontweight','bold');
    
    subplot(1,2,2);
    grid on
    xlabel('one way travel time [s]');
    ylabel('range anomaly [m]');
    xlim([0.8 2.3]);
end

%% range anomaly figure for valid in situ estimates

figure('name','rangeanomaly-by-owtt','renderer','painters','position',[108 108 1200 1000]);
t = tiledlayout(3,2,'TileSpacing','none','Padding','compact');

index3 = ~isnan(A.simGvel);
count = 0;
for zs = [20 30 90]
    index1 = A.sourceDepth == zs;
    
    for zr = [30 90]
        index2 = A.recDepth == zr;
        
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
                        'filled','MarkerFaceAlpha',0.1,'handlevisibility','off');
            end
            
            
            hold off
        end
        set(gca,'fontsize',13)
        
        % for all grids
        title(sprintf('source depth = %u m',zs),'fontsize',14,'fontweight','normal');
        text(2.2,25,sprintf('rx depth = %u m',zr),'HorizontalAlignment','right','VerticalAlignment','bottom','fontsize',11);
        
        if sum(index)>1
            text(2.2,25,sprintf('n = %u events',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
        else
            text(2.2,25,sprintf('n = %u event',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
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

% title
sgtitle('Range error by source (20,30,90 m) and receiver (30,90 m) depths','fontsize',17,'fontweight','bold')
h_printThesisPNG('range-error-owtt-data')
