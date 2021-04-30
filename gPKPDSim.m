function app = gPKPDSim

% Do not run this when packaging a MATLAB app
% % Add the appropriate paths 
% DefinePaths

if isempty(ver('simbio')) || isempty(ver('stats'))
    error('This app requires SimBiology and the Statistics and Machine Learning Toolbox to run. The Optimization Toolbox and Global Optimization Toolboxes are optional (for fitting).');
end

if isempty(ver('layout'))
    error('This app requires GUI Layout Toolbox (Version 2.3.1 or higher) to run. Please install from MATLAB Add-Ons or MATLAB Central');
end

% If version is < R2015a, error out
if verLessThan('matlab','9.0')
    error('The app was tested in MATLAB R2015b, R2016a, and R2016b. An older version of MATLAB was detected. Please use one of the supported releases.');
elseif ~verLessThan('matlab','9.2')
    warning('The app was tested in MATLAB R2015b, R2016a, and R2016b. The app was not tested in the detected release and may not run as expected.');
end

% Run units.m
units;

% Install NCA Toolbox for versions <= R2017a
Toolboxes = matlab.addons.toolbox.installedToolboxes;
NCAToolboxFile = 'SimBiolodyNCA.mltbx'; % TODO: Handle the path...
if ~isempty(Toolboxes)
    IsNCAInstalled = strcmpi({Toolboxes.Name},'SimBiologyNCA');
end
if verLessThan('matlab','9.3') && exist(NCAToolboxFile,'file') == 2 && ...
        (isempty(Toolboxes) || (~isempty(Toolboxes) && ~any(IsNCAInstalled)))
    % Install NCA Toolbox for versions <= 9.2 (R2017a and lower) if NCA
    % Toolbox file is specified in current directory
    disp('Installing Non-Compartmental Analysis (NCA) Toolbox into Add-Ons');
    disp('---------------------------------------------------');    
    InstalledToolbox = matlab.addons.toolbox.installToolbox(NCAToolboxFile);
    
elseif ~verLessThan('matlab','9.3') && ~isempty(Toolboxes) && any(IsNCAInstalled)
    % Uninstall NCA Toolbox for versions >= 9.3 (R2017b and higher)
    disp('Uninstalling Non-Compartmental Analysis (NCA) Toolbox from Add-Ons');
    disp('---------------------------------------------------');    
    matlab.addons.toolbox.uninstallToolbox(Toolboxes(IsNCAInstalled));
end

% Make sure NCA is at the top of the path for older releases
if verLessThan('matlab','9.3')    
    NCADir = fileparts(which('sbionca'));
    if ~isempty(NCADir) % TODO: Verify
        addpath(NCADir);
    end
end
    
% disp('Initializing Java paths for UI Widgets');
% disp('---------------------------------------------------');

% Add Javapaths
Paths = {
    fullfile(fileparts(which('uiextras.jTable.Table')), 'UIExtrasTable.jar')
    fullfile(fileparts(which('xlwrite')),'poi_library','poi-3.8-20120326.jar')
    fullfile(fileparts(which('xlwrite')),'poi_library','poi-ooxml-3.8-20120326.jar')
    fullfile(fileparts(which('xlwrite')),'poi_library','poi-ooxml-schemas-3.8-20120326.jar')
    fullfile(fileparts(which('xlwrite')),'poi_library','xmlbeans-2.3.0.jar')
    fullfile(fileparts(which('xlwrite')),'poi_library','dom4j-1.6.1.jar')
    fullfile(fileparts(which('xlwrite')),'poi_library','stax-api-1.0.1.jar')
    };

% % Display
% fprintf('%s\n',Paths{:});
% 
% Add paths
javaaddpath(Paths);
% disp('---------------------------------------------------');

% Instantiate the application
app = PKPDViewer.AnalysisApp.getInstance;
