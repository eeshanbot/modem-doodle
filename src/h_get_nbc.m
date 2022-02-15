function [T,colorSet] = h_get_nbc(listing,DATA,INDEX)
%h_get_nbc computes the nearest bounce criterion from processed Bellhop files
%   T is indexed by Bellhop SSP environment
%   1 = artifact-baseval
%   2 = artifact-eeof
%   3 = fixed-baseval
%   4 = fixed-eeof
%   5 = hycom

indBad = INDEX.bad;

for k = 1:numel(listing)
    T0 = readtable([listing(k).folder '/' listing(k).name]);
    T0.index = T0.index + 1;
    b = split(listing(k).name,'.');
    tName{k} = b{1};
    
    % assign gvel for each index by closest time comparison
    for j = 1:numel(T0.index)
        delay = DATA.owtt(j);
        tableDelay = table2array(T0(j,2:6));
        [~,here] = min(abs(tableDelay - delay));
        T0.gvel(j) = DATA.recRange(j)./tableDelay(here);
        T0.owtt(j) = tableDelay(here);
        T0.numBounces(j) = here-1;
        if sum(j == indBad) == 1
            T0.gvel(j) = NaN;
        end
    end
    
    T0.rangeAnomaly = DATA.owtt .* T0.gvel - DATA.recRange;

    T{k} = T0;
end


load p_sspColorDetails;
colorSet = {[0 0 0],[0 0 0],colorSet{:}};

end

