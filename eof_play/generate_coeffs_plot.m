%% generate_coeffs.m
% eeshan bhatt | eesh (at) mit (dot) edu
% LAMSS - Dr. Henrik Schmidt
% Feb 2020

function [chosen_weights,chosen_eofnum,ssp_approx] = generate_coeffs_plot(z,ssp,eof_file);

addpath(genpath('./helper/'));

[z,sort_ind] = sort(z);
ssp = ssp(sort_ind);




%% get new weights based off EOF file on vehicle

filename        = eof_file;
eofs            = ncread(filename,'eofs'); eofs = double(eofs);
baseval         = ncread(filename,'baseval'); baseval = double(baseval);
num_eofs        = ncread(filename,'num_eofs'); num_eofs = double(num_eofs);
num_depth       = ncread(filename,'num_depth'); num_depth = double(num_depth);
depth           = ncread(filename,'depth'); depth = double(depth);
default_weights = ncread(filename,'weights'); default_weights = double(default_weights);

xi              = ncread(filename,'pdf_val'); xi = double(xi);
f               = ncread(filename,'pdf_freq'); f = double(f);

%% interpolate to HYCOM depth
max_cast_depth = max(z);
min_cast_depth = min(z);
ind_cast_depth = find(depth > max_cast_depth, 1, 'first');
Cq = interp1(z,ssp,depth(1:ind_cast_depth),'linear','extrap');

Z = depth(1:ind_cast_depth);
Cqq = [Cq; baseval(numel(Cq)+1:end)];
count = 0;

%% get estimate for R,Z (OPTIONAL)
request_r = 0;
request_z = 0;

%% loop through combinations
fprintf('\nrunning ray trace simulation... \n');
for ne = 2:num_eofs
    
    combos = nchoosek(1:num_eofs,ne);
    [num_combos,~] = size(combos);
    
    for cmb = 1:num_combos
        count = count + 1;
        
        eof_subset = combos(cmb,:);
        
        % find weights for valid depths
        ind_cast_depth = numel(Cq);
        new_weights = eofs(1:ind_cast_depth,eof_subset) \ (Cq - baseval(1:ind_cast_depth));
        new_weights = round(new_weights,3);
        ssp_approx = baseval + eofs(:,eof_subset)*new_weights;
        
        % sum of squares compared CTD
        eof_error(count) = calc_error(Cqq, ssp_approx);
        
        % timefront shift compared to "CTD"
        if request_r + request_z > 0
            timevals = 12;
        else
            timevals = [0.6 1.2 2 3];
        end
        
        % run ray tracer
        [ray_rz_error(count),~,~] = run_rt(Cqq,ssp_approx,depth,timevals,request_r,request_z);
        
        % keep track of the combination of EOFs and corresponding weights
        eof_combo{count} = combos(cmb,:);
        eof_coeff{count} = new_weights;
        eof_ssp{count} = ssp_approx;
    end
end

% create a rank by minimizing eof error and minimizing ray shift
eof_rank = -zscore(eof_error) -zscore(ray_rz_error);

[~,eof_rank_sorted_index] = sort(eof_rank,'descend');
ERSI = eof_rank_sorted_index;

%% print best options?

% % debug figure
% figure(99)
% plot(1:count,eof_rank)
% grid on
% ylabel('eof score')
% xlabel('eof weight combo')

%num_print = input(['how many weight combinations do you want to see (suggested 10% = ' num2str(round(.10*count)) ')? ']);
num_print = 5;

fprintf('\nprinting best combinations of EOFs... \n');
fprintf('\nthe more uncertain you are about vehicle position, the more you should trust env_error ONLY \n');

rank = 1:num_print;
for rr = rank
    env_error(rr) = eof_error(ERSI(rr));
    env_combo = eof_combo{ERSI(rr)};
    eof_use{rr} = num2str(env_combo);
    env_coeff(rr,env_combo+1) = eof_coeff{ERSI(rr)};
    ray_shift(rr) = ray_rz_error(ERSI(rr));
end

eof_use = eof_use.';
rank = rank.';
env_error = env_error.';
ray_shift = ray_shift.';

%% table
T2 = table(rank,env_error,ray_shift,eof_use);
disp(T2);

%% visualize sound speeds
fprintf('\nNow we will visually examine the resultant sound speed recreations. \n');

examine = -1;
% examine = input('please enter -1 to skip, 0 to see all at once, or a number to see that specific one: ');

