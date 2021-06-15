%% main_plot_raytrace_v2.m
% plots raytraces by each source depth for the three ssps

%% prep workspace
clear; clc; close all;

lg_font_size = 14;

myGray = [0.6 0.6 0.6];
alphaColor   = .2;

% depth_switch = [20 30 90];
zs = 90;

%% load modem marker info
load p_modemMarkerDetails

%% load all events
load('./data-prep/tobytest-recap-full.mat'); % loads "event
A = h_unpack_experiment(event);
DATA = readtable('./bellhop-gvel-gridded/gveltable.csv');
%DATA.simGvel(isnan(DATA.simGvel)) = 0;

% remove crazy 11 second event, event that is nominally 1.58* seconds
indBad1 = find(DATA.owtt > 3);
indBad2 = find(strcmp(DATA.rxNode,'East') & DATA.owtt > 1.55);
indBad = union(indBad1,indBad2);

% 1.587 events, had clock errors + Bellhop can't resolve these
DATA.simGvel(indBad) = NaN;
% only simGvel

load bellhop-eigenrays-3ssp/eigentable_flat.mat
load bellhop-eigenrays-3ssp/eig_reruns_jun21.mat
arCell = struct2cell(all_rays);

%% load all sound speeds
path = './bellhop-gvel-gridded/';

file{1} = 'ssp-hycom.csv';
file{2} = 'ssp-fixed-baseval.csv';
file{3} = 'ssp-fixed-eeof.csv';

fileNames = {'HYCOM','Baseline','Chosen Weights'};
colorSet = {[152 134 117]./256,[232, 153, 35]./256,[0 85 135]./256};

for k = 1:3
    T = readtable([path file{k}]);
    ssp(k).depth = T.Var1;
    ssp(k).ssp   = T.Var2;
    ssp(k).name = fileNames{k};
    ssp(k).color = colorSet{k};
    temp = split(file{k},'.');
    ssp(k).filestr = temp{1};
end

%% make plot

figure('name','raytrace-all','renderer','painters','position',[108 108 1300 1050]);
t = tiledlayout(3,9,'TileSpacing','compact');

theta = [-49:2:-31 -30:1:30 31:2:49];
numstep = 1100;
sstep = 5;

for k = 1:3
    
    tic;
    
    %% sound speed plot
    nexttile([1 2]);
    
    plot(ssp(k).ssp,ssp(k).depth,'linewidth',3,'color',myGray);
    set(gca,'ydir','reverse');
    grid on
    ylim([0 300]);
    xlim([1431 1463]);
    set(gca,'fontsize',12)
    ylabel('depth [m]');
    title(sprintf('SSP from %s',ssp(k).name));
    
    if k == 3
        xlabel('c [m/s]');
    end
    
    %% raytrace plot
    nexttile([1 7]);
    [R,Z,~] = eb_raytrace(zs,theta,numstep,sstep,ssp(k).depth,ssp(k).ssp,0,max(ssp(k).depth));
    
    plot(R.'/1000,Z.','color',[myGray alphaColor],'linewidth',2);
    set(gca,'ydir','reverse');
    ylim([0 300]);
    set(gca,'fontsize',12);
    yticklabels([]);
    
    if zs == 20
        xlim([0 2]);
    else
        xlim([0 3.5]);
    end
    
    title(sprintf('Source depth = %u m',zs));
    
    if k == 3
        xlabel('range [km]');
    end
    
    hold on
    
%     % add eigenrays -- old
%     num_eigentable = numel(eigentable);
%     for ne = 1:num_eigentable
%         
%         if strcmp(eigentable{ne}.env,ssp(k).filestr)
%             tx_z = double(eigentable{ne}.tx_z);
%             
%             if tx_z == zs
%                 
%                 % rerun ray based on BELLHOP angle + owtt -- this is
%                 % somehow more accurate... not sure why.
%                 theta0 = double(eigentable{ne}.arrival.SrcDeclAngle);
%                 t0 = double(eigentable{ne}.arrival.delay);
%                 [r,z,t] = eb_raytrace(zs,-theta0,numstep,sstep,ssp(k).depth,ssp(k).ssp,0,max(ssp(k).depth));
%                 indStop = find(t>=t0,1,'first');
%                 plot(r(1:indStop)./1000,z(1:indStop),...
%                     'color',[markerModemMap(eigentable{ne}.rx_node) 0.5],'linewidth',2,'handlevisibility','off')
%                 
%                 % plot BELLHOP eigenray
%                 %plot(eigentable{ne}.ray.r./1000,eigentable{ne}.ray.z,...
%                 %'color',[markerModemMap(eigentable{ne}.rx_node) 0.5],'linewidth',2,'handlevisibility','off')
%             end
%         end
%     end

    % add eigenrays -- new
    num_eigentable = numel(eigentable);
    for ne = 1:num_eigentable
        
        % check file source
        if strcmp(eigentable{ne}.env,ssp(k).filestr)
            tx_z = double(eigentable{ne}.tx_z);
            
            % check source depth
            if tx_z == zs
                
                % source new eigenrays from "all_rays"
                hits = arCell{ne};
                for h = 1:numel(hits)
                    theta0(h) = double(hits{h}.alpha0);
                end
                
                % get clustered "travel time" from data & other useful info
                t0 = double(eigentable{ne}.arrival.delay);
                r0 = double(eigentable{ne}.case_rx_r);
                z0 = double(eigentable{ne}.rx_z);
                
                % run ray trace for time front & find distance away 
                numstep0 = round(1.5 .* r0 ./ sstep);
                [r,z,t] = eb_raytrace(zs,-theta0,numstep0,sstep,ssp(k).depth,ssp(k).ssp,0,max(ssp(k).depth));
                [Ri,Zi] = h_interpolate_by_owtt(t0,r,z,t);
                p = sqrt((Ri-r0).^2 + (Zi-z0).^2);
                [~,pInd] = min(p);
                
                tInd = find(t(pInd,:)>=t0,1,'first');
                plotR = r(pInd,1:tInd);
                plotZ = z(pInd,1:tInd);
                plot(plotR./1000,plotZ,...
                     'color',[markerModemMap(eigentable{ne}.rx_node) 0.5],'linewidth',2,'handlevisibility','off')

            end
        end
    end
    
    % add source
    scatter(0,zs,markerSize,'k','s','linewidth',2);
    
    % add modem shapes
    for node = A.unique_rx
        node = node{1}; % change from cell to char
        
        for imd = modem_rx_depth
            index = find(strcmp(DATA.rxNode,node) & DATA.recDepth == imd & DATA.sourceDepth == zs);
            
            if ~isempty(index)
                scatter(DATA.recRange(index)./1000,DATA.recDepth(index),...
                    markerSize-25,markerModemMap(node),markerShape(imd),'filled');
            end
        end
    end
    
    hold off
    toc;
end

h_printThesisPNG(sprintf('raytrace-3env-zs-%u',zs));

%% helper function : h_interpolate_by_owtt
function [Ri,Zi] = h_interpolate_by_owtt(ttSpread,R,Z,T)

% number of thetas to aggregrate over
numTheta = size(R,1);
for n = 1:numTheta
    
    interp_range = interp1(T(n,:),R(n,:),ttSpread);
    interp_depth = interp1(T(n,:),Z(n,:),ttSpread);
    
    % matrix to store eigenrays -- [theta x ttSpread]
    Ri(n,:) = interp_range;
    Zi(n,:) = interp_depth;
end
end

