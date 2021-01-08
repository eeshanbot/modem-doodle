%% helper function : set_xy_bounds(x1,x2);
function [] = h_set_xy_bounds(x1,x2,y1,y2)
% h_set_xy_bounds --- sets xlim and ylim based on inputs

% remove NaNs, if any
x1 = x1(~isnan(x1));
x2 = x2(~isnan(x2));
y1 = y1(~isnan(y1));
y2 = y2(~isnan(y2));


% standard deviation
x_std = std([x1(:); x2(:)]);
y_std = std([y1(:); y2(:)]);

% min/max for x
min_xval = min([min(x1(:)) min(x2(:))])-x_std/5;
max_xval = max([max(x1(:)) max(x2(:))])+x_std/5;

% min/max for y
min_yval = min([min(y1(:)) min(y2(:))])-y_std/5;
max_yval = max([max(y1(:)) max(y2(:))])+y_std/5;

% set xlim
xlim([min_xval max_xval]);
ylim([min_yval max_yval]);
end
