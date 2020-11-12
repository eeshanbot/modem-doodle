function [ray_rz_error,R,Z] = run_rt(y_ssp,yhat_ssp,z,travel_time,request_r,request_z,plot_bool)

range_check = false;
% define plot_bool, range_check
if nargin == 4
    plot_bool = false;
elseif nargin == 6
    plot_bool = false;
    if request_r + request_z > 0
        range_check = true;
        travel_time = travel_time(1);
    end
end

% fix grid spacing for raytracer
zspace = 0:max(z);
Yq = interp1(z,y_ssp,zspace);
Yhatq = interp1(z,yhat_ssp,zspace);

yvals = [Yq; Yhatq];

% ray tracing parameters
if range_check
    theta = 0:0.5:90;
else
    theta = 0:2:70;
end

theta(theta==90)=[];
num_theta = length(theta);

z0 = 33;

% empty structures to compare
R = zeros(2,num_theta);
Z = R;

% loop over times
for tt = 1:numel(travel_time)
    tnow = travel_time(tt);
    % loop over two SSPs
    for yv = 1:2
        [rr,zz,~,~] = model_rayTrace(0,z0,theta,tnow,zspace,yvals(yv,:),false);
        
        if range_check
            for dtheta = 1:length(theta)
                indr = find(abs(rr{dtheta} - request_r) > 0.2*request_r);
                indz = find(abs(zz{dtheta} - request_z) > 0.2*request_z);
                ind_rc = union(indr,indz);
                
                % we know rr,zz will hold b/c range_check only runs w/ one
                % time
                if numel(ind_rc) > 0
                    rr{dtheta}(ind_rc) = NaN;
                    zz{dtheta}(ind_rc) = NaN;
                end
                
                R(yv,dtheta) = mean(real(rr{dtheta}),'omitnan');
                Z(yv,dtheta) = mean(real(zz{dtheta}),'omitnan');
            end
        else
            for dtheta = 1:length(theta)
                R(yv,dtheta) = real(rr{dtheta}(end));
                Z(yv,dtheta) = real(zz{dtheta}(end));
            end
        end
    end   
    
% environmental error
range_error(tt,:) = R(2,:) - R(1,:);
depth_error(tt,:) = Z(2,:) - Z(1,:);
end

ray_rz_error = sqrt(range_error.^2 + depth_error.^2);
ray_rz_error = mean(ray_rz_error(:),'omitnan');

%% figure for validation
if plot_bool
    figure()
    scatter(R(1,:),Z(1,:));
    hold on
    scatter(R(2,:),Z(2,:));
    hold off
    grid on
    legend('CTD','EOF','location','best')
    set(gca,'ydir','reverse')
    
    xlabel('range [m]');
    ylabel('depth [m]');
    title(['timefront comparison, t = ' num2str(travel_time) ' s']);
end
end