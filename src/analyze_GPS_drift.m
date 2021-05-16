%% analyze_GPS_drift.m

clear; clc; close all;

A = load('./data-prep/tobytest-recap-full.mat'); % loads "event"
global RECAP modem_labels SIM_NEW
RECAP = h_unpack_experiment(A.event);
modem_labels = {'North','South','East','West','Camp'};

%% load post-processing, new algorithm
listing = dir('./bellhop-gvel-gridded/csv_arr/*gridded.csv');

for f = 1:numel(listing)
    T0 = readtable([listing(f).folder '/' listing(f).name]);
    T0.index = T0.index + 1;
    b = split(listing(f).name,'.');
    tName{f} = b{1};
    
    % assign gvel for each index by closest time comparison
    for k = 1:numel(T0.index)
        delay = RECAP.data_owtt(k);
        tableDelay = table2array(T0(k,2:6));
        [~,here] = min(abs(tableDelay - delay));
        T0.gvel(k) = RECAP.data_range(k)./tableDelay(here);
        T0.owtt(k) = tableDelay(here);
        T0.numBounces(k) = here-1;
    end
    
    T0.rangeEstimate = RECAP.data_owtt.' .* T0.gvel;
    T0.rangeEstimate(T0.rangeEstimate > 10000) = NaN;
    SIM_NEW{f} = T0;
end

%% 5x5 grid

figure('name','gps-and-time-drift','renderer','painters','position',[108 108 1300 1100]); clf;
t = tiledlayout(5,5,'TileSpacing','compact','Padding','compact');

for r = 1:5
    for c = 1:5
        
        % tileNum
        tileNum = (r-1).*5 + c;
        
        % tx and rx nodes
        txNode = modem_labels{r};
        rxNode = modem_labels{c};
        
        % if r == c, do nothing
        if r == c

        % if r <c, do dx/dy 
        elseif r < c
            nexttile(tileNum);
            h_d1d2(txNode,rxNode);
            
            if c - r == 1
                %xlabel('GPS \deltaR [m]')
                %ylabel('algorithm \deltaR [m]')
                
                xlabel('\deltat [ms]');
                ylabel('GPS \deltaR [m]');
            end
            
        % if r > c, do dt/dR    
        elseif r > c   
            nexttile(tileNum);
            h_dxdy(txNode,rxNode);
            
            % add label for when tileNum == 21
            if tileNum == 21
                xlabel('GPS \deltax [m]');
                ylabel('GPS \deltay [m]');
                xticklabels auto
                yticklabels auto
            end
        end
    end
end

%% helper function
function [] = h_dxdy(txNode,rxNode)
global RECAP;

myColor = [51 152 152]./256;

ind1 = strcmp(RECAP.tag_tx,{txNode}) & strcmp(RECAP.tag_rx,{rxNode});
ind2 = strcmp(RECAP.tag_tx,{rxNode}) & strcmp(RECAP.tag_rx,{txNode});
index = ind1 | ind2;

x1 = RECAP.rx_x(index);
y1 = RECAP.rx_y(index);

x2 = RECAP.tx_x(index);
y2 = RECAP.tx_y(index);

dx = abs(x2-x1)-mean(abs(x2-x1));
dy = abs(y2-y1)-mean(abs(y2-y1));

scatter(dx,dy,100,'filled','MarkerFaceAlpha',0.15,'MarkerFaceColor',myColor);
set(gca,'fontsize',12);

text(10,10,sprintf('n=%u',sum(index)),'verticalalignment','top','horizontalalignment','right');

xlim([-10 10]);
ylim([-10 10]);
grid on
yticks([-8:4:8])
xticks([-8:4:8]);
yticklabels([]);
xticklabels([]);

title(sprintf('%s <--> %s',txNode,rxNode))
end

%% helper function
function [] = h_d1d2(txNode,rxNode)
global RECAP SIM_NEW;

myColor = [5 119 177]./256;

ind1 = strcmp(RECAP.tag_tx,{txNode}) & strcmp(RECAP.tag_rx,{rxNode});
ind2 = strcmp(RECAP.tag_tx,{rxNode}) & strcmp(RECAP.tag_rx,{txNode});
index = ind1 | ind2;

% dr1 -- GPS difference
r1 = RECAP.data_range(index);
dr1 = r1 - median(r1);

t = RECAP.data_owtt(index);
dt = t - median(t);

% dr2 -- ALGORITHM difference
%r2 = SIM_NEW{4}.rangeEstimate(index);
%dr2 = r2 - mean(r1);

scatter(dt*1000,dr1,100,'filled','MarkerFaceAlpha',0.15,'MarkerFaceColor',myColor);
set(gca,'fontsize',11);

grid on

ssp = 1450/1000;
xlim([-11 11]);
ylim(ssp*[-11 11]);

hold on
plot([-11 11],ssp*[-11 11],'k--','linewidth',1);
hold off

% % x/y lim
%xlim([-10 20]);
%ylim([-10 20]);
% 
% % x/y ticks
% xticks(tTick);
% yticks(tTick.*ssp);
% xticklabels([]);
% yticklabels([]);
% 
% hold on
% plot([tBuff],ssp*tBuff,'--','color',[0.5 0.5 0.5 0.5]);
% hold off

title(sprintf('%s <--> %s',rxNode,txNode))
end

