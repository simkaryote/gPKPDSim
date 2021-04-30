function refresh(app)
% refresh - Updates all parts of the app display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the app display
%
% Syntax:
%           refresh(app)
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

%% Update the application title

% Update the figure title
set(app.Figure,'Name',app.TitleStr)


%% Update model project path

if ~isempty(app.Analysis.ProjectPath)
    [~,ProjectFileName,ProjectFileExt] = fileparts(app.Analysis.ProjectPath);
    ProjectFileName = [ProjectFileName ProjectFileExt];
    set(app.h.ProjectNameEdit,'String',ProjectFileName);
else
    set(app.h.ProjectNameEdit,'String','Unspecified');
end

if ~isempty(app.Analysis.ModelName)
    set(app.h.ModelNameEdit,'String',app.Analysis.ModelName);
else
    set(app.h.ModelNameEdit,'String','Unspecified');
end


%% Update dataset

if ~isempty(app.Analysis.DatasetTable) && ~isempty(app.Analysis.DatasetTable.FilePath)
    [~,FileName,FileExt] = fileparts(app.Analysis.DatasetTable.FilePath);
    FileName = [FileName,FileExt];
else
    FileName = 'Unspecified';
end
set(app.h.DatasetText,'String',FileName);


%% Variants

if app.IsPC
    if ~isempty(app.Analysis.ModelObj)
        set(app.h.VariantTable,'Enabled','on');
    else
        set(app.h.VariantTable,'Enabled','off');
    end
end

% Auto-assign SelectedVariantsOrder if not set to proper length
if numel(app.Analysis.SelectedVariantsOrder) ~= numel(app.Analysis.SelectedVariants)
    app.Analysis.SelectedVariantsOrder = 1:numel(app.Analysis.SelectedVariants);
end
if ~isempty(app.Analysis.SelectedVariants)
    SelectedOrders = cellfun(@(x)num2str(x),num2cell(app.Analysis.SelectedVariantsOrder),'UniformOutput',false);
    [~,Loc] = ismember(app.Analysis.SelectedVariantNames,get(app.Analysis.SelectedVariants,'Name'));
    if ~isempty(app.Analysis.ModelObj) && ~isempty(app.Analysis.SelectedVariants)
        if numel(app.Analysis.SelectedVariants(Loc)) == 1
            TableData = [...
                {get(app.Analysis.SelectedVariants(Loc),'Active')},...
                SelectedOrders(:),...
                {get(app.Analysis.SelectedVariants(Loc),'Name')},...
                {get(app.Analysis.SelectedVariants(Loc),'Tag')}];
        else
            TableData = [...
                get(app.Analysis.SelectedVariants(Loc),'Active'),...
                SelectedOrders(:),...
                get(app.Analysis.SelectedVariants(Loc),'Name'),...
                get(app.Analysis.SelectedVariants(Loc),'Tag')];
        end
    else
        TableData = {};
    end
else
    TableData = {};
end
OrderOptions = num2cell(1:numel(app.Analysis.SelectedVariants))';
OrderOptions = cellfun(@(x)num2str(x),OrderOptions,'UniformOutput',false);
if app.IsPC
    set(app.h.VariantTable,'Data',TableData,'ColumnFormatData',{{},[{} OrderOptions],{},{}});