while examine >= 0
    figure(1); clf;
    
    if examine == 0
        
        cc = copper(num_print);
        
        % sound speed info
        subplot(1,7,1:4)
        plot(Cq,Z,'r--');
        hold on
        plot(baseval,depth,'b');
        str = {'CTD','baseval'};
        for pr = 1:num_print
            ssp_approx = baseval + eofs(:,eof_combo{ERSI(pr)})*eof_coeff{ERSI(pr)};
            plot(ssp_approx,depth,'o','color',cc(pr,:));
            str{pr+2} = ['rank: ' num2str(pr) ', combo: ' num2str(eof_combo{ERSI(pr)})];
        end
        hold off
        set(gca,'ydir','reverse');
        ylabel('depth [m]');
        xlabel('sound speed [m/s]');
        grid on
        ylim([0 2*request_depth]);
        title('all ranks')
        
        legend(str,'location','best');
        
        % depth dependent error
        subplot(1,7,5:7);
        hold on
        for pr = 1:num_print
            ssp_approx = baseval + eofs(:,eof_combo{ERSI(pr)})*eof_coeff{ERSI(pr)};
            plot(ssp_approx - Cqq, depth, '-o','color',cc(pr,:))
        end
        hold off
        set(gca,'ydir','reverse');
        xlabel('error [m/s]');
        grid on
        ylim([0 2*request_depth]);
        
        examine = -1;
        
    elseif examine > num_print
        warning(['too high, try again <= ' num2str(num_print)]);
        examine = input('please enter -1 to skip, 0 to see all at once, or a number to see that specific one: ');
    else
        
        % sound speed info
        subplot(1,7,1:4)
        plot(Cq,Z,'r--');
        hold on
        plot(baseval,depth,'b');
        str = {'CTD','baseval'};
        ssp_approx = baseval + eofs(:,eof_combo{ERSI(examine)})*eof_coeff{ERSI(examine)};
        plot(ssp_approx,depth,'ko-')
        str{3} = ['rank: ' num2str(examine) ', combo: ' num2str(eof_combo{ERSI(examine)})];
        title(['rank ' num2str(examine)]);
        
        hold off
        set(gca,'ydir','reverse');
        ylabel('depth [m]');
        xlabel('sound speed [m/s]');
        grid on
        ylim([0 2*request_depth]);
        
        legend(str,'location','best');
        
        % depth dependent error
        subplot(1,7,5:7);
        plot(ssp_approx - Cqq, depth, 'ko-')
        set(gca,'ydir','reverse');
        xlabel('error [m/s]');
        grid on
        ylim([0 2*request_depth]);
        
        % re-examine
        examine = input('please enter -1 to skip, 0 to see all at once, or a number to see that specific one: ');
    end
end

%% select ranks for acoustic difference
% [pursue_rank,~] = listdlg('PromptString',{'select all ranks of interest:','try not to pick more than 4',''},...
%     'SelectionMode','multiple',...
%     'Name','Ranks for Acoustic Study',...
%     'ListSize',[300 300],...
%     'ListString',string(1:num_print));

pursue_rank = 1;

%% kde plots

% load weight_distributions.mat
entropy = @(p) -sum(p.*log2(p));
numpoints = 100;

cmb = cbrewer('qual','Dark2',num_eofs);
linestr = {':','-','--'};

%% final decision

%veh_rank  = input('please enter your chosen rank of the EOF-coefficients: ');

veh_rank = 1;

%% print final decision
fprintf('\nfinal chosen weights are... \n')
fprintf('rank = %d \n',veh_rank)

chosen_weights = eof_coeff{ERSI(veh_rank)};
chosen_eofnum = eof_combo{ERSI(veh_rank)};

ssp_approx = baseval + eofs(:,eof_combo{ERSI(veh_rank)})*eof_coeff{ERSI(veh_rank)};


json_str = '{ "eofs" : { ';
new_weights = zeros(num_eofs,1);
for ce = 1:length(chosen_eofnum)
    % find z-score (temporary solution)
    ce_mean = mean(xi(chosen_eofnum(ce),:));
    ce_std  = std(xi(chosen_eofnum(ce),:));
    ce_zscore(ce) = round((chosen_weights(ce)-ce_mean)/ce_std,4);
    
    new_weights(chosen_eofnum(ce)) = chosen_weights(ce);
    
    % fprintf('eof# = %d | weight = %2.3f | zscore = %2.3f \n',chosen_eofnum(ce),chosen_weights(ce),ce_zscore)
end


%% table
eof_num = chosen_eofnum.';
weight_zscore = ce_zscore.';
T1 = table(eof_num,chosen_weights,weight_zscore);
disp(T1);

%% helper function: calculate error
    function [error] = calc_error(y,yhat)
        error = double(sum((y-yhat).^2));
    end

end