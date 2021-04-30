function out = cellstr2dlmstr(in,delimiter)
% cellstr2dlmstr - Convert cell string to delimited list
% -------------------------------------------------------------------------
% Abstract: Converts an input cell array of strings into a delimited string
%
% Syntax:
%           out = cellstr2dlmstr(in,delimiter)
%           out = cellstr2dlmstr(in,delimiter)
%
% Inputs:
%           in - input cellstr array
%           delimiter - delimiter string to separate items
%
% Outputs:
%           out = output string
%
% Examples:
%           >> out = cellstr2dlmstr({'moo','boo','foo'},'; ')
%           out =
%           moo; boo; foo
%
% Notes: none
%

%   Copyright 2011-2017 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 420 $  $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
% ---------------------------------------------------------------------

if nargin < 2
    delimiter = ',';
end

in = cellstr(in);

if ~isempty(in)
    out = [sprintf(['%s' delimiter], in{1:end-1}), sprintf('%s', in{end})];
else
    out = '';
end
