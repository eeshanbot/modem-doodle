function [T] = h_get_mbc(listing,DATA)
%h_get_mbc computes the minimal bounce criterion from processed Bellhop files
%   T is indexed by Bellhop SSP environment
%   1 = artifact-baseval
%   2 = artifact-eeof
%   3 = fixed-baseval
%   4 = fixed-eeof
%   5 = hycom

for f = 1:numel(listing)
    T0 = readtable([listing(f).folder '/' listing(f).name]);
    T0.index = T0.index + 1;
    b = split(listing(f).name,'.');
    tName{f} = b{1};
    
    % assign gvel by minimum bounce
    for k = 1:numel(T0.index)
        T0.gvel(k) = DATA.recRange(k)./T0.owtt(k);
    end
    
    T0.rangeAnomaly = DATA.owtt .* T0.gvel - DATA.recRange;
    T{f} = T0;
end

end

