function [tval_output] = h_convertTime(tval_input)
%UNTITLED2 convert time from posix to MATLAB datenum
%   Detailed explanation goes here
tval_output = datenum(datetime(tval_input,'ConvertFrom','PosixTime'));
end

