function [tval_output] = h_convertTime(tval_input,bool)
%UNTITLED2 convert time from posix to MATLAB datenum
%   Detailed explanation goes here

if bool
    tval_output = datestr(datetime(tval_input,'ConvertFrom','PosixTime'));
else
    tval_output = datenum(datetime(tval_input,'ConvertFrom','PosixTime'));
end

end

