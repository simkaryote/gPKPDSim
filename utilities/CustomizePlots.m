function varargout = CustomizePlots(varargin)
% CustomizePlots UI
%
%   Syntax:
%       CustomizePlots
%
% CUSTOMIZEPLOTS MATLAB code for CustomizePlots.fig
%      CUSTOMIZEPLOTS, by itself, creates a new CUSTOMIZEPLOTS or raises the existing
%      singleton*.
%
%      H = CUSTOMIZEPLOTS returns the handle to a new CUSTOMIZEPLOTS or the handle to
%      the existing singleton*.
%
%      CUSTOMIZEPLOTS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CUSTOMIZEPLOTS.M with the given input arguments.
%
%      CUSTOMIZEPLOTS('Property','Value',...) creates a new CUSTOMIZEPLOTS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CustomizePlots_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CustomizePlots_OpeningFcn via varargin.
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

% Edit the above text to modify the response to help CustomizePlots

% Last Modified by GUIDE v2.5 01-Feb-2017 23:01:45

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @CustomizePlots_OpeningFcn, ...
    'gui_OutputFcn',  @CustomizePlots_OutputFcn, ...
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


% --- Executes just before CustomizePlots is made visible.
function CustomizePlots_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CustomizePlots (see VARARGIN)

% For debugging:
set(handles.GUIFigure,'WindowStyle','modal')
set(handles.GUIFigure,'Resize','on');
set(handles.Settings1_PANEL,'Units','normalized');
set(handles.Settings2_PANEL,'Units','normalized');
set(handles.Settings3_PANEL,'Units','normalized');
set(handles.Settings4_PANEL,'Units','normalized');
set(handles.OK_PUSHBUTTON,'Units','normalized');

p = inputParser;

p.addParameter('Settings',PKPD.PlotSettings.empty(0,1),@(x)all(isa(x,'PKPD.PlotSettings')));

% Parse and distribute results
p.parse(varargin{:});

% Distribute
Settings = p.Results.Settings;

% -- Create table
handles.SettingsTable(1) = uitable(...
    'Parent',handles.Settings1_PANEL,...
    'Units','normalized',...
    'Position',[0 0 1 1],...
    'Tag','SettingsTable1');
handles.SettingsTable(2) = uitable(...
    'Parent',handles.Settings2_PANEL,...
    'Units','normalized',...
    'Position',[0 0 1 1],...
    'Tag','SettingsTable2');
handles.SettingsTable(3) = uitable(...
    'Parent',handles.Settings3_PANEL,...
    'Units','normalized',...
    'Position',[0 0 1 1],...
    'Tag','SettingsTable3');
handles.SettingsTable(4) = uitable(...
    'Parent',handles.Settings4_PANEL,...
    'Units','normalized',...
    'Position',[0 0 1 1],...
    'Tag','SettingsTable4');

for index = 1:numel(handles.SettingsTable)
    % Create context menu
    handles.SettingsTableContextMenu = uicontextmenu('Parent',handles.GUIFigure);
    uimenu(handles.SettingsTableContextMenu,...
        'Label','Apply to All Plots',...
        'Tag','ApplyAll',...
        'Callback',@(h,e)onSettingsTableContextMenu(h,e,handles,index));
    set(handles.SettingsTable(index),...
        'CellSelectionCallback',@(h,e)onSettingsTableSelection(h,e,handles,index),...
        'CellEditCallback',@(h,e)onSettingsTableEdited(h,e,handles,index),...
        'UIContextMenu',handles.SettingsTableContextMenu);
end


% -- Save in appdata
setappdata(handles.GUIFigure,'Settings',Settings);
setappdata(handles.GUIFigure,'CancelSelection',false);      
setappdata(handles.GUIFigure,'Row',1);
setappdata(handles.GUIFigure,'Col',1);
PropertyGroup = {...
    'SettablePropertiesGroup1',...
    'SettablePropertiesGroup2',...
    'SettablePropertiesGroup3',...
    'SettablePropertiesGroup4',...
    };
setappdata(handles.GUIFigure,'PropertyGroup',PropertyGroup);

