%% prep workspace
clear; clc; close all;

% load modem marker information
load p_modemMarkerDetails

%% load data

[DATA,INDEX] = h_unpack_bellhop('../bellhop-gvel-gridded/gveltable.csv');

%% load simulation
listing = dir('../bellhop-gvel-gridded/csv_arr/*gridded.csv');
[T,colorSet] = h_get_nbc(listing,DATA,INDEX);

%% histogram of all events

figure('name','rangeanomaly-histogram','renderer','painters','position',[108 108 1200 500]);
clear h;

edges = [-14:2:22];
count = 0;
for s = [5 3 4]
    count = count + 1;
    %T{s}.rangeAnomaly = T{s}.gvel .* DATA.owtt - DATA.recRange;
    
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
    rangeAnomalyBounce = T{s}.rangeAnomaly(ind);
    
    h(count,:) = histcounts(rangeAnomalyBounce,edges,'normalization','count');
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