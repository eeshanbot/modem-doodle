%% helper function : get_nested_val();
% get a nested value as an array over all structs
function [array] = h_get_nested_val_filter(obj,lvl1,lvl2,filter)
stuff = [obj.(lvl1)];
array = [stuff.(lvl2)];

if exist('filter','var')
    array = array(filter);
end

end