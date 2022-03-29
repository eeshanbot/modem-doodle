function [A] = h_clean_simgvel(A)
% h_clean_simgvel
% inputs and outputs A from h_unpack_experiment 
% emulates the filters from the ICNN outlier rejection

% remove crazy 11 second event, event that is nominally 1.58* seconds
indBad1 = A.data_owtt > 3;
indBad2 = strcmp(A.tag_rx,'East') & A.data_owtt > 1.55;
indBad = indBad1 | indBad2;

% 1.587 events, had clock errors
A.sim_gvel(indBad) = NaN;
end

