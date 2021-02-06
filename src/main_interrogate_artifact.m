%% main_interrogate_artifact.m
% quantify role of artifact in ray shift

clear; clc; close all;

%% parameters

% source depths
% zs = [20 30 90];
zs = 90;

%% prep workspace
weights = [-10 -9.257 -1.023 3.312 -5.067 1.968 1.47].';
OBJ_EOF = eb_read_eeof('../data/eeof_itp_Mar2013.nc',true);

% traceGray
myGray = [0.6 0.6 0.6 0.3];
myPurple = [150 0 150]./256;

% water column depth
zMax = 2680;
Zq = 0:zMax;

% set up artifact object
artifact.baseval = OBJ_EOF.baseval;
artifact.ssp = OBJ_EOF.baseval + (OBJ_EOF.eofs * weights);
artifact.depth = OBJ_EOF.depth;
artifact.Cq = interp1(artifact.depth,artifact.ssp,Zq,'pchip');

% set up fixed object
fixed.baseval = OBJ_EOF.baseval;
fixed.baseval(1) = fixed.baseval(2);
fixed.ssp = fixed.baseval + (OBJ_EOF.eofs * weights);
fixed.depth = OBJ_EOF.depth;
fixed.Cq = interp1(fixed.depth,fixed.ssp,Zq,'pchip');

% ray tracing parameters
theta0 = -50:4:50;
numstep = 1000;
sstep = 11;

%% run raytraces
[artifact.R,artifact.Z,artifact.T]  = eb_raytrace(zs,theta0,numstep,sstep,Zq,artifact.Cq,0,zMax);
[fixed.R,fixed.Z,fixed.T]           = eb_raytrace(zs,theta0,numstep,sstep,Zq,fixed.Cq,0,zMax);

%% figure --- plot both rays
figure('Name','rays','renderer','painters','position',[200 200 1200 700])

subplot(2,10,[1:2])
plot(artifact.Cq,Zq,'linewidth',3,'color',myPurple);
h1_beautify();
title('SSP with the artifact');
ylabel('depth [m]');

subplot(2,10,[11:12])
plot(fixed.Cq,Zq,'linewidth',3,'color',myPurple);
h1_beautify();
title('Corrected SSP');
ylabel('depth [m]');

subplot(2,10,[3:10])
plot(artifact.R.',artifact.Z.','color',myGray);
hold on
plot(1,zs,'kd')
hold off
h1_beautify();
title(sprintf('Artifact raytrace [zs = %u m]',zs));
xlim([0 4000]);
xticks([500:500:4000]);
xticklabels([500:500:4000]);
yticklabels([]);

subplot(2,10,[13:20])
plot(fixed.R.',fixed.Z.','color',myGray)
hold on
plot(1,zs,'kd')
hold off
h1_beautify();
title(sprintf('Corrected raytrace [zs = %u m]',zs));
xlim([0 4000]);
xticks([500:500:4000]);
xticklabels([500:500:4000]);
yticklabels([]);
xlabel('range [m]');

% save
h_printThesisPNG(sprintf('zs%u-artifact-raytrace.png',zs));

%% figure --- plot ray shift by theta

figure('Name','comparison-theta','renderer','painters','position',[200 200 1200 700])

% axes handle
h1 = tight_subplot(2,1,.03,.1,.1);

% time space to interpolate to (linear, usefully dense);
ttSpace = 0.5:.05:6;

% sort data
for dTH = 1:numel(theta0)
    
    F = h_interp_owtt(dTH,fixed,ttSpace);
    A = h_interp_owtt(dTH,artifact,ttSpace);
    
    delta_owtt_R(dTH,:) = (A.R - F.R) ./ F.R  * 100;
    delta_owtt_Z(dTH,:) = (A.Z - F.Z) ./ zMax * 100;
end

% violin plot for range
axes(h1(1));
violinplot(delta_owtt_R.',theta0,...
    'ViolinColor',myPurple,'ViolinAlpha',.1,'EdgeColor',[0.6 0.6 0.6],'BoxColor',[0.3 0.3 0.3],'MedianColor',[0 0 0],'Width',0.25);
