%% analyze_travel_time_vs_time.m

%% prep workspace
clear; clc; close all;
addpath('./../../src/');

%% load data

A = load('../../data/tobytest-recap-clean.mat'); % loads "event"
global RECAP
RECAP = h_unpack_experiment(A.event);

%% nodes

[r,t,timeInHours] = h_dtdT('North','Camp');

%% helper function
function [r1,t1,time] = h_dtdT(txNode,rxNode)
figure('name','time-check','position',[108 108 800 400]);

global RECAP;

myColor = [153, 51, 153]./256;

ind1 = strcmp(RECAP.tag_tx,{txNode}) & strcmp(RECAP.tag_rx,{rxNode});
ind2 = strcmp(RECAP.tag_tx,{rxNode}) & strcmp(RECAP.tag_rx,{txNode});
index = ind1 | ind2;

% dr1 -- GPS difference
r1 = RECAP.data_range(index);

t1 = RECAP.data_owtt(index);
time = RECAP.data_time(index);

yyaxis right
plot(time,r1,'o');
ylabel('\Delta R from GPS [m]')
xlabel('hours of toby test');
ybounds = ylim();
grid on
datetick('x','mmm-dd HHMM');
a = get(gca,'XTickLabel');  
set(gca,'XTickLabel',a,'fontsize',12)

yyaxis left
plot(time,t1,'o');
ylabel('\Delta t from modem [s]');
grid on

title(sprintf('\\Deltat and \\DeltaR between %s and %s beacons',txNode,rxNode));
save_str = sprintf('%s-%s-timecheck',txNode,rxNode);

export_fig(save_str,'-q101','-r300','-painters','-png')
end