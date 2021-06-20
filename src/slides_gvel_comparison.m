%% slides_gvel_comparison
% show visual comparison, for a source depth of 30 m, for v1 & v2 gvel
% predictions

%% prep workspace
clear; clc; close all;

% load data
DATA = readtable('./bellhop-gvel-gridded/gveltable.csv');
% only simGvel
DATA.gvel = DATA.recRange ./ DATA.owtt;

DATA.simGvel(isnan(DATA.simGvel)) = 0;

% remove crazy 11 second event, event that is nominally 1.58* seconds
indBad1 = find(DATA.owtt > 4);
indBad2 = find(strcmp(DATA.rxNode,'East') & DATA.owtt > 1.55);
indBad3 = find(strcmp(DATA.rxNode,'Camp'));
indBad = union(indBad1,indBad2);
indBad = union(indBad,indBad3);

% 1.587 events, had clock errors + Bellhop can't resolve these
DATA.simGvel(indBad) = NaN;
% only simGvel

indValid = ~isnan(DATA.simGvel);

% calculate RangeAnomaly
DATA.rangeAnomaly = DATA.owtt .* DATA.simGvel - DATA.recRange;

%% load post-processing sim for v2
listing = dir('./bellhop-gvel-gridded/csv_arr/*gridded.csv');

for k = 1:numel(listing)
    T0 = readtable([listing(k).folder '/' listing(k).name]);
    T0.index = T0.index + 1;
    b = split(listing(k).name,'.');
    tName{k} = b{1};
    
    % assign gvel for each index by closest time comparison
    for j = 1:numel(T0.index)
        delay = DATA.owtt(j);
        tableDelay = table2array(T0(j,2:6));
        [~,here] = min(abs(tableDelay - delay));
        T0.gvel(j) = DATA.recRange(j)./tableDelay(here);
        T0.owtt(j) = tableDelay(here);
        T0.numBounces(j) = here-1;
        if sum(j == indBad) == 1
            T0.gvel(j) = NaN;
        end
    end
    T2{k} = T0;
end

%% load post-processing sim, v1
listing = dir('./bellhop-gvel-gridded/csv_arr/*old.csv');

for f = 1:numel(listing)
    T0 = readtable([listing(f).folder '/' listing(f).name]);
    T0.index = T0.index + 1;
    b = split(listing(f).name,'.');
    tName{f} = b{1};
    
    % assign gvel by minimum bounce
    for k = 1:numel(T0.index)
        T0.gvel(k) = DATA.recRange(k)./T0.owtt(k);
    end
    
    T0.rangeAnomaly = DATA.owtt .* T0.gvel - DATA.recRange;
    T1{f} = T0;
end

%% set up

% 1 = artifact-baseval
% 2 = artifact-eeof
% 3 = fixed-baseval
% 4 = fixed-eeof
% 5 = hycom

colorSet = {[0 0 0],[0 0 0],[232, 153, 35]./256,[0 85 135]./256,[152 134 117]./256};

%% plot all data group velocity

figure('name','gvel-by-owtt','renderer','painters','position',[108 108 1300 650]);
tiledlayout(1,2,'TileSpacing','none','Padding','compact');

shapeBounce = {'o','x','s','^','d'};

count = 0;
for zs = [30]
    index1 = DATA.sourceDepth == zs;
    
    for zr = [30 90]
        index2 = DATA.recDepth == zr;
        
        count = count + 1;
        nexttile;
        
        index = boolean(index1.*index2.*indValid);
        
        if sum(index)>=1
            % plot
            hold on
            for s = [5 3 4]
                xval = DATA.owtt(index);
                yval2 = T2{s}.gvel(index);
                
                numBounces = T2{s}.numBounces(index);
                
                % remove nans
                numBounces = numBounces(~isnan(yval2));
                xval = xval(~isnan(yval2));
                yval2 = yval2(~isnan(yval2));
                
                for nb = 0:4
                    indBounce = find(numBounces == nb);
                    scatter(xval(indBounce),yval2(indBounce),150,shapeBounce{nb+1},'MarkerEdgeColor',[colorSet{s}],'linewidth',2,'handlevisibility','off');
                end
                
                % in situ
                yval1 = T1{s}.gvel(index);
                plot(xval,yval1,'.','handlevisibility','off','markersize',15,'color',[colorSet{s}]);
                
            end
            hold off
        end
        set(gca,'fontsize',13)
        
        % for all grids
        %title(sprintf('source depth = %u m',zs),'fontsize',14,'fontweight','bold');
        title(sprintf('receiver depth = %u m',zr),'fontsize',14,'fontweight','bold');
        %text(0.95,1445,sprintf('rx depth = %u m',zr),'HorizontalAlignment','left','VerticalAlignment','bottom','fontsize',12);
        
        if sum(index)>1
            text(2.25,1448,sprintf('n = %u events',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',12);
        else
            text(2.25,1448,sprintf('n = %u event',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',12);
        end
        grid on
        
        xlim([0.9 2.26])
        ylim([1423 1448])
        
        % add in manual indicator for bottom bounce events for panel 1
        if zr == 30
            indManual = find(T1{4}.gvel < 1000);
            hold on
            plot(DATA.owtt(indManual),1424,'.','handlevisibility','off','markersize',15,'color',[colorSet{4}]);
            strManual = sprintf('%c \\approx %u m/s  ',251,round(mean(T1{4}.gvel(indManual))));
            text(mean(DATA.owtt(indManual)),1424,strManual,'HorizontalAlignment','right','VerticalAlignment','baseline','color',[colorSet{4}]);
            hold off
        end
        
        yticks([1425:5:1445]);
        if mod(count,2)~=1
            yticklabels([])
        else
            ylabel('group velocity [m/s]');
        end
        
        xlabel('one way travel time [s]');
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


plot(NaN,NaN,'k.','markersize',10)
plot(NaN,NaN,'w');
plot(NaN,NaN,'w');


% add legend 2 -- shape
for nb = 0:4
    scatter(NaN,NaN,shapeBounce{nb+1},'MarkerEdgeColor','k');
end

lgdstr = {'HYCOM','Baseline','Chosen Weights','','',...
    'minimal bounce','','',...
    'direct path','1 bounce','2 bounces','3 bounces','4 bounces'};
lgd = legend(lgdstr,'fontsize',12,'location','NorthWestOutside');
%title(lgd,'SSP Source & Multipath Structure');
legend boxoff
hold off

% title
sgtitle('Group velocity predictions for a source depth = 30 m','fontsize',17,'fontweight','bold')
%%
h_printThesisPNG('SLIDES-gvel-comparison');