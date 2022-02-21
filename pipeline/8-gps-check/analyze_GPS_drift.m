%% analyze_GPS_drift.m

%% prep workspace
clear; clc; close all;
addpath('./../../src/');

%% load data

A = load('../../data/tobytest-recap-clean.mat'); % loads "event"
global RECAP modem_labels colorDepth sourceDepth alphaDepth sspGVEL
RECAP = h_unpack_experiment(A.event);
modem_labels = {'North','South','East','West','Camp'};

colorDepth = containers.Map([20 30 90],{[70 240 240]./256,[0 130 200]./256,[0 0 128]./256});
sourceDepth = containers.Map([20 30 90],{'>','^','v'});
alphaDepth = containers.Map([20 30 90],[.5 .4 .4]);
sspGVEL = 1440/1000; % meters / millisecond

%% 5x5 grid

% figure('name','gps-and-time-drift','renderer','painters','position',[108 108 1300 1100]); clf;
% tiledlayout(5,5,'TileSpacing','compact','Padding','compact');

% for r = 1:5
%     for c = 1:5
%         
%         % tileNum
%         tileNum = (r-1).*5 + c;
%         
%         % tx and rx nodes
%         txNode = modem_labels{r};
%         rxNode = modem_labels{c};
%         
%         % if r == c, do nothing
%         if r == c
% 
%         % if r <c, do dx/dy 
%         elseif r < c
%             nexttile(tileNum);
%             h_dtdR(txNode,rxNode,100);
%             
%             if c - r == 1
%                 %xlabel('GPS \deltaR [m]')
%                 %ylabel('algorithm \deltaR [m]')
%                 
%                 xlabel('\deltat [ms]');
%                 ylabel('GPS \deltaR [m]');
%             end
%             
%         % if r > c, do dt/dR    
%         elseif r > c   
%             nexttile(tileNum);
%             h_dxdy(txNode,rxNode,100);
%             
%             if c == 1
%                 ylabel('GPS \deltay [m]');
%                 yticklabels auto
%             end
%             
%             if r == 5
%                 xlabel('GPS \deltax [m]');
%                 xticklabels auto
%             end
%             
%             % add label for when tileNum == 21
%             if tileNum == 21
%                 xlabel('GPS \deltax [m]');
%                 xticklabels auto
%             end
%             
%             if tileNum == 24
%                 cb = colorbar;
%                 cb.Ticks = 0:4:12;
%                 cb.TickLabels = num2cell(0:4:12);
%                 cb.Label.String = 'time past [hours]';
%                 cb.Label.FontSize = 10;
%             end
%         end
%     end
% end
% 
% %% legend -- 1
% nexttile(1);
% 
% % legend
% % add legend
% hold on
% for s = [20 30 90]
%     plot(NaN,NaN,'color',colorDepth(s),'linewidth',6);
% end
% 
% for r = [20 30 90]
%     plot(NaN,NaN,sourceDepth(r),'color','k')
% end
% hold off
% lgdstr = {' 20 m',' 30 m',' 90 m',' 20 m',' 30 m',' 90 m'};
% 
% lg1 = legend(lgdstr,'location','south','NumColumns',2,'fontsize',11);
% title(lg1,'   source depth & receiver depth');
% 
% set(gca,'XColor','white');
% set(gca,'YColor','white');
% 
% % export
% % h_printThesisPNG('gps-drift');

%% secondary figure

figure('name','gps-drift-example','renderer','painters','position',[108 108 1200 600]); clf;
t = tiledlayout(1,2,'TileSpacing','compact');

rbounds1 = [-2.6 2.6];
rticks1 = [-2:2];

xbounds2 = [-1.05 1.05];
xticks2 = [-1:0.5:1];

% % panel 1
% nexttile;
% h_dxdy('North','East',200);
% %colorbar;
% xlim(rbounds1)
% ylim(rbounds1)
% xticks(rticks1);
% yticks(rticks1);
% xticklabels auto
% yticklabels auto
% xlabel('GPS \deltax [m]');
% ylabel('GPS \deltay [m]');
% title('GPS drift --- North and East buoys','fontsize',15);
% 
% % panel 2
% nexttile;
% h_dxdy('South','West',200);
% xlim(rbounds1)
% ylim(rbounds1)
% xticks(rticks1);
% yticks(rticks1);
% xticklabels auto
% yticklabels auto
% xlabel('GPS \deltax [m]');
% ylabel('GPS \deltay [m]');
% title('GPS drift --- South and West buoys','fontsize',15);
% cb = colorbar;
% cb.Ticks = 0:2:14;
% cb.TickLabels = num2cell(0:2:14);
% cb.Label.String = 'time past [hours]';

