%% helper function : get_nested_val();
% get a nested value as an array over all structs
function [array] = h_get_nested_val_filter(obj,lvl1,lvl2,filter)
stuff = [obj.(lvl1)];

temp = stuff(1).(lvl2);

% for doubles
if isa(temp,'double')
    array = [stuff.(lvl2)];
    if exist('filter','var')
        array = array(filter);
    end
% for character arrays
elseif isa(temp,'char')
    array = {stuff.(lvl2)};
    if exist('filter','var')
        array = array{filter};
    end
end

end