grid on
ylabel('% of total range traveled');
set(gca,'fontsize',14)
xlim([0.5 numel(theta0)+0.5]);
xticklabels([]);
yticklabels auto

% add info about ttSpace, zs
yMax = ylim();
yMax = yMax(2);
str = sprintf('zs=%u m, owtt = 0.5:0.05:6 s',zs);
text(numel(theta0)+0.5,yMax,str,'HorizontalAlignment','right','VerticalAlignment','bottom','fontsize',13);

% violin plot for depth
axes(h1(2));
violinplot(delta_owtt_Z.',theta0,...
    'ViolinColor',myPurple,'ViolinAlpha',.2,'EdgeColor',[0.6 0.6 0.6],'BoxColor',[0.3 0.3 0.3],'MedianColor',[0 0 0],'Width',0.25);
grid on
set(gca,'fontsize',14)
xlim([0.5 numel(theta0)+0.5]);
grid on
xlabel('\theta = launch angle from horizontal');
ylabel('% of max water depth');
yticklabels auto

sgtitle('Relative error caused by the artifact, visualized by ray launch angle','fontsize',18,'fontweight','bold');

% save
h_printThesisPNG(sprintf('zs%u-artifact-error-by-theta.png',zs));

%% figure : comparison by owtt

figure('Name','comparison-owtt','renderer','painters','position',[200 200 1200 700])

% axes handle
h2 = tight_subplot(1,2,.03,.1,.1);

ttSpace = [0.6 1.3 2.0 4.0 5.0 6.0];

clear tempRo tempZo tempRi tempZi

for tt = 1:numel(ttSpace)
    
    for dTH = 1:numel(theta0)
        
        artRo(dTH) = interp1(artifact.T(dTH,:),artifact.R(dTH,:),ttSpace(tt));
        artZo(dTH) = interp1(artifact.T(dTH,:),artifact.Z(dTH,:),ttSpace(tt));
        
        fixedRi(dTH) = interp1(fixed.T(dTH,:),fixed.R(dTH,:),ttSpace(tt));
        fixedZi(dTH) = interp1(fixed.T(dTH,:),fixed.Z(dTH,:),ttSpace(tt));

    end
    
    delta_th_R(tt,:) = (artRo - fixedRi)./fixedRi * 100;
    delta_th_Z(tt,:) = (artZo - fixedZi)./zMax * 100;
    
end

axes(h2(1));
violinplot(delta_th_R.',ttSpace,...
    'ViolinColor',myPurple,'ViolinAlpha',.2,'EdgeColor',[0.6 0.6 0.6],'BoxColor',[0.3 0.3 0.3],'MedianColor',[0 0 0],'Width',0.4);
grid on
view([90 90])
ylabel('% of total range traveled');
xlabel('travel time [s]');
xlim([0.5 6.5])
yticklabels auto


axes(h2(2));
violinplot(delta_th_Z.',ttSpace,...
            'ViolinColor',myPurple,'ViolinAlpha',.2,'EdgeColor',[0.6 0.6 0.6],'BoxColor',[0.3 0.3 0.3],'MedianColor',[0 0 0],'Width',0.4);
grid on
view([90 90])
ylabel('% of max water depth');
xlim([0.5 6.5])
xticklabels([]);
yticklabels auto

% add info about ttSpace, zs
yMax = ylim();
yMax = yMax(2);
str = sprintf('zs=%u m, theta = -50:4:50',zs);
text(0.5,yMax,str,'HorizontalAlignment','right','VerticalAlignment','bottom','fontsize',13);

sgtitle('Relative error caused by the artifact, visualized by travel time','fontsize',18,'fontweight','bold');

% save
h_printThesisPNG(sprintf('zs%u-artifact-error-by-owtt.png',zs));

%% h1_beautify
function [] = h1_beautify()
grid on
set(gca,'ydir','reverse');
ylim([0 450])
set(gca,'fontsize',12)
end

%% h_interp_owtt
function [output] = h_interp_owtt(dTH,input,ttSpace)
output.R = interp1(input.T(dTH,:),input.R(dTH,:),ttSpace);
output.Z = interp1(input.T(dTH,:),input.Z(dTH,:),ttSpace);
end

