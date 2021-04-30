function update(app)
% update - Updates all parts of the app display
% -------------------------------------------------------------------------
% Abstract: This function updates all parts of the app display
%
% Syntax:
%           update(app)
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


%% Update top menus

% Enable Save menu item only if dirty
if app.IsDirty
    set(app.h.FileSave_MENU,'Enable','on')
else
    set(app.h.FileSave_MENU,'Enable','off')
end

% Refresh the list of Recent Files 
i_UpdateRecentFiles(...
    app.h.FileOpenRecent_MENU,... %handle to the File->Open Recent menu
    app.RecentFiles,... %Current list of recent filenames
    @(FileName)onOpen(app,FileName) ); %Callback to open a file by name

% Disable FileImportData
if ~isempty(app.Analysis) && ~isempty(app.Analysis.ModelObj)
    set(app.h.FileImportData_MENU,'Enable','on');
else
    set(app.h.FileImportData_MENU,'Enable','off');
end


%% Update Overlay

if ~isempty(app.Analysis.ModelObj)
    set(app.h.PlotOverlayCheckbox,'Enable','on');
    if strcmpi(app.Analysis.Task,'Simulation')
        set(app.h.PlotOverlayCheckbox,'Value',app.Analysis.FlagSimOverlay);
    elseif strcmpi(app.Analysis.Task,'Population')
        set(app.h.PlotOverlayCheckbox,'Value',app.Analysis.FlagPopOverlay);
    end
else
    set(app.h.PlotOverlayCheckbox,'Enable','off');    
end
    

%% Update Plot Layout

if ~isempty(app.Analysis.ModelObj)
    set(app.h.PlotLayoutPopup,'Enable','on');
    MatchIndex = find(strcmpi(app.Analysis.SelectedPlotLayout,app.Analysis.PlotLayoutOptions));
    if isempty(MatchIndex)
        MatchIndex = 1;
    end
    set(app.h.PlotLayoutPopup,'Value',MatchIndex,'String',app.Analysis.PlotLayoutOptions);
else
    set(app.h.PlotLayoutPopup,'Enable','off');
end
    

%% Update Species Data
   
if ~isempty(app.Analysis.ModelObj) && ~isempty(app.Analysis.PlotSpeciesTable)
    % Get axes options for dropdown
    AxesOptions = num2cell(app.SimulationPlotIdx)';
    AxesOptions = cellfun(@(x)num2str(x),AxesOptions,'UniformOutput',false);
    AxesOptions = vertcat({' '},AxesOptions);
    
    TableData = cell(size(app.Analysis.PlotSpeciesTable,1),size(app.Analysis.PlotSpeciesTable,2)+1);
    TableData(:,1) = app.Analysis.PlotSpeciesTable(:,1);
    TableData(:,2) = app.Analysis.SpeciesLineStyles(:);
    TableData(:,3) = app.Analysis.PlotSpeciesTable(:,2);
    TableData(:,4) = app.Analysis.PlotSpeciesTable(:,3);
    
    if app.IsPC
        set(app.h.SpeciesDataTable,'Data',TableData);
        set(app.h.SpeciesDataTable,'ColumnFormatData',{AxesOptions,app.Analysis.LineStyleMap,{},{}});
    else
        set(app.h.SpeciesDataTable,'Data',TableData,'ColumnFormat',{AxesOptions(:)',app.Analysis.LineStyleMap(:)','char','char',});
    end
    
else
    set(app.h.SpeciesDataTable,'Data',{});
end


%% Update Experimental Data

