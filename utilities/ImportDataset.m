function varargout = ImportDataset(varargin)
% ImportDataset UI
%
%   Syntax:
%       ImportDataset
%
% IMPORTDATASET MATLAB code for ImportDataset.fig
%      IMPORTDATASET, by itself, creates a new IMPORTDATASET or raises the existing
%      singleton*.
%
%      H = IMPORTDATASET returns the handle to a new IMPORTDATASET or the handle to
%      the existing singleton*.
%
%      IMPORTDATASET('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMPORTDATASET.M with the given input arguments.
%
%      IMPORTDATASET('Property','Value',...) creates a new IMPORTDATASET or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ImportDataset_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ImportDataset_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%   Copyright 2017 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: agajjala $
%   $Revision: 420 $  $Date: 2017-12-07 14:47:44 -0500 (Thu, 07 Dec 2017) $
% ---------------------------------------------------------------------

% Edit the above text to modify the response to help ImportDataset

% Last Modified by GUIDE v2.5 15-Mar-2017 18:34:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @ImportDataset_OpeningFcn, ...
    'gui_OutputFcn',  @ImportDataset_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% Suppress Messages
%#ok<*DEFNU>


% --- Executes just before ImportDataset is made visible.
function ImportDataset_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ImportDataset (see VARARGIN)

% For debugging:
set(handles.GUIFigure,'WindowStyle','modal');

p = inputParser;
p.addParameter('FlagComputeNCA',true,@islogical);
DefaultDatasetTable = PKPD.Dataset;
p.addParameter('DatasetTable',DefaultDatasetTable,@(x)isa(x,'PKPD.Dataset'));
p.addParameter('DefaultFolder',pwd,@ischar);

% Parse and distribute results
p.parse(varargin{:});

% Distribute
FlagComputeNCA = p.Results.FlagComputeNCA;
PrevDatasetTable = p.Results.DatasetTable;
DefaultFolder = p.Results.DefaultFolder;

% New DatasetTable
DatasetTable = PKPD.Dataset;

% Copy old obj to new one
mc = metaclass(PrevDatasetTable);
pList = mc.PropertyList;
isPublicProp = strcmp({pList.SetAccess}, 'public') & strcmp({pList.GetAccess}, 'public');
isOkProp = isPublicProp & ...
    ~([pList.Constant] | [pList.Dependent] | [pList.Transient] | [pList.NonCopyable]);  

% Get the object and structure properties
Props = pList(isOkProp);

% Assign PrevDatasetTable to DatasetTable
for pIndex = 1:numel(Props)
    PropName = Props(pIndex).Name;
    Val = PrevDatasetTable.(PropName);
    DatasetTable.(PropName) = Val;
end

% Compute TimeRange
[TimeRange,NumGroups] = i_ImportDataHelper(DatasetTable.FilePath,DatasetTable.Time,DatasetTable.Group);
   
% -- Save in appdata
setappdata(handles.GUIFigure,'FlagComputeNCA',FlagComputeNCA);
setappdata(handles.GUIFigure,'TimeRange',TimeRange);
setappdata(handles.GUIFigure,'NumGroups',NumGroups);
setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
setappdata(handles.GUIFigure,'DefaultFolder',DefaultFolder);
setappdata(handles.GUIFigure,'CancelSelection',false);        
        
% -- Set GUI name and all labels
set(handles.GUIFigure,'Name','Import Dataset');
i_UpdateViewer(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ImportDataset wait for user response (see UIRESUME)
uiwait(handles.GUIFigure);


% --- Outputs from this function are returned to the command line.
function varargout = ImportDataset_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% First, check if handles is not empty - it is empty when the user presses
% X to close the GUI
if ~isempty(handles)
    cancelselection = getappdata(handles.GUIFigure,'CancelSelection');
    varargout{1} = ~cancelselection;
    if ~cancelselection
        varargout{2} = getappdata(handles.GUIFigure,'DatasetTable');
        varargout{3} = getappdata(handles.GUIFigure,'DefaultFolder');
        varargout{4} = getappdata(handles.GUIFigure,'FlagComputeNCA');
    else
        varargout{2} = [];
        varargout{3} = [];
        varargout{4} = [];
    end
    close(handles.GUIFigure);
else
    % Treat as user pressed cancel and assign next output args to be empty
    varargout{1} = false;
    varargout{2} = [];
    varargout{3} = [];
    varargout{4} = [];
end


function Name_EDIT_Callback(hObject, eventdata, handles)
% hObject    handle to Name_EDIT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Name_EDIT as text
%        str2double(get(hObject,'String')) returns contents of Name_EDIT as a double

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');
Value = strtrim(get(hObject,'String'));

if isempty(Value)
    Message = sprintf('Name must be non-empty.');
    Title = 'Invalid Name';
    hDlg = errordlg(Message,Title,'modal');
    uiwait(hDlg);
else
    DatasetTable.Name = Value;    
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


% --- Executes on button press in Browse_PUSHBUTTON.
function Browse_PUSHBUTTON_Callback(hObject, eventdata, handles)
% hObject    handle to Browse_PUSHBUTTON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');
DefaultFolder = getappdata(handles.GUIFigure,'DefaultFolder');

% Prompt the user for a filename
Spec = {'*.xlsx;*.xls'};
Title = 'Open Dataset';
[FileName,PathName] = uigetfile(Spec,Title,DefaultFolder);
FilePath = fullfile(PathName,FileName);

% Verify the user didn't cancel
if ~isequal(FileName,0)
    set(handles.GUIFigure,'pointer','watch');
    drawnow;
    DatasetTable.FilePath = FilePath;
    DefaultFolder = PathName;
    
    [~,~,Raw] = xlsread(FilePath);
    if ~isempty(Raw)
        Headers = Raw(1,:);
    else
        Headers = {};
    end
    DatasetTable.Headers = Headers;
    
    % Automatically update the name
    [~,Name] = fileparts(FileName);
    DatasetTable.Name = Name;
    
    set(handles.GUIFigure,'pointer','arrow');
    drawnow;
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
setappdata(handles.GUIFigure,'DefaultFolder',DefaultFolder);
i_UpdateViewer(handles);


% --- Executes on selection change in Time_POPUP.
function Time_POPUP_Callback(hObject, eventdata, handles)
% hObject    handle to Time_POPUP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Time_POPUP contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Time_POPUP

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

if ~isempty(DatasetTable)
    Options = DatasetTable.Headers;
    OldValue = DatasetTable.Time;
    NewValue = Options{get(hObject,'Value')};
    
    DatasetTable.Time = NewValue;
    setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
    
    if ~isequal(OldValue,DatasetTable.Time)
        [TimeRange,NumGroups] = i_ImportDataHelper(DatasetTable.FilePath,DatasetTable.Time,DatasetTable.Group);
        setappdata(handles.GUIFigure,'TimeRange',TimeRange);
        setappdata(handles.GUIFigure,'NumGroups',NumGroups);
    end    
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


% --- Executes on selection change in Group_POPUP.
function Group_POPUP_Callback(hObject, eventdata, handles)
% hObject    handle to Group_POPUP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Group_POPUP contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Group_POPUP

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

if ~isempty(DatasetTable)
    Options = DatasetTable.Headers;
    DatasetTable.Group = Options{get(hObject,'Value')};
    
    [TimeRange,NumGroups] = i_ImportDataHelper(DatasetTable.FilePath,DatasetTable.Time,DatasetTable.Group);
    setappdata(handles.GUIFigure,'TimeRange',TimeRange);
    setappdata(handles.GUIFigure,'NumGroups',NumGroups);
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


% --- Executes on selection change in YAxis_LISTBOX.
function YAxis_LISTBOX_Callback(hObject, eventdata, handles)
% hObject    handle to YAxis_LISTBOX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns YAxis_LISTBOX contents as cell array
%        contents{get(hObject,'Value')} returns selected item from YAxis_LISTBOX

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

if ~isempty(DatasetTable)
    Options = DatasetTable.Headers;
    DatasetTable.YAxis = Options(get(hObject,'Value'));
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


% --- Executes on selection change in Dosing_LISTBOX.
function Dosing_LISTBOX_Callback(hObject, eventdata, handles)
% hObject    handle to Dosing_LISTBOX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Dosing_LISTBOX contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Dosing_LISTBOX

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

if ~isempty(DatasetTable)
    Options = DatasetTable.Headers;
    DatasetTable.Dosing = Options(get(hObject,'Value'));
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


% --- Executes on selection change in IVDose_POPUP.
function IVDose_POPUP_Callback(hObject, eventdata, handles)
% hObject    handle to IVDose_POPUP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns IVDose_POPUP contents as cell array
%        contents{get(hObject,'Value')} returns selected item from IVDose_POPUP

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

if ~isempty(DatasetTable)
    Options = get(hObject,'String');
    DatasetTable.IVDose = Options{get(hObject,'Value')};
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


% --- Executes on selection change in SCDose_POPUP.
function SCDose_POPUP_Callback(hObject, eventdata, handles)
% hObject    handle to SCDose_POPUP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SCDose_POPUP contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SCDose_POPUP

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

if ~isempty(DatasetTable)
    Options = get(hObject,'String');
    DatasetTable.SCDose = Options{get(hObject,'Value')};
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


% --- Executes on selection change in Subgroup_POPUP.
function Subgroup_POPUP_Callback(hObject, eventdata, handles)
% hObject    handle to Subgroup_POPUP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Subgroup_POPUP contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Subgroup_POPUP

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

if ~isempty(DatasetTable)
    Options = get(hObject,'String');
    DatasetTable.Subgroup = Options{get(hObject,'Value')};
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


% --- Executes on selection change in Concentration_POPUP.
function Concentration_POPUP_Callback(hObject, eventdata, handles)
% hObject    handle to Concentration_POPUP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Concentration_POPUP contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Concentration_POPUP

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

if ~isempty(DatasetTable)
    Options = get(hObject,'String');
    DatasetTable.Concentration = Options{get(hObject,'Value')};
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


function AUCTimePoints_EDIT_Callback(hObject, eventdata, handles)
% hObject    handle to AUCTimePoints_EDIT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AUCTimePoints_EDIT as text
%        str2double(get(hObject,'String')) returns contents of AUCTimePoints_EDIT as a double

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

% Get TimeRange, NumGroups
TimeRange = getappdata(handles.GUIFigure,'TimeRange');

if ~isempty(DatasetTable)
    TimePoints = str2num(get(hObject,'String')); %#ok<ST2NM>
    [NaNRow,~] = find(isnan(TimePoints));
    TimePoints(NaNRow,:) = [];
    
    if ~isempty(TimePoints) && ...
            (any(TimePoints(:,1) > TimePoints(:,2)) || ...
            any(any(TimePoints < TimeRange(1))) || ...
            any(any(TimePoints > TimeRange(2))))
        hDlg = errordlg('Invalid time points chosen for AUC calculations. Must specify an empty vector (no time points) or a matrix of Nx2 time points to be applied to all groups. All time points must be within the time range of the file.','Invalid','modal');
        uiwait(hDlg);
    else            
        DatasetTable.AUCTimePoints = TimePoints;
    end
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


function CmaxTimePoints_EDIT_Callback(hObject, eventdata, handles)
% hObject    handle to cmaxtimepoints_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cmaxtimepoints_edit as text
%        str2double(get(hObject,'String')) returns contents of cmaxtimepoints_edit as a double

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

% Get TimeRange, NumGroups
TimeRange = getappdata(handles.GUIFigure,'TimeRange');

if ~isempty(DatasetTable)
    TimePoints = str2num(get(hObject,'String')); %#ok<ST2NM>
    [NaNRow,~] = find(isnan(TimePoints));
    TimePoints(NaNRow,:) = [];
    
    if ~isempty(TimePoints) && ...
            (any(TimePoints(:,1) > TimePoints(:,2)) || ...
            any(any(TimePoints < TimeRange(1))) || ...
            any(any(TimePoints > TimeRange(2))))
        hDlg = errordlg('Invalid time points chosen for Cmax calculations. Must specify an empty vector (no time points) or a matrix of Nx2 time points to be applied to all groups. All time points must be within the time range of the file.','Invalid','modal');
        uiwait(hDlg);
    else            
        DatasetTable.CmaxTimePoints = TimePoints;
    end
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


function CustomHalfLifeEstimationTimePoints_EDIT_Callback(hObject, eventdata, handles)
% hObject    handle to CustomHalfLifeEstimationTimePoints_EDIT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CustomHalfLifeEstimationTimePoints_EDIT as text
%        str2double(get(hObject,'String')) returns contents of CustomHalfLifeEstimationTimePoints_EDIT as a double

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

% Get TimeRange, NumGroups
TimeRange = getappdata(handles.GUIFigure,'TimeRange');

if ~isempty(DatasetTable)
    TimePoints = str2num(get(hObject,'String')); %#ok<ST2NM>
    TimePoints(isnan(TimePoints)) = [];
    
    if ~isempty(TimePoints) && ...
            (size(TimePoints,1) > 1 || ...
            TimePoints(1) > TimePoints(2) ||...
            TimePoints(1) < TimeRange(1) || ...
            TimePoints(2) > TimeRange(2))

        hDlg = errordlg('Invalid time points chosen for half-life estimation calculations. Must specify [t0 tN], where t0 < tN. Time points must be within time range of the file.','Invalid','modal');
        uiwait(hDlg);
    else            
        DatasetTable.HalfLifeEstimationTimePoints = TimePoints;
    end
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


% --- Executes when selected object is changed in NCAAnalysisType_BUTTONGROUP.
function NCAAnalysisType_BUTTONGROUP_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in NCAAnalysisType_BUTTONGROUP 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

if ~isempty(DatasetTable)
    if isequal(hObject,handles.SparseNCA_RADIOBUTTON)        
        DatasetTable.Sparse = true;
    elseif isequal(hObject,handles.SerialNCA_RADIOBUTTON)        
        DatasetTable.Sparse = false;
    end
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


% --- Executes when selected object is changed in TerminalHalfLife_BUTTONGROUP.
function TerminalHalfLife_BUTTONGROUP_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in TerminalHalfLife_BUTTONGROUP 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

if ~isempty(DatasetTable)
    if isequal(hObject,handles.AutomaticHalfLifeEstimation_RADIOBUTTON)        
        DatasetTable.AutomaticHalfLifeEstimation = true;
    elseif isequal(hObject,handles.CustomHalfLifeEstimation_RADIOBUTTON)        
        DatasetTable.AutomaticHalfLifeEstimation = false;
    end
end

setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);
i_UpdateViewer(handles);


% --- Executes on button press in ComputeNCA_CHECKBOX.
function ComputeNCA_CHECKBOX_Callback(hObject, eventdata, handles)
% hObject    handle to ComputeNCA_CHECKBOX (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ComputeNCA_CHECKBOX

Value = logical(get(hObject,'Value'));
setappdata(handles.GUIFigure,'FlagComputeNCA',Value);
i_UpdateViewer(handles);


% --- Executes on button press in Import_PUSHBUTTON.
function Import_PUSHBUTTON_Callback(hObject, eventdata, handles) %#ok<*INUSL>
% hObject    handle to Import_PUSHBUTTON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');

% Validate    
if exist(DatasetTable.FilePath,'file') == 2 && ...
        ~isempty(DatasetTable.Name) && ...
        ~isempty(DatasetTable.Time) && ...
        ~isempty(DatasetTable.Group) && ...
        ~isempty(DatasetTable.YAxis) && ...
        ~isempty(DatasetTable.Dosing) % No general guard needed for NCA though may want to add for group count  
        
    % Resume control
    uiresume(handles.GUIFigure);
else
    hDlg = errordlg('Datasets must be non-empty, names must be specified, and files must exist.','Invalid','modal');
    uiwait(hDlg);
end


% --- Executes on button press in Cancel_PUSHBUTTON.
function Cancel_PUSHBUTTON_Callback(~, ~, handles)
% hObject    handle to Cancel_PUSHBUTTON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Choose default command line output for ImportDataset

% Resume control if user pressed cancel
setappdata(handles.GUIFigure,'CancelSelection',true);
uiresume(handles.GUIFigure);


%% Helper function: i_UpdateViewer
function i_UpdateViewer(handles)

DatasetTable = getappdata(handles.GUIFigure,'DatasetTable');
FlagComputeNCA = getappdata(handles.GUIFigure,'FlagComputeNCA');

% Get headers
if ~isempty(DatasetTable)    
    Headers = DatasetTable.Headers;    
else
    Headers = {};
end

% Name
if ~isempty(DatasetTable)
    set(handles.Name_EDIT,'String',DatasetTable.Name);
else
    set(handles.Name_EDIT,'String','');
end

% Filepath
if ~isempty(DatasetTable) && ~isempty(DatasetTable.FilePath)
    set(handles.FilePath_TEXT,'String',DatasetTable.FilePath);
else
    set(handles.FilePath_TEXT,'String','<No File Selected>');
end

% Time
if ~isempty(DatasetTable) && ~isempty(Headers)
    MatchIndex = find(strcmpi(DatasetTable.Time,Headers));
    if isempty(MatchIndex)
        MatchIndex = find(strcmpi(Headers,'Time'));
        if ~isempty(MatchIndex)
            MatchIndex = MatchIndex(1);
        else
            MatchIndex = 1;
        end
    end
    DatasetTable.Time = Headers{MatchIndex};
    set(handles.Time_POPUP,'Value',MatchIndex,'String',Headers);
else
    set(handles.Time_POPUP,'Value',1,'String','Unspecified');
end

% Group
if ~isempty(DatasetTable) && ~isempty(Headers)
    MatchIndex = find(strcmpi(DatasetTable.Group,Headers));
    if isempty(MatchIndex)
        MatchIndex = find(strcmpi(Headers,'Group'));
        if ~isempty(MatchIndex)
            MatchIndex = MatchIndex(1);
        else
            MatchIndex = 1;
        end
    end
    DatasetTable.Group = Headers{MatchIndex};
    set(handles.Group_POPUP,'Value',MatchIndex,'String',Headers);    
else
    set(handles.Group_POPUP,'Value',1,'String','Unspecified');    
end

% Compute TimeRange and num groups
TimeRange = getappdata(handles.GUIFigure,'TimeRange');
NumGroups = getappdata(handles.GUIFigure,'NumGroups');
if isempty(TimeRange) || isempty(NumGroups)
    [TimeRange,NumGroups] = i_ImportDataHelper(DatasetTable.FilePath,DatasetTable.Time,DatasetTable.Group);
    setappdata(handles.GUIFigure,'TimeRange',TimeRange);
    setappdata(handles.GUIFigure,'NumGroups',NumGroups);
end

% Update Group label
if ~isempty(DatasetTable) && ~isempty(Headers)
    set(handles.Group_TEXT,'String',sprintf('%s (%d)',DatasetTable.Group,NumGroups));
else
    set(handles.Group_TEXT,'String','Unspecified');
end

% Subgroup
if ~isempty(DatasetTable) && ~isempty(Headers)
    HeadersWithoutGroup = Headers;
    HeadersWithoutGroup = HeadersWithoutGroup(~strcmpi(HeadersWithoutGroup,DatasetTable.Group));
    HeadersWithoutGroup = vertcat({'Unspecified'},HeadersWithoutGroup(:));
    
    % Update Subgroup so that Group ~= Subgroup
    if strcmpi(DatasetTable.Group,DatasetTable.Subgroup)
        if ~isempty(HeadersWithoutGroup)
            DatasetTable.Subgroup = HeadersWithoutGroup{1};
        end
    end
    MatchIndex = find(strcmpi(DatasetTable.Subgroup,HeadersWithoutGroup));
    if isempty(MatchIndex)
        MatchIndex = find(strcmpi(HeadersWithoutGroup,'Subgroup'));
        if ~isempty(MatchIndex)
            MatchIndex = MatchIndex(1);
        else
            MatchIndex = 1;
        end
    end
    DatasetTable.Subgroup = HeadersWithoutGroup{MatchIndex};
    set(handles.Subgroup_POPUP,'Value',MatchIndex,'String',HeadersWithoutGroup);
else
    set(handles.Subgroup_POPUP,'Value',1,'String','Unspecified');
end

% Y-Axis
if ~isempty(DatasetTable) && ~isempty(Headers)
    MatchIndex = find(ismember(Headers,DatasetTable.YAxis));
    if isempty(MatchIndex)
        MatchIndex = find(strcmpi(Headers,'Conc'));
        if ~isempty(MatchIndex)
            MatchIndex = MatchIndex(1);
        else
            MatchIndex = [];
        end
    end
    DatasetTable.YAxis = Headers(MatchIndex);
    set(handles.YAxis_LISTBOX,'Value',MatchIndex,'String',Headers);
else
    set(handles.YAxis_LISTBOX,'Value',1,'String','Unspecified');
end

% Dosing
if ~isempty(DatasetTable) && ~isempty(Headers)
    MatchIndex = find(ismember(Headers,DatasetTable.Dosing));
    if isempty(MatchIndex)
        MatchIndex = find(ismember(Headers,{'DoseIV','DoseSC'}));
        if ~isempty(MatchIndex)
            MatchIndex = MatchIndex(1);
        else
            MatchIndex = [];
        end
    end
    DatasetTable.Dosing = Headers(MatchIndex);
    set(handles.Dosing_LISTBOX,'Value',MatchIndex,'String',Headers);
else
    set(handles.Dosing_LISTBOX,'Value',1,'String','Unspecified');
end

% IV Dose Baseline
if ~isempty(DatasetTable) && ~isempty(DatasetTable.Dosing)
    TheseOptions = vertcat({'Unspecified'},DatasetTable.Dosing(:));
    MatchIndex = find(strcmpi(DatasetTable.IVDose,TheseOptions));
    if isempty(MatchIndex)
        MatchIndex = find(strcmpi(TheseOptions,'DoseIV'));
        if ~isempty(MatchIndex)
            MatchIndex = MatchIndex(1);
        else
            MatchIndex = 1;
        end
    end
    DatasetTable.IVDose = TheseOptions{MatchIndex};
    set(handles.IVDose_POPUP,'Value',MatchIndex,'String',TheseOptions);
else
    set(handles.IVDose_POPUP,'Value',1,'String','Unspecified');
end

% SC Dose Baseline
if ~isempty(DatasetTable) && ~isempty(DatasetTable.Dosing)
    TheseOptions = vertcat({'Unspecified'},DatasetTable.Dosing(:));
    MatchIndex = find(strcmpi(DatasetTable.SCDose,TheseOptions));
    if isempty(MatchIndex)
        MatchIndex = find(strcmpi(TheseOptions,'DoseSC'));
        if ~isempty(MatchIndex)
            MatchIndex = MatchIndex(1);
        else
            MatchIndex = 1;
        end
    end
    DatasetTable.SCDose = TheseOptions{MatchIndex};
    set(handles.SCDose_POPUP,'Value',MatchIndex,'String',TheseOptions);
else
    set(handles.SCDose_POPUP,'Value',1,'String','Unspecified');
end

% Concentration
if ~isempty(DatasetTable) && ~isempty(Headers) && ~isempty(DatasetTable.YAxis)
    TheseOptions = DatasetTable.YAxis(:);
    MatchIndex = find(strcmpi(DatasetTable.Concentration,TheseOptions));
    if isempty(MatchIndex)
        MatchIndex = find(strcmpi(TheseOptions,'Conc'));
        if ~isempty(MatchIndex)
            MatchIndex = MatchIndex(1);
        else
            MatchIndex = 1;
        end
    end
    DatasetTable.Concentration = TheseOptions{MatchIndex};
    set(handles.Concentration_POPUP,'Value',MatchIndex,'String',TheseOptions);
else
    set(handles.Concentration_POPUP,'Value',1,'String','Unspecified');
end

% Time Range
if ~isempty(TimeRange) && numel(TimeRange) == 2
    set(handles.TimeRange_TEXT,'String',sprintf('[%.2f %.2f]',TimeRange(1),TimeRange(2)));
else
    set(handles.TimeRange_TEXT,'String','-');
end

% AUC time points
if ~isempty(DatasetTable.AUCTimePoints)
    set(handles.AUCTimePoints_EDIT,'String',mat2str(DatasetTable.AUCTimePoints));
else
    set(handles.AUCTimePoints_EDIT,'String','');
end

% Cmax time points
if ~isempty(DatasetTable.CmaxTimePoints)
    set(handles.CmaxTimePoints_EDIT,'String',mat2str(DatasetTable.CmaxTimePoints));
else
    set(handles.CmaxTimePoints_EDIT,'String','');
end

% Half-life estimation time points
if ~isempty(DatasetTable)
    if DatasetTable.AutomaticHalfLifeEstimation
        set(handles.TerminalHalfLife_BUTTONGROUP,'SelectedObject',handles.AutomaticHalfLifeEstimation_RADIOBUTTON);
    else
        set(handles.TerminalHalfLife_BUTTONGROUP,'SelectedObject',handles.CustomHalfLifeEstimation_RADIOBUTTON);
    end
end

if ~isempty(DatasetTable.HalfLifeEstimationTimePoints)
    set(handles.CustomHalfLifeEstimationTimePoints_EDIT,'String',mat2str(DatasetTable.HalfLifeEstimationTimePoints));
else
    set(handles.CustomHalfLifeEstimationTimePoints_EDIT,'String','');
end

% NCA Analysis Type
if ~isempty(DatasetTable)
    if DatasetTable.Sparse
        set(handles.NCAAnalysisType_BUTTONGROUP,'SelectedObject',handles.SparseNCA_RADIOBUTTON);
    else
        set(handles.NCAAnalysisType_BUTTONGROUP,'SelectedObject',handles.SerialNCA_RADIOBUTTON);
    end
end

% Store
setappdata(handles.GUIFigure,'DatasetTable',DatasetTable);

% Check if sbionca is on the path
IsNCAfile = which('sbionca');
if isempty(IsNCAfile)
    NCAEnable = 'off';
    FlagComputeNCA = false;
    setappdata(handles.GUIFigure,'FlagComputeNCA',FlagComputeNCA);
    set(handles.ComputeNCA_CHECKBOX,'String','Compute NCA (NCA package not installed)')
else
    NCAEnable = 'on';
    set(handles.ComputeNCA_CHECKBOX,'String','Compute NCA')
end

% Toggle NCA
set(handles.ComputeNCA_CHECKBOX,'Value',FlagComputeNCA,'Enable',NCAEnable);
if FlagComputeNCA
    set([...
        handles.IVDose_LABEL,...
        handles.IVDose_POPUP,...
        handles.SCDose_LABEL,...
        handles.SCDose_POPUP,...
        handles.Concentration_LABEL,...
        handles.Concentration_POPUP,...        
        handles.Group_LABEL,...
        handles.Group_TEXT,...
        handles.TimeRange_LABEL,...
        handles.TimeRange_TEXT,...
        handles.AUCTimePoints_LABEL,...
        handles.AUCTimePoints_EDIT,...
        handles.CmaxTimePoints_LABEL,...
        handles.CmaxTimePoints_EDIT,...
        handles.AutomaticHalfLifeEstimation_RADIOBUTTON,...
        handles.CustomHalfLifeEstimation_RADIOBUTTON,...
        handles.CustomHalfLifeEstimationTimePoints_EDIT,...
        handles.SparseNCA_RADIOBUTTON,...
        handles.SerialNCA_RADIOBUTTON,...
        ],'Enable','on');
    if DatasetTable.Sparse
        set([...
            handles.Subgroup_LABEL,...
            handles.Subgroup_POPUP],...
            'Enable','off');        
    else
        set([...
            handles.Subgroup_LABEL,...
            handles.Subgroup_POPUP],...
            'Enable','on');
    end
    if DatasetTable.AutomaticHalfLifeEstimation
        set([...
            handles.CustomHalfLifeEstimationTimePoints_EDIT],...
            'Enable','off');        
    else
        set([...            
            handles.CustomHalfLifeEstimationTimePoints_EDIT],...
            'Enable','on');
    end
            
else
    set([...
        handles.IVDose_LABEL,...
        handles.IVDose_POPUP,...
        handles.SCDose_LABEL,...
        handles.SCDose_POPUP,...
        handles.Concentration_LABEL,...
        handles.Concentration_POPUP,...
        handles.Group_LABEL,...
        handles.Group_TEXT,...
        handles.Subgroup_LABEL,...
        handles.Subgroup_POPUP,...
        handles.TimeRange_LABEL,...
        handles.TimeRange_TEXT,...
        handles.AUCTimePoints_LABEL,...
        handles.AUCTimePoints_EDIT,...
        handles.CmaxTimePoints_LABEL,...
        handles.CmaxTimePoints_EDIT,...
        handles.AutomaticHalfLifeEstimation_RADIOBUTTON,...
        handles.CustomHalfLifeEstimation_RADIOBUTTON,...
        handles.CustomHalfLifeEstimationTimePoints_EDIT,...
        handles.SparseNCA_RADIOBUTTON,...
        handles.SerialNCA_RADIOBUTTON,...
        ],'Enable','off');
end


%% Helper function: i_ImportDataHelper
function [TimePoints,NumGroups] = i_ImportDataHelper(FilePath,TimeVar,GroupVar)

DefaultTimeRange = [];
DefaultNumGroups = [];

try
    TimeVar = matlab.lang.makeValidName(TimeVar);
    GroupVar = matlab.lang.makeValidName(GroupVar);
    ThisData = readtable(FilePath);
    if ~isempty(ThisData) && any(strcmp(ThisData.Properties.VariableNames,TimeVar))
        TimeVec = unique(ThisData.(TimeVar));
        TimePoints = [min(TimeVec) max(TimeVec)];        
    else
        TimePoints = DefaultTimeRange;
    end
    
    if ~isempty(ThisData) && any(strcmp(ThisData.Properties.VariableNames,GroupVar))
        % Sum the non-empty groups
        TheseValues = unique(ThisData.(GroupVar));
        if ~iscell(TheseValues)
            TheseValues = num2cell(TheseValues);
        end
        NumGroups = sum(~cellfun(@isempty,TheseValues));
    else
        NumGroups = 0;
    end
catch
    TimePoints = DefaultTimeRange;
    NumGroups = DefaultNumGroups;
end
