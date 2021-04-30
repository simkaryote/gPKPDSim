function savePrefs(app)
% savePrefs - Updates the preferences
% -------------------------------------------------------------------------
% Abstract: This function updates the app's preferences
%
% Syntax:
%           savePrefs(app)
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

setpref('PKPDViewer_AnalysisApp','DataPath',app.DataPath)
setpref('PKPDViewer_AnalysisApp','LastPath',app.LastPath)
setpref('PKPDViewer_AnalysisApp','Position',app.Position)
setpref('PKPDViewer_AnalysisApp','RecentFiles',app.RecentFiles)
