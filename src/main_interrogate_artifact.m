%% main_interrogate_artifact.m
% quantify role of artifact in ray shift

clear; clc; close all;

%% parameters

% source depths
% zs = [20 30 90];
zs = 20;

%% prep workspace
weights = [-10 -9.257 -1.023 3.312 -5.067 1.968 1.47].';
OBJ_EOF = eb_read_eeof('../data/eeof_itp_Mar2013.nc',true);

% traceGray
myGray = [0.6 0.6 0.6 0.3];
myBlue   = [70 240 240]./256;
myRed    = [240 50 230]./256;
myPurple = myBlue/2 + myRed/2;

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
plot(artifact.Cq,Zq);
h1_beautify();
title('SSP with the artifact');
ylabel('depth [m]');

subplot(2,10,[11:12])
plot(fixed.Cq,Zq);
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
%h_printThesisPNG(sprintf('zs%u-artifact-raytrace.png',zs));

%% figure --- plot ray shift by theta

figure('Name','comparison-theta','renderer','painters','position',[200 200 1200 700])

ttSpace = linspace(.5,7);

axisZ = 0;
axisR = 0;
for dTH = 1:numel(theta0)
    
    F = h_interp_owtt(dTH,fixed,ttSpace);
    A = h_interp_owtt(dTH,artifact,ttSpace);
    
    deltaR = A.R - F.R;
    deltaZ = A.Z - F.Z;
    
    clear alphaVal;
    for d = 1:numel(deltaR)
        indR = abs(deltaR - deltaR(d)) <= 1.5*std(deltaR);
        indZ = abs(deltaZ - deltaZ(d)) <= 1.5*std(deltaZ);
        sizeValR(d) = sum(indR);
        sizeValZ(d) = sum(indZ);
    end
    
    sizeValZ = sizeValZ.^2./numel(theta0);
    sizeValZ(sizeValZ<40) = 40;
    
    sizeValR = sizeValR.^2./numel(theta0);
    sizeValR(sizeValR<40) = 40;
    
    % reorder by size
    [sizeValR,indR] = sort(sizeValR,'descend');
    [sizeValZ,indZ] = sort(sizeValZ,'descend');
    deltaR = deltaR(indR);
    deltaZ = deltaZ(indZ);
    
    here = theta0(dTH) .* ones(size(deltaR));
    
    xbar = [here(1)-1 here(1)+1];
       
    subplot(2,1,1);
    hold on
    scatter(here,deltaR,sizeValR,'o','filled','MarkerFaceColor','k','MarkerFaceAlpha',0.05)
    plot(xbar,[max(deltaR) max(deltaR)],'color',myRed);
    plot(xbar,[min(deltaR) min(deltaR)],'color',myBlue);
    plot(xbar,[mean(deltaR) mean(deltaR)],'color',myPurple);
    hold off
    
    if axisR < max(abs(deltaR))
        axisR = max(abs(deltaR)); 
    end
    
    subplot(2,1,2);
    hold on
    scatter(here,deltaZ,sizeValZ,'o','filled','MarkerFaceColor','k','MarkerFaceAlpha',0.05);
    plot(xbar,[max(deltaZ) max(deltaZ)],'color',myRed);
    plot(xbar,[min(deltaZ) min(deltaZ)],'color',myBlue);
    plot(xbar,[mean(deltaZ) mean(deltaZ)],'color',myPurple);
    hold off
    
    if axisZ < max(abs(deltaZ))
        axisZ = max(abs(deltaZ)); 
    end
end
    
subplot(2,1,1);
grid on
ylabel('\delta r [m]');
title(sprintf('Absolute error caused by the artifact, visualized by ray launch angle [zs=%u m]',zs));
axis auto
xlim([min(theta0)-2 max(theta0)+2]);
buffR = 0.1.*axisR;
ylim([-axisR-buffR axisR+buffR]);

subplot(2,1,2);
grid on
xlabel('\theta = launch angle from horizontal');
ylabel('\delta z [m]');
xlim([min(theta0)-2 max(theta0)+2]);
buffZ = 0.1.*axisZ;
ylim([-axisZ-buffZ axisZ+buffZ]);

% save
% h_printThesisPNG(sprintf('zs%u-artifact-error.png',zs));

%% figure : comparison by owtt

figure('Name','comparison-owtt','renderer','painters','position',[200 200 1200 700])

ttSpace = [0.6 1.3 2.0 4.0 5.0 6.0];

clear tempRo tempZo tempRi tempZi

for tt = 1:numel(ttSpace)
    
    for dTH = 1:numel(theta0)
        
        tempRo(dTH) = interp1(artifact.T(dTH,:),artifact.R(dTH,:),ttSpace(tt));
        tempZo(dTH) = interp1(artifact.T(dTH,:),artifact.Z(dTH,:),ttSpace(tt));
        
        tempRi(dTH) = interp1(fixed.T(dTH,:),fixed.R(dTH,:),ttSpace(tt));
        tempZi(dTH) = interp1(fixed.T(dTH,:),fixed.Z(dTH,:),ttSpace(tt));

    end
    
    delta_th_R(tt,:) = (tempRo - tempRi)./tempRi * 100;
    delta_th_Z(tt,:) = (tempZo - tempZi)./zMax * 100;
    
end

subplot(1,2,1);
violinplot(delta_th_R.',ttSpace,...
    'ViolinColor',myPurple,'ViolinAlpha',.2,'EdgeColor',[0.6 0.6 0.6],'BoxColor',[0.3 0.3 0.3],'MedianColor',[0 0 0],'Width',0.4);
grid on
view([90 90])
ylabel('% of total range traveled');
xlabel('travel time [s]');
xlim([0.5 6.5])


subplot(1,2,2);
violinplot(delta_th_Z.',ttSpace,...
            'ViolinColor',myPurple,'ViolinAlpha',.2,'EdgeColor',[0.6 0.6 0.6],'BoxColor',[0.3 0.3 0.3],'MedianColor',[0 0 0],'Width',0.4);
grid on
view([90 90])
ylabel('% compared to max water depth');
xlim([0.5 6.5])

sgtitle(sprintf('Relative error caused by the artifact, visualized by travel time [zs=%u m]',zs),'fontsize',18,'fontweight','bold');

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