% panel 3
nexttile;
h_dtdR('East','North',200);
axis square
xlim(xbounds2);
xticks(xticks2);
ylim(xbounds2.*sspGVEL);
yticks(xticks2.*sspGVEL);
title('GNSS noise between North and East buoys','fontsize',15);
ylabel('GNSS \deltaR [m]');
xlabel('\deltat [ms]');

% panel 4
nexttile;
h_dtdR('West','South',200);
axis square
xlim(xbounds2);
xticks(xticks2);
ylim(xbounds2.*sspGVEL);
yticks(xticks2.*sspGVEL);
title('GNSS noise between South and West buoys','fontsize',15);
%ylabel('GPS \deltaR [m]');
xlabel('\deltat [ms]');

%% legend
% add legend
hold on

plot(NaN,NaN,'w');
for s = [20 30 90]
    plot(NaN,NaN,'color',colorDepth(s),'linewidth',6);
end

plot(NaN,NaN,'w');
for r = [20 30 90]
    plot(NaN,NaN,sourceDepth(r),'color','k')
end
hold off
lgdstr = {'\bf{tx depth (color)}',' 20 m',' 30 m',' 90 m','\bf{rx depth (shape)}', ' 20 m',' 30 m',' 90 m'};

lg1 = legend(lgdstr,'location','eastOutside','NumColumns',1,'fontsize',10);
%title(lg1,{'tx depth (color)','rx depth (shape)'});

%% export
h_printThesisPNG('gps-drift-example');

%% helper function
function [] = h_dxdy(txNode,rxNode,scatterSize)
global RECAP;

myColor = [153, 51, 153]./256;

ind1 = strcmp(RECAP.tag_tx,{txNode}) & strcmp(RECAP.tag_rx,{rxNode});
ind2 = strcmp(RECAP.tag_tx,{rxNode}) & strcmp(RECAP.tag_rx,{txNode});
index = ind1 | ind2;

x1 = RECAP.rx_x(index);
y1 = RECAP.rx_y(index);

x2 = RECAP.tx_x(index);
y2 = RECAP.tx_y(index);

dx = abs(x2-x1)-mean(abs(x2-x1));
dy = abs(y2-y1)-mean(abs(y2-y1));

ZR = RECAP.rx_z(index);
ZS = RECAP.tx_z(index);
timeInHours = 24.*(RECAP.data_time(index) - min(RECAP.data_time));
scatter(dx,dy,scatterSize,timeInHours,'filled','MarkerFaceAlpha',0.5,'handleVisibility','off');
colormap(parula(7));
caxis([0 14]);

text(10,10,sprintf('n=%u',sum(index)),'verticalalignment','top','horizontalalignment','right');

xlim([-10 10]);
ylim([-10 10]);
grid on
yticks([-8:4:8])
xticks([-8:4:8]);
yticklabels([]);
xticklabels([]);

title(sprintf('%s <--> %s',txNode,rxNode))
set(gca,'fontsize',12);

end

%% helper function
function [] = h_dtdR(txNode,rxNode,scatterSize)
global RECAP sourceDepth colorDepth alphaDepth sspGVEL

ind1 = strcmp(RECAP.tag_tx,{txNode}) & strcmp(RECAP.tag_rx,{rxNode});
ind2 = strcmp(RECAP.tag_tx,{rxNode}) & strcmp(RECAP.tag_rx,{txNode});
index = ind1 | ind2;

% dr1 -- GPS difference
r1 = RECAP.data_range(index);
dr1 = r1 - median(r1);

t = RECAP.data_owtt(index);
dt = t - median(t);

ZR = RECAP.rx_z(index);
ZS = RECAP.tx_z(index);

hold on
for k = 1:numel(dt)
    zr = ZR(k);
    zs = ZS(k);
    scatter(dt(k)*1000,dr1(k),scatterSize,'filled',sourceDepth(zr),'MarkerFaceColor',colorDepth(zs),'MarkerFaceAlpha',alphaDepth(zs),'handleVisibility','off');
end
hold off

grid on

xlim([-11 11]);
ylim(sspGVEL*[-11 11]);

hold on
plot([-11 11],sspGVEL*[-11 11],'k--','linewidth',1,'handlevisibility','off');
hold off

title(sprintf('%s <--> %s',rxNode,txNode))
set(gca,'fontsize',12);

end

