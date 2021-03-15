%% gvel_1_data
% makes plots to explore *data* from ICEX20

%% prep workspace
clear; clc; close all;

% load data
A = readtable('./bellhop-gvel-gridded/gveltable.csv');

% load modem marker information
load p_modemMarkerDetails

plotbool = [0 0 0 0 1];

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
    figure('name','data-sim-compare','renderer','painters','position',[108 108 1250 550]);
    
    % get index for gvel data
    indValid = ~isnan(A.simGvel);
    
    hold on
    for k = 1:numel(indValid)
        
        % plot gvel
        if indValid(k)==1
            
            subplot(1,2,1);
            hold on
            xval = A.recRange(k) ./ A.owtt(k);
            yval = A.simGvel(k);
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
    xlabel('simulated group velocity [s]');
    ylabel('naive group velocity [m/s]');
    sgtitle('Comparing simulated group velocity with naive group velocity calculations','fontsize',18,'fontweight','bold');
    
    subplot(1,2,2);
    grid on
    xlabel('simulated group velocity [m/s]');
    xlim([1420 1452]);
    ylim([1420 1452]);
    xlabel('simulated group velocity [s]');
    ylabel('naive group velocity [m/s]');
end


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

%% gvel anomaly vs owtt, separate by source depths
% 
% if plotbool(5) == 1
%     figure('name','gvel-by-zs','renderer','painters','position',[108 108 1250 1000]);
%     
%     nodes = unique([A.txNode]);
%     
%     % get index for gvel data
%     indValid = ~isnan(A.simGvel);
%     
%     for zs = [20 30 90]
%         indSrcDepth = A.sourceDepth == zs;
%         
%         for zr = [20 30 90]
%             indRecDepth = A.recDepth == zs;
%             
%             for n = nodes
%                 indNode = A.rxNode == n{1};
%             
%                 indPlot = boolean(indValid .* indSrcDepth .* indRecDepth .* indNode);
%                 
%                 xval = A.owtt(indPlot);
%                 yval = A.owtt(indPlot);
%                 scatter(xval,yval,...
%                 150,markerModemMap(A.rxNode{k}),markerShape(A.recDepth(k)),...
%                 'filled','MarkerFaceAlpha',0.4,'handlevisibility','off');
%                 
%                 
%             end
%         end
%     end
% end
