function [DATA,INDEX] = h_unpack_bellhop(filepath)
%h_unpack_bellhop loads & filters BELLHOP runs

% load data
DATA = readtable(filepath);
% only simGvel
DATA.gvel = DATA.recRange ./ DATA.owtt;

DATA.simGvel(isnan(DATA.simGvel)) = 0;

% remove crazy 11 second event, event that is nominally 1.58* seconds
indBad1 = find(DATA.owtt > 4);
indBad2 = find(strcmp(DATA.rxNode,'East') & DATA.owtt > 1.55);
indBad3 = find(strcmp(DATA.rxNode,'Camp'));
indBad = union(indBad1,indBad2);
indBad = union(indBad,indBad3);

% 1.587 events, had clock errors
DATA.simGvel(indBad) = NaN;
% only simGvel

indValid = ~isnan(DATA.simGvel);

INDEX.valid = indValid;
INDEX.bad   = indBad;

% calculate RangeAnomaly
DATA.rangeAnomaly = DATA.owtt .* DATA.simGvel - DATA.recRange;
end