else
    if ~isempty(OrderOptions)
        set(app.h.VariantTable,'Data',TableData,'ColumnFormat',{'logical',OrderOptions(:)','char','char'});
    else
        set(app.h.VariantTable,'Data',TableData,'ColumnFormat',{'logical','char','char','char'});
    end        
end


%% Dosing

% Toggle visibility
if strcmpi(app.Analysis.Task,'Fitting')
    set(app.h.DosingNameLabel,'Visible','off');
    set(app.h.DosingTable,'Visible','off')
else
    set(app.h.DosingNameLabel,'Visible','on');
    set(app.h.DosingTable,'Visible','on')    
end

if app.IsPC
    if ~isempty(app.Analysis.ModelObj)
        set(app.h.DosingTable,'Enabled','on');
    else
        set(app.h.DosingTable,'Enabled','off');
    end
end
if ~isempty(app.Analysis.ModelObj) && ~isempty(app.Analysis.SelectedDoses)
    if numel(app.Analysis.SelectedDoses) == 1
        DosingTable = [...
            {get(app.Analysis.SelectedDoses,'Active')},...
            {get(app.Analysis.SelectedDoses,'Name')},...
            {get(app.Analysis.SelectedDoses,'Type')},...
            {get(app.Analysis.SelectedDoses,'TargetName')},...
            {get(app.Analysis.SelectedDoses,'StartTime')},...
            {get(app.Analysis.SelectedDoses,'TimeUnits')},...
            {get(app.Analysis.SelectedDoses,'Amount')},...
            {get(app.Analysis.SelectedDoses,'AmountUnits')},...
            {get(app.Analysis.SelectedDoses,'Interval')},...
            {get(app.Analysis.SelectedDoses,'Rate')},...
            {get(app.Analysis.SelectedDoses,'RepeatCount')},...
            ];
    else
        DosingTable = [...
            get(app.Analysis.SelectedDoses,'Active'),...
            get(app.Analysis.SelectedDoses,'Name'),...
            get(app.Analysis.SelectedDoses,'Type'),...
            get(app.Analysis.SelectedDoses,'TargetName'),...
            get(app.Analysis.SelectedDoses,'StartTime'),...
            get(app.Analysis.SelectedDoses,'TimeUnits'),...
            get(app.Analysis.SelectedDoses,'Amount'),...
            get(app.Analysis.SelectedDoses,'AmountUnits'),...
            get(app.Analysis.SelectedDoses,'Interval'),...
            get(app.Analysis.SelectedDoses,'Rate'),...
            get(app.Analysis.SelectedDoses,'RepeatCount'),...
            ];
    end
else
    DosingTable = {};
end
set(app.h.DosingTable,'Data',DosingTable);


%% Toggle view

switch app.Analysis.Task    
    case 'Simulation'
        set(app.h.AnalysisRadioButtonGroup,'SelectedObject',app.h.SimulationRadioButton);
        app.h.CardLayout.Selection = 1;                
    case 'Fitting'
        set(app.h.AnalysisRadioButtonGroup,'SelectedObject',app.h.FittingRadioButton);
        app.h.CardLayout.Selection = 2;        
    case 'Population'
        set(app.h.AnalysisRadioButtonGroup,'SelectedObject',app.h.PopulationRadioButton);
        app.h.CardLayout.Selection = 3;            
    otherwise
        set(app.h.AnalysisRadioButtonGroup,'SelectedObject',app.h.SimulationRadioButton);
        app.h.CardLayout.Selection = 1;        
end


%% Adjust the heights

updateLeftLayoutSizes(app);


%% Propagate data

app.h.SimulationPanel.Data = app.Analysis;
app.h.FittingPanel.Data = app.Analysis;
app.h.PopulationPanel.Data = app.Analysis;


%% Update NCA

if ~isempty(app.Analysis.NCAParameters)
    TableData = table2cell(app.Analysis.NCAParameters);
    IsNumeric = cellfun(@isnumeric,TableData);
    TableData(~IsNumeric) = cellfun(@char,TableData(~IsNumeric),'UniformOutput',false);    
    
    % Round numeric to 3 decimal places
    TableData(IsNumeric) = cellfun(@(x)roundToN(x,-3),TableData(IsNumeric),'UniformOutput',false);
    
    % Update table
    set(app.h.NCATable,...
        'ColumnName',app.Analysis.NCAParameters.Properties.VariableNames,...
        'ColumnEditable',false(1,numel(app.Analysis.NCAParameters.Properties.VariableNames)),...
        'Data',TableData);
else
    set(app.h.NCATable,'ColumnName','','Data',{});
end


%% Invoke update

update(app);


function Value = roundToN(Value,N)

if N < 0   
    P = 10^-N;    
    Value = round(P*Value)/P;
elseif N > 0
    P = 10^N;    
    Value = P*round(Value/P);
else
    Value = round(Value);
end

