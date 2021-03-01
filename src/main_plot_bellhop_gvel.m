%% main_plot_bellhop_gvel

%% prep workspace
clear; clc; close all;

% load data
A1 = readtable('./bellhop-gvel-gridded/gveltable.csv');

% load simulation
listing = dir('./bellhop-gvel-gridded/csv_arr/*.csv');

keepInd = [A1.owtt] < 4;

A.sourceDepth = A1.sourceDepth(keepInd);
A.recDepth    = A1.recDepth(keepInd);
A.recRange    = A1.recRange(keepInd);
A.simGvel     = A1.simGvel(keepInd);
A.txNode      = A1.txNode(keepInd);
A.rxNode      = A1.rxNode(keepInd);
A.owtt        = A1.owtt(keepInd);


for k = 1:numel(listing)
    T0 = readtable([listing(k).folder '/' listing(k).name]);
    T0.index = T0.index + 1;
    T0.gvel = A1.recRange ./ T0.owtt;
    b = split(listing(k).name,'.');
    tName{k} = b{1};
    
    T{k}.index = T0.index(keepInd);
    T{k}.must_bnc = T0.must_bnc(keepInd);
    T{k}.n_bnc = T0.n_bnc(keepInd);
    T{k}.owtt = T0.owtt(keepInd);
    T{k}.must_bnc0 = T0.must_bnc0(keepInd);
    T{k}.n_bnc0 = T0.n_bnc0(keepInd);
    T{k}.owtt0 = T0.owtt0(keepInd);
    T{k}.gvel = T0.gvel(keepInd);
    
    if sum(T{k}.gvel < 1000) > 1
        ind = find(T{k}.gvel < 1000);
        T{k}.gvel(ind) = NaN;
    end

end

% 1 = artifact-baseval
% 2 = artifact-eeof
% 3 = fixed-baseval
% 4 = fixed-eeof
% 5 = hycom

% load modem marker information
load p_modemMarkerDetails

% depth switch % [90] or [20 30];
zs= [20 30];

%% plot all data

figure('name','gvel-by-owtt','renderer','painters','position',[108 108 1250 550]);

indexSrcDepth = A.sourceDepth == zs;
if numel(zs) == 2
    indexSrcDepth = sum(indexSrcDepth,2);
end

lineStyleSet = {'','','-',':','-'};
colorSet = {[0 0 0],[0 0 0],[51, 152, 152]./256,[51, 152, 152]./256,[152 134 117]./256};

for s = [3 4 5]
    
    for r = [20 30 90]
        if r == 20
            count = 0;
            pxval = []; pyval = [];
        elseif r == 90
            count = 0;
            pxval = []; pyval = [];
        end
        indexRecDepth = A.recDepth == r;
        
        for ml = modem_labels
            m = ml{1};
            
            indexModem = strcmp(A.rxNode,m);
            
            index = boolean(indexModem .* indexRecDepth .* indexSrcDepth);
            p = find(index == 1);
            
            gvel = A.recRange(index) ./ A.owtt(index);
            
            hold on
            for i = 1:numel(p)
                xval = A.owtt(p(i));
                yval = T{s}.gvel(p(i));
                scatter(xval,yval,...
                    150,markerModemMap(m),markerShape(A.recDepth(p(i))),...
                    'filled','MarkerFaceAlpha',0.4,'handlevisibility','off');
                
                count = count + 1;
                pxval(count) = xval;
                pyval(count) = yval;
            end
        end
        
        if r == 30
            hold on
            [pxval,ind] = sort(pxval);
            plot(pxval,pyval(ind),lineStyleSet{s},'color',[colorSet{s} 0.8],'linewidth',4,'handlevisibility','off');
            hold off
        elseif r == 90
            hold on
            [pxval,ind] = sort(pxval);
            plot(pxval,pyval(ind),lineStyleSet{s},'color',[colorSet{s} 0.8],'linewidth',4);
            hold off
        end
    end
end

%% make pretty
grid on

xlabel('one way travel time [s]');
ylabel('estimated group velocity [m/s]');
ylim([1432 1451]);
xlim([1 2.21]);

if numel(zs) == 2
    lg = legend('Mean of EOF set','Chosen EOF weights','HYCOM','location','northeast','fontsize',14);
    title(lg,'sound speed estimate');
    title('Group velocity estimates given source depths = 20, 30 m');
    h_printThesisPNG(sprintf('gvel-estimate-zs20m30m.png'));
else
    lg = legend('Mean of EOF set','Chosen EOF weights','HYCOM','location','southeast','fontsize',14);
    title(lg,'sound speed estimate');
    title(sprintf('Group velocity estimates given a source depth = %u m',zs));
    h_printThesisPNG(sprintf('gvel-estimate-zs%u.png',zs));
end