if ~isempty(app.Analysis.PlotDatasetTable) && ~isempty(app.Analysis.DataToFit) && ~isempty(app.Analysis.PlotDatasetTable)
    
    % Get axes options for dropdown
    AxesOptions = num2cell(app.SimulationPlotIdx)';
    AxesOptions = cellfun(@(x)num2str(x),AxesOptions,'UniformOutput',false);
    AxesOptions = vertcat({' '},AxesOptions);
    
    TableData = cell(size(app.Analysis.PlotDatasetTable,1),size(app.Analysis.PlotDatasetTable,2)+1);
    TableData(:,1) = app.Analysis.PlotDatasetTable(:,1);
    LineMarkers = CustomLineMarkers(numel(app.Analysis.PlotDatasetTable(:,1)));
    TableData(:,2) = LineMarkers;
    TableData(:,3) = app.Analysis.PlotDatasetTable(:,2);
    TableData(:,4) = app.Analysis.PlotDatasetTable(:,3);
    if app.IsPC
        set(app.h.ExperimentalDataTable,'Data',TableData,'ColumnFormatData',{AxesOptions,{},{},{}});   
    else
        set(app.h.ExperimentalDataTable,'Data',TableData,'ColumnFormat',{AxesOptions(:)','char','char','char'});   
    end
    
else
    set(app.h.ExperimentalDataTable,'Data',{});
end


%% Update Group Data table

if ~isempty(app.Analysis.PlotDatasetTable) && ~isempty(app.Analysis.DataToFit)
    
    UniqueGroups = unique(categorical(app.Analysis.DataToFit.(app.Analysis.DatasetTable.Group)),'stable');
    
    TableData = cell(numel(UniqueGroups),4);
    TableData(:,1) = num2cell(app.Analysis.SelectedGroups(:));
    TableData(:,3) = cellfun(@(x)char(x),num2cell(UniqueGroups),'UniformOutput',false);
    TableData(:,4) = app.Analysis.PlotGroupNames(:);
    
    % Loop through and color the second column
    if app.IsPC
        set(app.h.GroupDataTable,'Data',TableData);
        for index = 1:numel(UniqueGroups)
            app.h.GroupDataTable.setCellColor(index,2,app.Analysis.GroupColors(index,:));
        end        
    else
        TableData(:,2) = PKPDViewer.AnalysisApp.getHTMLColor(app.Analysis.GroupColors);
        set(app.h.GroupDataTable,'Data',TableData);
    end
    if ~isempty(app.Analysis.DatasetTable) && ~isempty(app.Analysis.DatasetTable.Group)
        set(app.h.GroupDataTable,'ColumnName',{'Show','Color',app.Analysis.DatasetTable.Group,'Display'});
    else
        set(app.h.GroupDataTable,'ColumnName',{'Show','Color','Group','Display'});
    end
else
    set(app.h.GroupDataTable,'Data',{});
    set(app.h.GroupDataTable,'ColumnName',{'Show','Color','Group','Display'});
end


%% Update legends from PlotSettings

updateLegends(app);


%% Update lines from PlotSettings

updateLines(app);


%% Update context menus

updateContextMenus(app);
                  

%% Update axes layout

updateAxesLayout(app);


%% Profile notes

% Update Species
Species = get(app.Analysis.ModelObj,'Species');
SelectedSpeciesNames = get(app.Analysis.SelectedSpecies,'Name');
MatchIndex = ismember(get(app.Analysis.Species,'Name'),SelectedSpeciesNames);
Species = Species(MatchIndex);

if ~isempty(Species)
    Compartments = get(Species,'Parent');
    if numel(Compartments) == 1
        Compartments = {Compartments};
    end
    CompartmentNames = get(vertcat(Compartments{:}),'Name');
    if ischar(CompartmentNames)
        CompartmentNames = {CompartmentNames};
    end
    SpeciesNames = get(Species,'Name');
    if ischar(SpeciesNames)
        SpeciesNames = {SpeciesNames};
    end
    
    % Append empty
    FullSpeciesNames = cellfun(@(x,y)sprintf('[%s].[%s]',x,y),CompartmentNames,SpeciesNames,'UniformOutput',false);
else
    FullSpeciesNames = {};
end
    
% Visibility
if any(strcmpi(app.Analysis.Task,{'Simulation','Population'})) && app.h.MiddleLayout.Heights(2) == 0
    % Reset it only if Visible is on and Heights(2) is 0
    app.h.MiddleLayout.Heights = [-4 -1];
elseif any(strcmpi(app.Analysis.Task,'Fitting'))
    app.h.MiddleLayout.Heights = [-4 0];
end

% Table
updateProfileNotes(app);

[TableProfileSummary,~,Colors,Visible] = getProfileNotes(app);
NumRuns = size(TableProfileSummary,1);

% Adjust based on task
if strcmpi(app.Analysis.Task,'Simulation')
    ColumnName = {'Run','Color','Description','Show','Export'};
    ColumnEditable = [false false true true true];
    PCColumnFormat = {'char','char','char','boolean','boolean'};
    MacColumnFormat = {'char','char','char','logical','logical'};
else
    ColumnName = {'Run','Color','Description','No. of Simulations','Show','Export'};
    ColumnEditable = [false false true false true true];
    PCColumnFormat = {'char','char','char','integer','boolean','boolean'};
    MacColumnFormat = {'char','char','char','numeric','logical','logical'};
end

if app.IsPC    
    set(app.h.ProfileNotesTable,...
        'ColumnName',ColumnName,... 
        'ColumnEditable',ColumnEditable,...
        'ColumnFormat',PCColumnFormat,... 
        'ColumnFormatData',{{},{},{},{},{}},... 
        'Visible',Visible);
    % Need to set Data and SelectedRows, then set cell color
    for index = 1:NumRuns
        try
            app.h.ProfileNotesTable.setCellColor(index,2,Colors(index,:));
        catch
            % Do nothing - set cell color can fail if a user is editing a
            % widget (i.e. No. of Simulation Runs) and then immediately
            % presses Run
        end 
    end
else
    set(app.h.ProfileNotesTable,...
        'ColumnName',ColumnName,...
        'ColumnEditable',ColumnEditable,... 
        'ColumnFormat',MacColumnFormat,...
        'Visible',Visible);    
end


%% Internal function i_UpdateRecentFiles
function i_UpdateRecentFiles(Parent,FileNames,Callback)
% This internal function updates the File->Open Recent menu entries

% Which files already have a menu item?
hOldItems = get(Parent,'Children');
ExistingItems = get(hOldItems,'UserData');

% Keep track of which existing menu items are matched
ExistingItemsToKeep = false(size(ExistingItems));

% How many menu items should there be?
NumFiles = numel(FileNames);

% Prepare a list of the new menu item handles in correct order
hNewItems = zeros(NumFiles,1);

% Loop on each file and populate the list of menu items
for idx=1:NumFiles
    
    % Does this file already have a menu item?
    ExistingMatch = strcmp(FileNames{idx}, ExistingItems);
    if any( ExistingMatch )
       
       % It does, just grab the handle
       hNewItems(idx) = hOldItems(ExistingMatch); 
       
       % Mark the item to be retained
       ExistingItemsToKeep = ExistingItemsToKeep | ExistingMatch;
       
    else
        
       % It doesn't, create a new menu item
       hNewItems(idx) = uimenu(...
            'Parent',Parent,...
            'Label',FileNames{idx},...
            'UserData',FileNames{idx},...
            'Callback',@(h,e)Callback(FileNames{idx}));
        
    end %if any( ExistingMatch )
    
end %for idx=1:NumFiles

% Remove any menu items that we didn't flag to keep
delete(hOldItems(~ExistingItemsToKeep));

% Now, update the order of the menu items
if ~isequal(hNewItems,hOldItems)
    set(Parent,'Children',hNewItems)
end

% Enable the menu only if entries exist
if isempty(hNewItems)
    set(Parent,'Enable','off')
else
    set(Parent,'Enable','on')
end