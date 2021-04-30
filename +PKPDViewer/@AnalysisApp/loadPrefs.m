function loadPrefs(app)
% loadPrefs - Load the preferences
% -------------------------------------------------------------------------
% Abstract: This function loads the app's preferences
%
% Syntax:
%           loadPrefs(app)
%
% Inputs:
%           app - The PKPDViewer.AnalysisApp object
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

% Load each preference into the app
app.DataPath = getpref('PKPDViewer_AnalysisApp','DataPath',app.DataPath);
app.LastPath = getpref('PKPDViewer_AnalysisApp','LastPath',app.LastPath);
app.Position = getpref('PKPDViewer_AnalysisApp','Position',app.Position);
app.RecentFiles = getpref('PKPDViewer_AnalysisApp',...
    'RecentFiles',app.RecentFiles);

% Validate each recent file, and remove any invalid files
idxOk = cellfun(@(x)exist(x,'file'),app.RecentFiles);
app.RecentFiles(~idxOk) = [];

% Ensure it's on the screen, in case display settings changed
movegui(app.Figure,'onscreen')