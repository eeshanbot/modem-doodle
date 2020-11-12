function [rt,zt,tl] = model_parabolicEquation(ssp,z)
% ******************************************************
% PE
% ******************************************************
bool_plot = false;

zs  = 33;			% source depth
f   = 3500/8; omega = 2 * pi * f;	% frequency in Hertz

d   = max(z);			% bottom depth
nz  = numel(z);	% number of finite-difference points
h   = d / nz; h2  = h * h;	% mesh spacing
z   = linspace( 0, d, nz );	% grid coordinates

c = ssp;

% c0 = 1500;
%x = 2 * ( z - 1300 ) / 1300;
%c = c0 * ( 1 + eps * ( x - 1 + exp( -x ) ) );

if bool_plot
    figure(1)
    subplot(1,5,1)
    plot( z, c ); view( 90, 90 );
    xlabel( 'Depth (m)' ); ylabel( 'Sound Speed (m/s)' )
    xlim([0 1000]);
    grid on
end

% ******************************************************
% Gaussian starter
% ******************************************************

% \psi(0,z) = \sqrt{ k_0 } \,
% e^{ -{ k_0^2 \over 2 } ( z - z_s )^2 } (6.100)

c0 = min(ssp);
k0 = omega / c0;
isd = zs / d * nz;

nr     = 1001;
rmax   = 10000.0;
deltar = rmax / nr;
r = linspace( 0.0, rmax, nr );

psi = zeros( nz, nr );

% we have broadened the Gaussian to make it more
% narrow angle
% the usual formula has fac = 1
fac = 10;
psi( : , 1 ) = sqrt( k0 / fac ) * ...
    exp( -( k0 / fac )^2 * ...
    ( (z - zs * ones( 1, nz ) ) ).^2 )' ;

% ******************************************************
% Form marching matrix
% ******************************************************
% SPE: 2ik_0 { \pa \psi \over {\pa r} }
%          + { \pa^2 \psi \over {\pa z^2} }
%          + k_0^2 ( n^2 - 1 ) \psi = 0  (6.8)

c0     = 1500;
n      = c0 ./ c;

E  = sparse( 2:nz, 1:nz-1,      ones(1,nz-1) / h2,             nz, nz, nz-1 );  % sub diagonal
D1 = sparse( 1:nz, 1:nz  , -2 * ones(1,nz  ) / h2,             nz, nz, nz   );  %     diagonal
D2 = sparse( 1:nz, 1:nz  ,    k0^2 * (n.^2 - ones( 1, nz ) ),  nz, nz, nz   );

A = D1 + D2 + E + E';
B = 2 * 1i * k0 /deltar * speye( size( A ) ) - A / 2;
C = 2 * 1i * k0 /deltar * speye( size( A ) ) + A / 2;

% ******************************************************
% March out in range
% ******************************************************

% --- factor C

[L, U] = lu( C );

for ir = 1:nr-1
    ir;
    % equivalent to C psi( :, ir+1 ) = B * psi( :, ir );
    y1 = B * psi( :, ir );
    y = L \ y1;
    psi( :, ir+1 ) = U \ y;
end

% ******************************************************
% PE
% ******************************************************

% --- plot field

takez = 1:nz;
taker = 2:nr;

zt = z( takez );
rt = r( taker );
psit = psi( takez, taker );

% put back Hankel function
hank = sqrt( 2 / ( pi * k0 ) ) * exp( 1i * ( k0 * rt - pi / 4 ) ) ...
    * diag( 1.0 ./ sqrt( rt ) );

tl = 20 * log10( abs( psit * diag( hank ) ) ) ;

if bool_plot
    subplot(1,5,2:5)
    pcolor( rt, zt, tl ); ...
        % caxis( [ -70 -40 ] ); ...
    cmocean thermal
    shading flat; colorbar; view( 0, -90 );
    xlabel( 'Range (m)' ); ylabel( 'Depth (m)' );
    yticklabels([]);
    title('PE intensity')
    ylim([0 1000])
end

end

