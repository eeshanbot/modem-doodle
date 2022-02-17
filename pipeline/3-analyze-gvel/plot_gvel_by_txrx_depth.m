%% prep workspace
clear; clc; close all;

% load modem marker information
load p_modemMarkerDetails
load isovelocity-ssp.mat

%% load data
[DATA,INDEX] = h_unpack_bellhop('../bellhop-gvel-gridded/gveltable.csv');

%% load simulation
listing = dir('../bellhop-gvel-gridded/csv_arr/*gridded.csv');
[T2,colorSet] = h_get_nbc(listing,DATA,INDEX);

%% load post-processing sim for MBC
listing1 = dir('../bellhop-gvel-gridded/csv_arr/*old.csv');
T1 = h_get_mbc(listing1,DATA);

%% plot all data group velocity
figure('name','gvel-by-owtt','renderer','painters','position',[108 108 1300 800]);
tiledlayout(2,3,'TileSpacing','none','Padding','none');

shapeBounce = {'o','x','s','^','d'};

count = 0;
for zr = [30 90]
    index2 = DATA.recDepth == zr;
    
    for zs = [20 30 90]
        index1 = DATA.sourceDepth == zs;
        
        count = count + 1;
        nexttile;
        
        index = logical(index1.*index2.*INDEX.valid);
        
        % add iso velocity w/ error bar
        yline(iso.avg,'k','linewidth',2,'handlevisibility','off');
        yline(iso.avg+iso.std,'k:','linewidth',2,'handlevisibility','off');
        yline(iso.avg-iso.std,'k:','linewidth',2,'handlevisibility','off');
        
        % implied effective sound speed (GPS)
        sgps = scatter(DATA.owtt(index),DATA.gvel(index),50,'o','filled','handlevisibility','off');
        sgps.MarkerEdgeColor = 'none';
        sgps.MarkerFaceColor = [200, 78, 0]./256;
        sgps.MarkerFaceAlpha = 0.2;

        %p = patch([0 5 5 0 0],...
            %[iso.avg-iso.std,iso.avg-iso.std,iso.avg+iso.std,iso.avg+iso.std,iso.avg-iso.std],'k','handlevisibility','off');
        %p.FaceAlpha = 0.07;
        %p.EdgeColor = 'none';
        
        if sum(index)>=1
            % plot
            hold on
            for s = [5 3 4]
                xval = DATA.owtt(index);
                yval = T2{s}.gvel(index);
                
                numBounces = T2{s}.numBounces(index);
                
                % remove nans
                numBounces = numBounces(~isnan(yval));
                xval = xval(~isnan(yval));
                yval = yval(~isnan(yval));
                
                % MBC
                for nb = 0:4
                    indBounce = find(numBounces == nb);
                    scatter(xval(indBounce),yval(indBounce),150,shapeBounce{nb+1},'MarkerEdgeColor',[colorSet{s}],'linewidth',2,'handlevisibility','off');
                end
                
                % NBC
                yval1 = T1{s}.gvel(index);
                plot(xval,yval1,'.','handlevisibility','off','markersize',15,'color',[colorSet{s}]);
            end
        end
        set(gca,'fontsize',13)
        

        hold off
        
        text(2.24,1425,sprintf('receiver depth = %u m',zr),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',12,'fontweight','bold');
        text(2.24,1425,sprintf('source depth = %u m',zs),'HorizontalAlignment','right','VerticalAlignment','bottom','fontsize',12,'fontweight','bold');
        
        if sum(index)>1
            text(2.24,1423.5,sprintf('n = %u events',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
        else
            text(2.24,1423.5,sprintf('n = %u event',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
        end
        grid on
        
        xlim([0.9 2.26])
        xticks([1:.25:2.25]);
        
        ylim([1420 1450.5])
        yticks([1420:5:1450]);
        
        if count == 4
            xlabel('one way travel time [s]');
            ylabel('sound speed [m/s]');
        else
            yticklabels([]);
            xticklabels([]);
        end
        
    end
end

%% add legend

% add legend
nexttile(4);

% add legend 1 -- color
hold on
plot(NaN,NaN,'w');
plot(NaN,NaN,'k','linewidth',4);
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
plot(NaN,NaN,'.','color',[200, 78, 0]./256,'markersize',15);

lgdstr = {'\bf{SOUND SPEED SOURCE}','Isovelocity','HYCOM','Baseline','Chosen Weights','','\bf{MINIMAL BOUNCE CRITERIA}',...
    'Minimal bounce','','\bf{NEAREST BOUNCE CRITERIA}',...
    'Direct path','1 bounce','2 bounces','3 bounces','4 bounces',...
    '','\bf{IMPLIED SPEED}','GPS range divided by OWTT'};
lgd = legend(lgdstr,'fontsize',12,'location','WestOutside');
hold off
legend boxoff

% % add legend
% nexttile(1);
% 
% % add legend 1 -- color
% hold on
% plot(NaN,NaN,'w');
% plot(NaN,NaN,'k','linewidth',4);
% 
% for s = [5 3 4]
%     plot(NaN,NaN,'color',colorSet{s},'linewidth',5);
% end
% plot(NaN,NaN,'w');
% plot(NaN,NaN,'w');
% 
% % add legend 2 -- shape
% for nb = 0:4
%     scatter(NaN,NaN,shapeBounce{nb+1},'MarkerEdgeColor','k');
% end
% 
% lgdstr = {'\bf{SOUND SPEED SOURCE}','Isovelocity','HYCOM','Baseline','Chosen Weights','','\bf{MULTIPATH STRUCTURE}','direct path','1 bounce','2 bounces','3 bounces','4 bounces'};
% lgd = legend(lgdstr,'numcolumns',1,'fontsize',11,'location','WestOutside');
% %title(lgd,'SSP Source & Multipath ID');
% legend boxoff
% hold off

% title
sgtitle({'Effective sound speed estimates by source and receiver depths'},'fontsize',17,'fontweight','bold')

%% save plot
h_printThesisPNG('gvel-txrxdepth-wIso-wGPS');