function StatusOk = open(app,FilePath)
% open - Opens the app session data from a selected file
% -------------------------------------------------------------------------
% Abstract: This function opens app session data from a selected file
%
% Syntax:
%           StatusOk = open(app,UseOpenAs)
%
% Inputs:
%           app - The PKPDViewer.AnalysisApp object
%           FilePath - Optional FilePath (used for open recent)
%
% Outputs:
%           StatusOk - Flag to indicate the open status (false if user
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

% If no file was specified, then we need to prompt the user
if nargin<2
    
    % Prompt the user for a filename
    Spec = {'*.mat'};
    Title = 'Open File';
    StartPath = app.LastPath;
    [FileName,PathName] = uigetfile(Spec,Title,StartPath);
    FilePath = fullfile(PathName,FileName);
    
    % Verify the user didn't cancel
    if isequal(FileName,0)
        StatusOk = false;
    else
        % Update the last path
        app.LastPath = PathName;
    end
    
else
    % Pull out the file name for later
    [~,FileName] = fileparts(FilePath);
end

% Validate the file exists and isn't already open. Otherwise prompt the user
if StatusOk
    [~,~,FileExt] = fileparts(FilePath);
    if ~exist(FilePath,'file') || ~strcmpi(FileExt,'.mat')
        Title = 'Open File';
        Message = sprintf('The specified file does not exist or is not a valid MAT file: \n%s',FilePath);
        hDlg = errordlg(Message,Title,'modal');
        uiwait(hDlg);
        StatusOk = false;
    end
end

% Open the data from MAT format
if StatusOk
    
    % Load the data
    s = load(FilePath,'Analysis');
    
    % Validate the file
    try
    Analysis = s.Analysis;
        validateattributes(Analysis,{'PKPD.Analysis'},{'scalar'})
    catch err
        Message = sprintf(['The file %s did not contain a valid '...
            'Analysis object:\n%s'], FileName, err.message);
        Title = 'Open File';
        hDlg = errordlg(Message,Title,'modal');
        uiwait(hDlg);
        StatusOk = false;
    end
    
end

% Add the analysis to the app
if StatusOk
    
    % Populate the data into the app
    app.Analysis = Analysis;
    app.FilePath = FilePath;
    app.IsDirty = false;
    
    % Add this to the list of recent files
    addRecentFile(app,FilePath);
    
end

