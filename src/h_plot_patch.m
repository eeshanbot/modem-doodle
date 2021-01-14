function [] = h_plot_patch(eof_bool, eof_time)
%h_plot_patch plots light gray patch on plots according to boolean status
%and time

% get ybounds
ybounds = ylim();

% figure out how many patches we neek
kindex = find(diff(eof_bool)~=0);

bool_open = eof_bool(1);
bool_close = eof_bool(end);

if bool_open
    kindex = [1 kindex];
end

if bool_close
    kindex = [kindex numel(eof_time)];
end

% loop through patches -- eeof ON
for k = 1:numel(kindex)/2
    
    patchTime = [eof_time(kindex(2*k-1)) eof_time(kindex(2*k))];
    
    buffer = 4;
    
    patchTime = [patchTime(1) patchTime patchTime(end)];
    patchVal = ybounds(2).*ones(size(patchTime));
    patchVal(1) = ybounds(1)-1;
    patchVal(end) = ybounds(1)-1;
    p = patch(patchTime,patchVal,'w','handlevisibility','off');
    p.FaceColor = [0.7 0.7 0.7];
    p.EdgeColor = 'none';
    p.FaceAlpha = .137;
    
    text(patchTime(1),max(patchVal),' eeof',...
        'HorizontalAlignment','left','fontsize',13,'fontangle','italic','VerticalAlignment','top')
end

% loop through blanks -- eeof OFF
for k = 1:numel(kindex)/2 - 1
    patchTime = [eof_time(kindex(2*k):kindex(2*k+1))];
    
    text(patchTime(1),max(patchVal),' baseval',...
        'HorizontalAlignment','left','fontsize',13,'fontangle','italic','VerticalAlignment','top')
end


set(gca,'children',flipud(get(gca,'children')))

end