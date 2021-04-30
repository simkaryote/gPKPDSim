function StatusOk = save(app,UseSaveAs)
% save - Saves the app session data to a file
% -------------------------------------------------------------------------
% Abstract: This function saves app session data to a file
%
% Syntax:
%           StatusOk = save(app,UseSaveAs)
%
% Inputs:
%           app - The PKPDViewer.AnalysisApp object
%           UseSaveAs - Flag whether to Save As or just Save
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

% Check inputs
if nargin<2
    UseSaveAs = false;
end

% Get the save information
Analysis = app.Analysis; %#ok<NASGU> (called by save fcn below)
FilePath = app.FilePath;

% Plot Settings
% Update backend - copy handle
OrigTask = app.Analysis.Task;
app.Analysis.Task = 'Simulation';
updateAxesLayout(app);
app.Analysis.SimulationPlotSettings = getSummary(app.PlotSettings(app.SimulationPlotIdx));
app.Analysis.Task = 'Fitting';
updateAxesLayout(app);
app.Analysis.FittingPlotSettings = getSummary(app.PlotSettings(app.FittingPlotIdx));
app.Analysis.Task = 'Population';
updateAxesLayout(app);
app.Analysis.PopulationPlotSettings = getSummary(app.PlotSettings(app.PopulationPlotIdx));
% Restore
app.Analysis.Task = OrigTask;
updateAxesLayout(app);

% If file hasn't yet bene saved, give a default path and filename
IsNewFile = ~exist(FilePath,'file');
if IsNewFile
    FilePath = fullfile(app.LastPath,'untitled');
end

% Do we need to prompt for a filename?
if UseSaveAs || IsNewFile
    
    % Prompt the user for a filename
    Spec = {'*.mat'};
    Title = 'Save as';
    [FileName,PathName] = uiputfile(Spec,Title,FilePath);
    FilePath = fullfile(PathName,FileName);
    
    % Verify the user didn't cancel
    if isequal(FileName,0)
        StatusOk = false;
    else
        % Update the last path
        app.LastPath = PathName;
        app.FilePath = FilePath;
    end
    
end

% Is status still Ok?
if StatusOk
    
    % Save the data to MAT format
    save(FilePath,'Analysis');
    
    % Mark the app as clean
    app.IsDirty = false;
    
end

% Add this to the list of recent files
if StatusOk
    addRecentFile(app,FilePath);
end