% -- Set GUI name and all labels
set(handles.GUIFigure,'Name','Customize Plot Settings');
i_UpdateViewer(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CustomizePlots wait for user response (see UIRESUME)
uiwait(handles.GUIFigure);


% --- Outputs from this function are returned to the command line.
function varargout = CustomizePlots_OutputFcn(~, ~, handles)
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
        varargout{2} = getappdata(handles.GUIFigure,'Settings');        
    else
        varargout{2} = [];        
    end
    close(handles.GUIFigure);
else
    % Treat as user pressed cancel and assign next output args to be empty
    varargout{1} = false;
    varargout{2} = [];    
end


% --- Executes on button press in OK_PUSHBUTTON.
function OK_PUSHBUTTON_Callback(hObject, eventdata, handles) %#ok<*INUSL>
% hObject    handle to OK_PUSHBUTTON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(handles.GUIFigure);


% --- Executes on button press in Cancel_PUSHBUTTON.
function Cancel_PUSHBUTTON_Callback(~, ~, handles)
% hObject    handle to Cancel_PUSHBUTTON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Choose default command line output for CustomizePlots

% Resume control if user pressed cancel
setappdata(handles.GUIFigure,'CancelSelection',true);
uiresume(handles.GUIFigure);


function onSettingsTableContextMenu(hObject, eventData, handles, index)

Settings = getappdata(handles.GUIFigure,'Settings');
PropertyGroup = getappdata(handles.GUIFigure,'PropertyGroup');
ThisPropGroup = PropertyGroup{index};

Row = getappdata(handles.GUIFigure,'Row');
Col = getappdata(handles.GUIFigure,'Col');

ThisData = get(handles.SettingsTable(index),'Data');
for index = 1:numel(Settings)
    Settings(index).(Settings(index).(ThisPropGroup){Col,1}) = ThisData{Row,Col};
end

setappdata(handles.GUIFigure,'Settings',Settings);

% Update viewer
i_UpdateViewer(handles);


function onSettingsTableSelection(hObject, eventData, handles, index) %#ok<INUSD>

if ~isempty(eventData) && isprop(eventData,'Indices') && numel(eventData.Indices) == 2
    Indices = eventData.Indices;
    setappdata(handles.GUIFigure,'Row',Indices(1));
    setappdata(handles.GUIFigure,'Col',Indices(2));     
end
    

function onSettingsTableEdited(hObject, eventData, handles, index)

NewData = get(hObject,'Data');
PropertyGroup = getappdata(handles.GUIFigure,'PropertyGroup');
ThisPropGroup = PropertyGroup{index};

Settings = getappdata(handles.GUIFigure,'Settings');
if ~isempty(eventData) && isprop(eventData,'Indices') && numel(eventData.Indices) == 2
    Indices = eventData.Indices;
    Row = Indices(1);
    Col = Indices(2);
    try
        Settings(Row).(Settings(Row).(ThisPropGroup){Col,1}) = NewData{Row,Col};
    catch ME  
        NewData{Row,Col} = Settings(Row).(Settings(Row).(ThisPropGroup){Col,1});
        set(hObject,'Data',NewData); 
        hDlg = errordlg(sprintf('Invalid value entered. %s',ME.message),'Invalid Value','modal');
        uiwait(hDlg);
    end
    setappdata(handles.GUIFigure,'Row',Indices(1));
    setappdata(handles.GUIFigure,'Col',Indices(2));
end

% Update viewer
i_UpdateViewer(handles);


%% Helper function: i_UpdateViewer
function i_UpdateViewer(handles)

Settings = getappdata(handles.GUIFigure,'Settings');
PropertyGroup = getappdata(handles.GUIFigure,'PropertyGroup');

if ~isempty(Settings)
    for pIndex = 1:numel(PropertyGroup)
        Summary = {};
        for index = 1:numel(Settings)
            ThisSummary = struct2cell(Settings(index).getSummary(PropertyGroup{pIndex}));
            ThisSummary = ThisSummary(:)';
            Summary = [Summary; ThisSummary]; %#ok<AGROW>
        end
        Fields = Settings(1).(PropertyGroup{pIndex})(:,1);
        ColumnFormat = Settings(1).(PropertyGroup{pIndex})(:,2);
        RowNames = cellfun(@(x)sprintf('Plot %d',x),num2cell(1:numel(Settings)),'UniformOutput',false);
        
        % Set table
        set(handles.SettingsTable(pIndex),...
            'RowName',RowNames,...
            'ColumnName',Fields,...
            'ColumnEditable',true(1,numel(Fields)),...
            'ColumnFormat',ColumnFormat(:)',...
            'Data',Summary);

    end
else
    Fields = {};
    Summary = {};
    ColumnFormat = {};
    RowNames = {};
    
    for pIndex = 1:numel(PropertyGroup)
        % Set table
        set(handles.SettingsTable(pIndex),...
            'RowName',RowNames,...
            'ColumnName',Fields,...
            'ColumnEditable',true(1,numel(Fields)),...
            'ColumnFormat',ColumnFormat(:)',...
            'Data',Summary);
    end
end
