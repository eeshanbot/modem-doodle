%% prep workspace
clear; clc; close all;

%% unpack Bellhop gvel table
[DATA,INDEX] = h_unpack_bellhop('../bellhop-gvel-gridded/gveltable.csv');

%% load simulation
listing = dir('../bellhop-gvel-gridded/csv_arr/*gridded.csv');
[T,colorSet] = h_get_nbc(listing,DATA,INDEX);

%% plot
figure('name','rangeanomaly-by-owtt','renderer','painters','position',[108 108 1300 800]);
t = tiledlayout(2,3,'TileSpacing','none','Padding','compact');

count = 0;
for zr = [30 90]
    index2 = DATA.recDepth == zr;
    
    for zs = [20 30 90]
        index1 = DATA.sourceDepth == zs;
        
        count = count + 1;
        nexttile;
        
        index = logical(index1.*index2.*INDEX.valid);
        
        if sum(index)>=1
            % plot
            hold on
            plot([0 4],[0 0],'--','linewidth',3,'color',[0 0 0 0.6],'handlevisibility','off');

            for s = [5 3 4]
                xval = DATA.owtt(index);
                yval = T{s}.gvel(index) .* DATA.owtt(index) - DATA.recRange(index);
                                
                % remove nans
                xval = xval(~isnan(yval));
                yval = yval(~isnan(yval));
                
                % sort
                [xval,shuffle] = sort(xval);
                yval = yval(shuffle);
                
                % make boundary
                b = boundary(xval,yval);
                p = patch(xval(b),yval(b),colorSet{s});
                p.FaceAlpha = .2;
                p.EdgeColor = colorSet{s};
                p.LineWidth = 3;
                
                
            end
            hold off
        end
        set(gca,'fontsize',13)
        
        % for all grids
        if count <= 3
            title(sprintf('source depth = %u m',zs),'fontsize',14,'fontweight','bold');
        end
        text(2.25,22.8,sprintf('receiver depth = %u m',zr),'HorizontalAlignment','right','VerticalAlignment','bottom','fontsize',12,'fontweight','bold');
        
        if sum(index)>1
            text(2.25,22.8,sprintf('n = %u events',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
        else
            text(2.25,22.8,sprintf('n = %u event',sum(index)),'HorizontalAlignment','right','VerticalAlignment','top','fontsize',11);
        end
        grid on
        
        xlim([0.9 2.26])
        ylim([-16 26]);
        yticks(-20:5:25);
        xticks(1:0.2:2.2);
        
        if mod(count,3)~=1
            yticklabels([])
        else
            ylabel('range error [m]');
        end
        
        if count >=4
            xlabel('one way travel time [s]');
        else
            xticklabels([]);
        end
    end
end

% add legend
nexttile(1);
hold on
for s = [3 4 5]
    plot(NaN,NaN,'-','color',colorSet{s});
end
lg = legend('HYCOM','Baseline','Chosen Weights','location','southeast');
title(lg,'Sound Speed Inputs');

% title
sgtitle('Range error by source and receiver depths','fontsize',17,'fontweight','bold')
% h_printThesisPNG('SLIDES-range-error-owtt-newalgorithm')