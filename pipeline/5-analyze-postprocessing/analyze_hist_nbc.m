%% prep workspace
clear; clc; close all;

%% load data

[DATA,INDEX] = h_unpack_bellhop('../bellhop-gvel-gridded/gveltable.csv');

%% load simulation
listing = dir('../bellhop-gvel-gridded/csv_arr/*gridded.csv');
[T,colorSet] = h_get_nbc(listing,DATA,INDEX);

% for k = 1:numel(listing)
%     T0 = readtable([listing(k).folder '/' listing(k).name]);
%     T0.index = T0.index + 1;
%     b = split(listing(k).name,'.');
%     tName{k} = b{1};
%     
%     % assign gvel for each index by closest time comparison
%     for j = 1:numel(T0.index)
%         delay = DATA.owtt(j);
%         tableDelay = table2array(T0(j,2:6));
%         [~,here] = min(abs(tableDelay - delay));
%         T0.gvel(j) = DATA.recRange(j)./tableDelay(here);
%         T0.owtt(j) = tableDelay(here);
%         T0.numBounces(j) = here-1;
%         if sum(j == INDEX.bad) == 1
%             T0.gvel(j) = NaN;
%         end
%     end
%     T{k} = T0;
% end
% 
% % 1 = artifact-baseval
% % 2 = artifact-eeof
% % 3 = fixed-baseval
% % 4 = fixed-eeof
% % 5 = hycom

% load modem marker information
load p_modemMarkerDetails

 % colorSet = {[0 0 0],[0 0 0],[232, 153, 35]./256,[0 85 135]./256,[152 134 117]./256};

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

% save plot
% h_printThesisPNG('gvel-owtt-newalgorithm');

%% plot all data RANGE ANOMALY

figure('name','rangeanomaly-by-owtt','renderer','painters','position',[108 108 1100 900]);
t = tiledlayout(3,2,'TileSpacing','none','Padding','compact');

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
            plot([0 4],[0 0],'--','linewidth',3,'color',[0 0 0 0.6],'handlevisibility','off');

            for s = [5 3 4]
                xval = DATA.owtt(index);
                yval = T{s}.gvel(index) .* DATA.owtt(index) - DATA.recRange(index);
                                
                % remove nans
                xval = xval(~isnan(yval));
                yval = yval(~isnan(yval));
                
                % sort
                [xval,shuffle] = sort(xval);
                yval = yval(shuffle);
                
                % make boundary
                b = boundary(xval,yval);
                p = patch(xval(b),yval(b),colorSet{s});
                p.FaceAlpha = .2;
                p.EdgeColor = colorSet{s};
                p.LineWidth = 3;
                
                
            end
            hold off
        end
        set(gca,'fontsize',13)
        
        % for all grids
        title(sprintf('source depth = %u m',zs),'fontsize',14,'fontweight','bold');
        text(2.25,20,sprintf('rx depth = %u m',zr),'HorizontalAlignment','right','VerticalAlignment','bottom','fontsize',11);
        
        if sum(index)>1
            text(2.25,20,sprintf('n = %u events',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
        else
            text(2.25,20,sprintf('n = %u event',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
        end
        grid on
        
        xlim([0.9 2.26])
        ylim([-11 21]);
      
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

% add legend
nexttile(1);
hold on
for s = [3 4 5]
    plot(NaN,NaN,'-','color',colorSet{s});
end
lg = legend('HYCOM','Baseline','Chosen Weights','location','southeast');
title(lg,'Sound Speed Inputs');

% title
sgtitle('Post-processed range error by source and receiver depths','fontsize',17,'fontweight','bold')
% h_printThesisPNG('range-error-owtt-newalgorithm')

%% histogram of all events

figure('name','rangeanomaly-histogram','renderer','painters','position',[108 108 1200 500]);
clear h;

edges = [-14:2:22];
count = 0;
for s = [5 3 4]
    count = count + 1;
    T{s}.rangeAnomaly = T{s}.gvel .* DATA.owtt - DATA.recRange;
    
    h(count,:) = histcounts(T{s}.rangeAnomaly,edges,'normalization','count');
end

B = bar(edges(1:end-1),h,0.9,'FaceColor','flat','EdgeColor','none');
count = 0;
for s = [5 3 4]
   count = count + 1;
   B(count).CData = colorSet{s};
   B(count).FaceAlpha = 0.8;
end
grid on
xlim([-12 22])
xticks(edges+1);
set(gca,'fontsize',14);
title('Histogram of post-processed range error in 2 meter bins');
xlabel('range error [m]');
ylabel('count');
yticks([0:50:400]);

legend('HYCOM','Baseline','Chosen Weights');

hold on
buff = -100;
ylim([buff 400]);

plot([0 0],[buff 0],'k:','linewidth',2,'handlevisibility','off');

kbuff = 25;
kcount = 0;
for s = [5 3 4]
    kcount = kcount + 1;
    meanVal = mean(T{s}.rangeAnomaly,'omitnan');
    xQuant1 = quantile(T{s}.rangeAnomaly,[0 1]);
    xQuant2 = quantile(T{s}.rangeAnomaly,[.25 .5 .75]);
    
    plot(xQuant1,ones(2,1).*-kcount*kbuff,'handlevisibility','off','color',[colorSet{s} 0.4]);
    plot(xQuant1,-kcount*kbuff,'.','handlevisibility','off','color',colorSet{s},'MarkerSize',15);
    plot(xQuant2,-kcount*kbuff,'o','handlevisibility','off','color',colorSet{s});
    plot(meanVal,-kcount*kbuff,'d','color',colorSet{s},'MarkerSize',8,'handlevisibility','off');
end
    
hold off

% h_printThesisPNG('rangeError-hist1');

%% histogram of all events by num bounces

figure('name','rangeanomaly-histogram-numbounces','renderer','painters','position',[108 108 1200 900]);
clear h;
hold on

tiledlayout(5,1,'TileSpacing','compact');

for nb = [0:4]

nexttile;

edges = [-14:2:22];
count = 0;
for s = [5 3 4]
    count = count + 1;
    ind = T{s}.numBounces == nb;
    rangeAnomaly = T{s}.gvel(ind) .* DATA.owtt(ind) - DATA.recRange(ind);
    
    h(count,:) = histcounts(rangeAnomaly,edges,'normalization','count');
end
hold off

B = bar(edges(1:end-1),h,0.9,'FaceColor','flat','EdgeColor','none');
count = 0;
for s = [5 3 4]
    count = count + 1;
   B(count).CData = colorSet{s};
   B(count).FaceAlpha = 0.8;
end
grid on
xlim([-12 22])

xticks(edges+1);
set(gca,'fontsize',13);
title(sprintf('number of bounces = %u',nb));

if nb == 4
    xlabel('range error [m]');
end

end

nexttile(1);
legend('HYCOM','Baseline','Chosen Weights');
sgtitle('Histogram of post-processed range error by number of bounces','fontsize',17,'fontweight','bold');
% h_printThesisPNG('rangeError-hist2');