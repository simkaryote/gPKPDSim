function addRecentFile(app,FilePath)
% addRecentFile - Adds a recent file to the list
% -------------------------------------------------------------------------
% Abstract: This function adds a recent file to the list
%
% Syntax:
%           addRecentFile(app,FilePath)
%
% Inputs:
%           app - The PKPDViewer.AnalysisApp object
%           FilePath - The path for the file to add
%
% Outputs:
%           none
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2017 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 420 $  $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
% ---------------------------------------------------------------------

% If this file is already in the list, remove it so we can put it on bottom.
idxRemove = strcmp(FilePath,app.RecentFiles);
app.RecentFiles(idxRemove) = [];

% Add the file to the top of the list
app.RecentFiles = vertcat(app.RecentFiles,FilePath);

% Crop the list to 10 entries
app.RecentFiles(1:end-10) = [];
