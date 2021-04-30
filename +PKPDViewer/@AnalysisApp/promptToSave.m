function StatusOk = promptToSave(app)
% promptToSave - Prompt user whether to save changes
% -------------------------------------------------------------------------
% Abstract: This function prompts the user if changes should be saved.
%
% Syntax:
%           StatusOk = promptToSave(app)
%
% Inputs:
%           app - The PKPDViewer.AnalysisApp object
%
% Outputs:
%           StatusOk - Flag to indicate the save status (false if user
%           cancels)
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

% Default output
StatusOk = true;

% Prompt the user
Prompt = sprintf('Save changes to %s?', app.FileName);
Result = questdlg(Prompt,'Save Changes','Yes','No','Cancel','Yes');

% How did the user respond?
switch Result
    case 'Yes'
        UseSaveAs = false;
        StatusOk = app.save(UseSaveAs);
    case 'No'
        %Skip this file
    otherwise
        StatusOk = false;
end

% Exit if the user cancelled anything
if ~StatusOk
    return
end
