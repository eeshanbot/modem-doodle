%% slides_gvel_comparison
% show visual comparison, for a source depth of 30 m, for v1 & v2 gvel
% predictions

%% prep workspace
clear; clc; close all; addpath('../../src/');

% unpack Bellhop gvel table
[DATA,INDEX] = h_unpack_bellhop('../bellhop-gvel-gridded/gveltable.csv');

% DEPTH
ZS = 90;

%% load post-processing sim for NBC
listing2 = dir('../bellhop-gvel-gridded/csv_arr/*gridded.csv');
[T2,colorSet] = h_get_nbc(listing2,DATA,INDEX);

%% load post-processing sim for MBC
listing1 = dir('../bellhop-gvel-gridded/csv_arr/*old.csv');
T1 = h_get_mbc(listing1,DATA);

%% plot all data group velocity

figure('name','gvel-by-owtt','renderer','painters','position',[108 108 1300 700]);
tiledlayout(1,2,'TileSpacing','none','Padding','compact');

shapeBounce = {'o','x','s','^','d'};

count = 0;
for zs = ZS
    index1 = DATA.sourceDepth == zs;
    
    for zr = [30 90]
        index2 = DATA.recDepth == zr;
        
        count = count + 1;
        nexttile;
        
        index = boolean(index1.*index2.*INDEX.valid);
        
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
        
        hold on
        plot(DATA.owtt(index),DATA.gvel(index),'.','color',[200, 78, 0]./256,'handlevisibility','off','MarkerSize',10)
        hold off
        
        % for all grids
        %title(sprintf('source depth = %u m',zs),'fontsize',14,'fontweight','bold');
        title(sprintf('receiver depth = %u m',zr),'fontsize',14,'fontweight','bold');
        %text(0.95,1445,sprintf('rx depth = %u m',zr),'HorizontalAlignment','left','VerticalAlignment','bottom','fontsize',12);
        
        xlim auto
        % xlim([0.9 2.26])
        ylim([1419 1449])
        xx = xlim();
        
        if sum(index)>1
            text(xx(2),1449,sprintf('n = %u events',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',12);
        else
            text(xx(2),1449,sprintf('n = %u event',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',12);
        end
        grid on

        % add in manual indicator for bottom bounce events for panel 1
        if ZS == 30 && zr == 30
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
plot(NaN,NaN,'w');
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

% legend for data
plot(NaN,NaN,'w');
plot(NaN,NaN,'w');
plot(NaN,NaN,'.','color','markersize',15);

lgdstr = {'\bf{SOUND SPEED SOURCE}','HYCOM','Baseline','Chosen Weights','','\bf{MINIMAL BOUNCE CRITERIA}',...
    'Minimal bounce','','\bf{NEAREST BOUNCE CRITERIA}',...
    'Direct path','1 bounce','2 bounces','3 bounces','4 bounces',...
    '','\bf{IMPLIED SPEED}','GPS range divided by OWTT'};
lgd = legend(lgdstr,'fontsize',12,'location','WestOutside');
hold off
legend boxoff

% title
titlestr = sprintf('Group velocity predictions for a source depth = %u m',zs);
sgtitle(titlestr,'fontsize',17,'fontweight','bold')

%%
% h_printThesisPNG(sprintf(SLIDES-gvel-comparison-wdata-%u',ZS));