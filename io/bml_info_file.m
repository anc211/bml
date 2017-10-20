function info = bml_info_file(cfg)

% BML_INFO_FILE returns a table with the information of each file in a
% folder
%
% Use as
%   tab = bml_info_file(cfg);
%
% The first argument cfg is a configuration structure, which can contain
% the following field:
% cfg.path - string: path to the folder containing the files. Defauts to '.'
% cfg.pattern - string: file name pattern (eg '*.mat')
% cfg.regexp - string: regular expression to filter files
% cfg.filetype - string: variable added to info table
%
% Returns a matlab 'table' with the folloing variables:
%   name - cell array of char: filename
%   folder - cell array of char: path
%   date - cell array of char: data of file modification 
%   bytes - double: Size of the file in bytes
%   isdir - logical: 1 if name is a folder; 0 if name is a file
%   datenum - double: Modification date as serial date number.

% 2017.10.19 AB

path        = ft_getopt(cfg,'path','.');
filepattern = ft_getopt(cfg,'pattern','*');
fileregexp  = ft_getopt(cfg,'regexp',[]);

filetype    = regexp(filepattern,'.*\.(.*)$','tokens','once');
if isempty(filetype); filetype = 'unknown'; end
filetype    = ft_getopt(cfg,'filetype',filetype);

files=dir(fullfile(path, filepattern));
if ~isempty(fileregexp)
  rx=regexp({files.name},fileregexp,'once');
  files=files(~cellfun(@isempty,rx));
end

if isempty(files)
  info=table();
else
  info=struct2table(files);
  info.filetype = repmat(string(filetype),height(info),1);
end
