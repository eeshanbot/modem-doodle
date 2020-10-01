function info = itp_import_loc(filename, startRow, endRow)
%IMPORTFILE Import numeric data from a text file as a matrix.
%   ITP103GRD0000 = IMPORTFILE(FILENAME) Reads data from text file FILENAME
%   for the default selection.
%
%   ITP103GRD0000 = IMPORTFILE(FILENAME, STARTROW, ENDROW) Reads data from
%   rows STARTROW through ENDROW of text file FILENAME.
%
% Example:
%   itp103grd0000 = importfile('itp103grd0000.dat', 2, 2);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2019/11/14 16:25:09

%% Initialize variables.
if nargin<=2
    startRow = 2;
    endRow = 2;
end

%% Format for each line of text:
%   column1: double (%f)
%	column2: double (%f)
%   column3: double (%f)
%	column4: double (%f)
%   column5: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%4f%11f%5f%10f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Create output variable

%% defaults

info.lon = 9999;
info.lat = 9999;
info.year = 9999;
info.day = 9999;

dataArray = cellfun(@(x) num2cell(x), dataArray, 'UniformOutput', false);

info.year = cell2mat(dataArray{1});
info.day = cell2mat(dataArray{2});
lon = [string(dataArray{3}) '.' string(dataArray{4})];
lon = [lon{:}];
info.lon = str2num(lon);
info.lat = cell2mat(dataArray{5});
%info.num_depths = dataArray{6};


end

