classdef (Sealed) AnalysisApp < matlab.mixin.SetGet & UIUtilities.ConstructorAcceptsPVPairs
    % AnalysisApp - Analysis application
    % ---------------------------------------------------------------------
    % Abstract: Instantiates the Analysis application
    %
    % Syntax:
    %           app = PKPDViewer.AnalysisApp
    %           app = PKPDViewer.AnalysisApp('Property','Value',...)
    %
    % PKPDViewer.AnalysisApp Properties:
    %
    % PKPDViewer.AnalysisApp Methods:
    %
    % Examples:
    %  app = PKPDViewer.AnalysisApp()
    
    % Copyright 2017 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: agajjala $
    %   $Revision: 421 $
    %   $Date: 2017-12-07 15:07:04 -0500 (Thu, 07 Dec 2017) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (Constant=true)
        % Info for About dialog
        %RAJ - move into about?
        Name = 'gPKPDSim'
        Revision = '1.1.2';
        RevisionDate = datenum('09/17/2021');
        Logo = which('MW_CSG_Logo.png');
        SupportInfo = '';
    end
    
    properties (SetAccess=protected)
        Figure %figure handle
        
        % UI States
        DataPath = pwd %Last data path
        LastPath = pwd %Last path that was used when opening a file
        RecentFiles = cell(0,1) %List of recent session files
        SelectedIdx %Index of selected data in the analysis
        SelectedData %Data from the selected list item        
        % Information on the current session data
        Analysis = PKPD.Analysis() %The main back end data
        FilePath %The file path of the currently loaded data
        IsDirty = true(0,1) %Indicates modifications have not been saved        
        LastPanelHeights %Last panel height on LHS for use with minimize
        ZoomObj %Zoom object
        PanObj %Pan object
        DataCursorObj %Datacursormode object
        SelectedProfileRow = [] % TMW: temporary field for uitable due to jTable on Mac issue
        SelectedVariantRow = [] % TMW: temporary field for uitable due to jTable on Mac issue
        SelectedSpeciesRow = [] % TMW: temporary field for uitable due to jTable on Mac issue
        SelectedGroupRow = [] % TMW: temporary field for uitable due to jTable on Mac issue
        IsPC = ispc
    end
    
    properties (Dependent=true, SetAccess = private);
        FileName %FileName of the current FilePath
        TitleStr %Title of the application
    end
    
    properties (Dependent=true);
        Position %Position of the window
    end
    
    properties (SetAccess=protected)
        h %internal handles structure
        CurrentViewer %The viewer object that is currently being displayed
        NoParent_ = matlab.graphics.GraphicsPlaceholder.empty(0,0)
        
        PlotSettings = PKPD.PlotSettings.empty(0,1)        
        SimulationPlotIdx = 1:6
        FittingPlotIdx = 7:12
        PopulationPlotIdx = 13:18
        MaxNumPlots = 18
    end
    
    
    %% Constructor and Destructor
    methods (Access = private)
        
        % Constructor
        function app = AnalysisApp(varargin)
            % AnalysisApp % Constructor for PKPDViewer.AnalysisApp
            % -------------------------------------------------------------------------
            % Abstract: Constructs a new PKPDViewer.AnalysisApp
            %
            % Syntax:
            %           app = PKPDViewer.AnalysisApp()
            %           app = PKPDViewer.AnalysisApp('p1',v1,...)
            %
            % Inputs:
            %           Optional property-value pairs for default settings
            %
            % Outputs:
            %           app - PKPDViewer.AnalysisApp appect
            %
            % Examples:
            %           app = PKPDViewer.AnalysisApp();
            %
            
            % Create the base graphics
            app.create();
            
            % Create zoom, pan, datacursormode objects
            app.ZoomObj = zoom(app.Figure);
            app.PanObj = pan(app.Figure);
            app.DataCursorObj = datacursormode(app.Figure);
            
            % Load Preferences
            app.loadPrefs();
            
            % Populate public properties from P-V input pairs
            app.assignPVPairs(varargin{:});
            
            % Create analysis object
            app.Analysis = PKPD.Analysis();
            
            % Refresh the entire view
            app.refresh();
            
            % Now, make the figure visible
            set(app.Figure,'Visible','on')
            
        end %function
        
        
        % Destructor
        function delete(app)
            
            % Is the figure still valid?
            if ishghandle(app.Figure)
                
                % Update the preferences on exit
                app.savePrefs();
                
                % Delete analysis
                delete(app.Analysis);
                
                % Delete the figure window
                delete(app.Figure);
                
            end
            
        end %function
        
        
        function updateLines(app)
            % Axes
            
            switch app.Analysis.Task
                case 'Simulation'
                    
                    % Get settings for simulation
                    Settings = app.PlotSettings(app.SimulationPlotIdx);
                    
                    % Iterate through each axes and turn on SelectedProfileRow
                    if isfield(app.h,'SimulationSpeciesLine') && ~isempty(app.h.SimulationSpeciesLine)
                        for axIndex = 1:size(app.h.SimulationSpeciesLine,2)
                            LineWidth = Settings(axIndex).LineWidth;
                            HighlightLineWidth = Settings(axIndex).HighlightLineWidth;
                            
                            % Un-highlight all
                            hPlots = app.h.SimulationSpeciesLine(:,axIndex);
                            hPlots = horzcat(hPlots{:});
                            hPlots(~ishandle(hPlots)) = [];
                            set(hPlots,...
                                'LineWidth',LineWidth);
                            
                            % Highlight selected row
                            if app.SelectedProfileRow > 0
                                if app.SelectedProfileRow > size(app.h.SimulationSpeciesLine,1)
                                    app.SelectedProfileRow = size(app.h.SimulationSpeciesLine,1);
                                end
                                hPlots = app.h.SimulationSpeciesLine(app.SelectedProfileRow,axIndex);
                                hPlots = horzcat(hPlots{:});
                                hPlots(~ishandle(hPlots)) = [];
                                set(hPlots,...
                                    'LineWidth',HighlightLineWidth);
                            end
                        end
                        
                    end
                    
                    % Dataset line
                    if isfield(app.h,'SimulationDatasetLine') && ~isempty(app.h.SimulationDatasetLine)
                        for axIndex = 1:numel(app.h.SimulationDatasetLine)
                            DataSymbolSize = Settings(axIndex).DataSymbolSize;
                            hPlots = app.h.SimulationDatasetLine(axIndex);
                            hPlots = horzcat(hPlots{:});
                            hPlots(~ishandle(hPlots)) = [];
                            set(hPlots,'MarkerSize',DataSymbolSize);
                        end
                    end
                    
                case 'Fitting'
                    
                    % Get settings for fitting
                    Settings = app.PlotSettings(app.FittingPlotIdx);
                    
                    % Dataset line
                    if isfield(app.h,'FittingSpeciesLine') && ~isempty(app.h.FittingSpeciesLine)
                        hPlots = app.h.FittingSpeciesLine{1};
                    
                        % Apply MarkerSize to 'observed'
                        set(hPlots(strcmpi(get(hPlots,'Tag'),'observed')),'MarkerSize',Settings(1).DataSymbolSize);
                        
                        % Apply LineWidth to 'predicted'
                        set(hPlots(strcmpi(get(hPlots,'Tag'),'predicted')),'LineWidth',Settings(1).LineWidth);                        
                    end
                    
                case 'Population'
                    
                    % Get settings for simulation
                    Settings = app.PlotSettings(app.PopulationPlotIdx);
                    
                    if isfield(app.h,'PopulationSpeciesSummaryLine') && ~isempty(app.h.PopulationSpeciesSummaryLine) && ...
                            isfield(app.h,'PopulationSpeciesSummaryPatch') && ~isempty(app.h.PopulationSpeciesSummaryPatch)
                        for axIndex = 1:size(app.h.PopulationSpeciesSummaryLine,2)
                            LineWidth = Settings(axIndex).LineWidth;
                            HighlightLineWidth = Settings(axIndex).HighlightLineWidth;
                            
                            % Un-highlight all patches
                            hPlots = app.h.PopulationSpeciesSummaryPatch(:,axIndex);
                            hPlots = horzcat(hPlots{:});
                            hPlots(~ishandle(hPlots)) = [];
                            set(hPlots,...
                                'LineWidth',0.5,...
                                'FaceAlpha',0.05);
                            
                            % Un-highlight all lines
                            hPlots = app.h.PopulationSpeciesSummaryLine(:,axIndex);
                            hPlots = horzcat(hPlots{:});
                            hPlots(~ishandle(hPlots)) = [];
                            set(hPlots,...
                                'LineWidth',LineWidth);
                            LineWidth50 = min(LineWidth*1.25,10);
                            set(hPlots(1:3:end),...
                                'LineWidth',LineWidth50); % 50% (All)
                            
                            % Highlight selected row
                            if app.SelectedProfileRow > 0
                                
                                % Highlight selected row - patch
                                if app.SelectedProfileRow > size(app.h.PopulationSpeciesSummaryPatch,1)
                                    app.SelectedProfileRow = size(app.h.PopulationSpeciesSummaryPatch,1);
                                end
                                hPlots = app.h.PopulationSpeciesSummaryPatch(app.SelectedProfileRow,axIndex);
                                hPlots = horzcat(hPlots{:});
                                hPlots(~ishandle(hPlots)) = [];
                                set(hPlots,...
                                    'LineWidth',1,...
                                    'FaceAlpha',0.5);
                                
                                % Highlight selected row - lines
                                hPlots = app.h.PopulationSpeciesSummaryLine(app.SelectedProfileRow,axIndex);
                                hPlots = horzcat(hPlots{:});
                                hPlots(~ishandle(hPlots)) = [];
                                set(hPlots(1:3:end),...
                                    'LineWidth',HighlightLineWidth); % 50% (SelectedProfileRow)
                            end
                        end
                    end
                    
                    
                    % Dataset line
                    if isfield(app.h,'PopulationDatasetLine') && ~isempty(app.h.PopulationDatasetLine)
                        for axIndex = 1:numel(app.h.PopulationDatasetLine)
                            DataSymbolSize = Settings(axIndex).DataSymbolSize;
                            hPlots = app.h.PopulationDatasetLine(axIndex);
                            hPlots = horzcat(hPlots{:});
                            hPlots(~ishandle(hPlots)) = [];
                            set(hPlots,'MarkerSize',DataSymbolSize);
                        end
                    end
            end
        end %function
        
        
        function updateProfileNotes(app)
            % Get selected profile notes
            [TableSummary,TableDetailed,Colors,Visible] = getProfileNotes(app);
            
            % Get selection
            SelectedProfileRow = app.SelectedProfileRow;
            if SelectedProfileRow > size(TableSummary,1)
                SelectedProfileRow = size(TableSummary,1);                
            end
            if SelectedProfileRow < 1
                SelectedProfileRow = 1;
            end
            app.SelectedProfileRow = SelectedProfileRow;
            
            % Populate description
            if ~isempty(TableSummary) && ~isempty(SelectedProfileRow) && SelectedProfileRow ~= 0
                % Column 3
                Description = TableSummary{SelectedProfileRow,3};
            else
                Description = '';
            end
            
            % Update selection and data
            if app.IsPC
                if ~isempty(TableSummary)
                    set(app.h.ProfileNotesTable,...
                        'Data',TableSummary,...
                        'SelectedRows',SelectedProfileRow);
                else
                    set(app.h.ProfileNotesTable,...
                        'Data',TableSummary...
                        );
                end
            else
                if ~isempty(TableSummary)
                    NumRows = size(TableSummary,1);
                    TableSummary(:,2) = PKPDViewer.AnalysisApp.getHTMLColor(Colors(1:NumRows,:));                   
                end
                set(app.h.ProfileNotesTable,...
                    'Data',TableSummary...
                    );
            end
            drawnow;
            
            % Update run # and description on panel
            if ~isempty(Description) && ~isempty(SelectedProfileRow)
                set(app.h.ProfileDetailedPanel,'Title',sprintf('Run %d - %s:',SelectedProfileRow,Description));
            elseif ~isempty(SelectedProfileRow)
                set(app.h.ProfileDetailedPanel,'Title',sprintf('Run %d:',SelectedProfileRow));
            else
                set(app.h.ProfileDetailedPanel,'Title',sprintf('Run N/A:'));
            end
            
            % Set detailed contents
            set(app.h.ProfileDetailedContent,...
                'AllItems',TableDetailed,...
                'Visible',Visible);
        end %function
        
        
        function updateLegends(app)            
            % Axes
            
            hLegend = cell(0,6);
            hLegendChildren = cell(0,6);
            switch app.Analysis.Task
                case 'Simulation'
                    if isfield(app.h,'SimulationAxesLegend')
                        hLegend = app.h.SimulationAxesLegend;
                        hLegendChildren = app.h.SimulationAxesLegendChildren;
                    end
                    Settings = app.PlotSettings(app.SimulationPlotIdx);
                        
                case 'Fitting'
                    if isfield(app.h,'FittingAxesLegend')
                        hLegend = app.h.FittingAxesLegend;
                        hLegendChildren = app.h.FittingAxesLegendChildren;
                    end
                    Settings = app.PlotSettings(app.FittingPlotIdx);
                    
                case 'Population'
                    if isfield(app.h,'PopulationAxesLegend')
                        hLegend = app.h.PopulationAxesLegend;
                        hLegendChildren = app.h.PopulationAxesLegendChildren;
                    end
                    Settings = app.PlotSettings(app.PopulationPlotIdx);
            end
            
            if ~isempty(hLegend)
                for axIndex = 1:numel(Settings)
                    if ~isempty(hLegend{axIndex}) && ishandle(hLegend{axIndex})
                        % Visible, Location
                        hLegend{axIndex}.Visible = Settings(axIndex).LegendVisibility;
                        hLegend{axIndex}.Location = Settings(axIndex).LegendLocation;
                        hLegend{axIndex}.FontSize = Settings(axIndex).LegendFontSize;
                        hLegend{axIndex}.FontWeight = Settings(axIndex).LegendFontWeight;
                        
                        % FontSize, FontWeight
                        ch = hLegendChildren{axIndex};
                        if all(ishandle(ch))
                            for cIndex = 1:numel(ch)
                                if isprop(ch(cIndex),'FontSize')
                                    ch(cIndex).FontSize = Settings(axIndex).LegendFontSize;
                                end
                                if isprop(ch(cIndex),'FontWeight')
                                    ch(cIndex).FontWeight = Settings(axIndex).LegendFontWeight;
                                end
                            end %legend chidlren
                        end %ishandle
                    end %ishandle
                end
            end
            
        end %function
        
        
        function updateContextMenus(app)
            
            % Profile Notes: Display NCA
            if strcmpi(app.Analysis.Task,'Simulation')                
                set(app.h.ProfileNotesTableContextMenu_NCAOn,'Enable','on');
                set(app.h.ProfileNotesTableContextMenu_NCAOff,'Enable','on');
            else
                set(app.h.ProfileNotesTableContextMenu_NCAOn,'Enable','off');
                set(app.h.ProfileNotesTableContextMenu_NCAOff,'Enable','off');
            end

            % Axes
            for axIndex = 1:numel(app.h.MainAxes)
                
                hFigure = ancestor(app.h.MainAxes(axIndex),'Figure');
                
                % Update Y-Scale
                if strcmpi(get(app.h.MainAxes(axIndex),'YScale'),'log')
                    set(app.h.ContextMenu_YScaleLog(axIndex),'Checked','on')
                    set(app.h.ContextMenu_YScaleLinear(axIndex),'Checked','off')
                else
                    set(app.h.ContextMenu_YScaleLinear(axIndex),'Checked','on')
                    set(app.h.ContextMenu_YScaleLog(axIndex),'Checked','off')
                end
                
                % Create legend context menu
                app.h.AxesLegendContextMenu{axIndex} = uicontextmenu('Parent',hFigure);
                app.h.AxesLegendContextMenu_Hide{axIndex} = uimenu(app.h.AxesLegendContextMenu{axIndex},...
                    'Label','Hide',...
                    'Tag','HideLegend',...
                    'Callback',@(h,e)onLegendContextMenu(app,h,e,axIndex));
%                 app.h.AxesLegendContextMenu_Location{axIndex} = uimenu(app.h.AxesLegendContextMenu{axIndex},...
%                     'Label','Location',...
%                     'Tag','LegendLocation');
%                 for lIndex = 1:numel(PKPD.PlotSettings.LegendLocationOptions)
%                     uimenu(app.h.AxesLegendContextMenu_Location{axIndex},...
%                         'Label',PKPD.PlotSettings.LegendLocationOptions{lIndex},...
%                         'Tag',PKPD.PlotSettings.LegendLocationOptions{lIndex},...
%                         'Callback',@(h,e)onLegendContextMenu(app,h,e,axIndex));
%                 end
            end
            
            hLegend = cell(0,6);
            switch app.Analysis.Task
                case 'Simulation'
                    if isfield(app.h,'SimulationAxesLegend')
                        hLegend = app.h.SimulationAxesLegend;
                    end
                    Settings = app.PlotSettings(app.SimulationPlotIdx);
                    hAxes = app.h.MainAxes(app.SimulationPlotIdx);
                    hAxesLegendContextMenu = app.h.AxesLegendContextMenu(app.SimulationPlotIdx);
                        
                case 'Fitting'
                    if isfield(app.h,'FittingAxesLegend')
                        hLegend = app.h.FittingAxesLegend;
                    end
                    Settings = app.PlotSettings(app.FittingPlotIdx);
                    hAxes = app.h.MainAxes(app.FittingPlotIdx);
                    hAxesLegendContextMenu = app.h.AxesLegendContextMenu(app.FittingPlotIdx);
                    
                case 'Population'
                    if isfield(app.h,'PopulationAxesLegend')
                        hLegend = app.h.PopulationAxesLegend;
                    end
                    Settings = app.PlotSettings(app.PopulationPlotIdx);
                    hAxes = app.h.MainAxes(app.PopulationPlotIdx);
                    hAxesLegendContextMenu = app.h.AxesLegendContextMenu(app.PopulationPlotIdx);
            end
            
            % Attach contextmenu
            if ~isempty(hLegend)
                for axIndex = 1:numel(Settings)
                    if ~isempty(hLegend{axIndex}) && ishandle(hLegend{axIndex})
                        hFigure = ancestor(hAxes,'Figure');
                        % Check if un-parented to main UI
                        if ~isempty(hFigure)
                            set(hLegend{axIndex},'UIContextMenu',hAxesLegendContextMenu{axIndex});
                        end
%                         % Select the appropriate one
%                         Ch = get(app.h.AxesLegendContextMenu_Location{axIndex},'Children');
%                         set(Ch,'Checked','off');
%                         Location = get(hLegend{axIndex},'Location');
%                         set(Ch(strcmpi(get(Ch,'Tag'),Location)),'Checked','on');
                    end
                end
            end
        end %function
        
        
        function [TableSummary,TableDetailed,Colors,Visible] = getProfileNotes(app)
            SelectedProfileRow = app.SelectedProfileRow; %#ok<*PROP>
            
            if strcmpi(app.Analysis.Task,'Simulation') && ~isempty(app.Analysis.SimProfileNotes)
                % Get number of runs
                NumRuns = numel(app.Analysis.SimProfileNotes);
                if SelectedProfileRow > NumRuns
                    SelectedProfileRow = NumRuns;
                end
                % Table summary
                TableSummary = {};
                for index = 1:NumRuns
                    TableSummary(end+1,:) = getSummary(app.Analysis.SimProfileNotes(index)); %#ok<AGROW>
                end
                % Append runID
                RunID = num2cell(1:NumRuns)';
                RunID = cellfun(@num2str,RunID,'UniformOutput',false);
                ColorsPlaceholder = cell(NumRuns,1);
                
                TableSummary = [RunID ColorsPlaceholder TableSummary];
                % Detailed
                if isempty(SelectedProfileRow) || SelectedProfileRow == 0
                    TableDetailed = cell(0,2);
                else
                    TableDetailed = getDetailedContent(app.Analysis.SimProfileNotes(SelectedProfileRow));
                end
                % Colors
                Colors = vertcat(app.Analysis.SimProfileNotes.Color);
                % Visible
                Visible = 'on';
            elseif strcmpi(app.Analysis.Task,'Population') && ~isempty(app.Analysis.PopProfileNotes)
                % Get number of runs
                NumRuns = numel(app.Analysis.PopProfileNotes);
                if SelectedProfileRow > NumRuns
                    SelectedProfileRow = NumRuns;
                end
                % Table summary
                TableSummary = {};
                for index = 1:NumRuns
                    TableSummary(end+1,:) = getSummary(app.Analysis.PopProfileNotes(index)); %#ok<AGROW>
                end
                % Append runID
                RunID = num2cell(1:NumRuns)';
                RunID = cellfun(@num2str,RunID,'UniformOutput',false);
                ColorsPlaceholder = cell(NumRuns,1);
                TableSummary = [RunID ColorsPlaceholder TableSummary];
                % Detailed
                if isempty(SelectedProfileRow) || SelectedProfileRow == 0
                    TableDetailed = cell(0,2);
                else
                    TableDetailed = getDetailedContent(app.Analysis.PopProfileNotes(SelectedProfileRow));
                end
                % Colors
                Colors = vertcat(app.Analysis.PopProfileNotes.Color);
                % Visible
                Visible = 'on';
            elseif strcmpi(app.Analysis.Task,'Fitting')
                TableSummary = {};
                TableDetailed = cell(0,2);
                Visible = 'off';
                % Colors
                Colors = [];
            else
                TableSummary = {};
                TableDetailed = cell(0,2);
                Visible = 'on';
                % Colors
                Colors = [];
            end
            app.SelectedProfileRow = SelectedProfileRow;
        end %function
        
        
        function plotHelper(app)
            switch app.Analysis.Task
                case 'Simulation'
                    [app.h.SimulationSpeciesLine,app.h.SimulationDatasetLine,app.h.SimulationAxesLegend,app.h.SimulationAxesLegendChildren] = ...
                        plotSimulation(app.Analysis,app.h.MainAxes(app.SimulationPlotIdx),app.SelectedProfileRow,app.PlotSettings(app.SimulationPlotIdx));
                    refresh(app.h.SimulationPanel);
                    
                case 'Fitting'
                    [app.h.FittingSpeciesLine,app.h.FittingAxesLegend,app.h.FittingAxesLegendChildren] = plotFitting(app.Analysis,app.h.MainAxes(app.FittingPlotIdx),app.PlotSettings(app.FittingPlotIdx));
                    refresh(app.h.FittingPanel);
                    
                case 'Population'
                    [app.h.PopulationSpeciesSummaryLine,app.h.PopulationSpeciesSummaryPatch,app.h.PopulationDatasetLine,app.h.PopulationAxesLegend,app.h.PopulationAxesLegendChildren] = ...
                        plotPopulation(app.Analysis,app.h.MainAxes(app.PopulationPlotIdx),app.SelectedProfileRow,app.PlotSettings(app.PopulationPlotIdx));
                    refresh(app.h.PopulationPanel);
            end
        end %function
                
        
        function printAxesHelper(app,hAxes,SaveFilePath,PlotSettings)
            
            % Print using option
            [~,~,FileExt] = fileparts(SaveFilePath);
                        
            hNewFig = figure('Visible','off');
            set(hNewFig,'Color','white');
            
            % Use current axes to determine which line handles should be
            % used for the legend
            hUIAxes = hAxes(~strcmpi(get(hAxes,'Tag'),'legend'));
            ch = get(hUIAxes,'Children');
            
            % Keep all annotation-on
            hAnn = get(ch,'Annotation');
            if ~iscell(hAnn)
                hAnn = {hAnn};
            end
            hAnn = cellfun(@(x)get(x,'LegendInformation'),hAnn,'UniformOutput',false);
            hAnn = cellfun(@(x)get(x,'IconDisplayStyle'),hAnn,'UniformOutput',false);
            KeepIdxOn = strcmpi(hAnn,'on');
            
            % Remove all UI legend only handles
            ThisTag = get(ch,'Tag');
            if ~iscell(ThisTag)
                ThisTag = {ThisTag};
            end
            KeepExportIdx = ~strcmpi(ThisTag,'ForUILegendOnly');
            
            % Aggregate
            KeepIdx = KeepIdxOn & KeepExportIdx;
            
            % Copy axes to figure
            hNewAxes = copyobj(hAxes,hNewFig);
            
            % Delete the legend from hThisAxes
            delete(hNewAxes(strcmpi(get(hNewAxes,'Tag'),'legend')));
            hNewAxes = hNewAxes(ishandle(hNewAxes));
            
            % Create new plot settings and initialize with values from
            % original plot settings
            NewPlotSettings = PKPD.PlotSettings(hNewAxes);
            Summary = getSummary(PlotSettings);
            set(NewPlotSettings,fieldnames(Summary),struct2cell(Summary)');
            
            % Create a new legend
            OrigLegend = hAxes(strcmpi(get(hAxes,'Tag'),'legend'));
            if ~isempty(OrigLegend)
                hLine = get(hNewAxes,'Children');
                UserData = get(hLine,'UserData');
                if ~iscell(UserData)
                    UserData = {UserData};
                end
                
                % Check if profile
                IsProfile = find(cellfun(@(x)isa(x,'PKPD.Profile'),UserData));
                
                % If profile, update DisplayName using tag
                % (species name), species display name, and run
                % description
                for sIdx = IsProfile(:)'
                    % Species display name
                    Match = strcmpi(hLine(sIdx).Tag,app.Analysis.PlotSpeciesTable(:,2));
                    SpeciesDisplayName = app.Analysis.PlotSpeciesTable{Match,3};
                    % Run Description
                    RunDescription = UserData{sIdx}.Description;
                    % Updated display name
                    hLine(sIdx).DisplayName = sprintf('%s %s',SpeciesDisplayName,RunDescription);                    
                end
                % Format display name
                for idx = 1:numel(hLine)
                    % Replace _ with \_
                    hLine(idx).DisplayName = regexprep(hLine(idx).DisplayName,'_','\\_');
                    % In case there is now a \\_ (if previous formatted in plotting code), replace it with \_
                    hLine(idx).DisplayName = regexprep(hLine(idx).DisplayName,'\\\\_','\\_');
                end
                
                Location = OrigLegend.Location;
                Visible = OrigLegend.Visible;
                FontSize = OrigLegend.FontSize;
                FontWeight = OrigLegend.FontWeight;
                
                % Make current axes and place legend
                axes(hNewAxes);
                hLine = hLine(KeepIdx);
                hLine = flipud(hLine(:));
                [hLegend,hLegendChildren] = legend(hLine);
                % Set the legend - location and visibility
                hLegend.Location = Location;
                hLegend.Visible = Visible;
                hLegend.EdgeColor = 'none';
                
                % Set the fontsize and fontweight
                hLegend.FontSize = FontSize;
                hLegend.FontWeight = FontWeight;
                [hLegendChildren(arrayfun(@(x)isprop(x,'FontSize'),hLegendChildren)).FontSize] = deal(FontSize);
                [hLegendChildren(arrayfun(@(x)isprop(x,'FontWeight'),hLegendChildren)).FontWeight] = deal(FontWeight);
                
                % Fit axes in Figure
                PKPDViewer.AnalysisApp.fixAxesInFigure(hNewFig,[hNewAxes hLegend]);
            else
                % Fit axes in Figure
                PKPDViewer.AnalysisApp.fixAxesInFigure(hNewFig,hNewAxes);
            end
            
            if strcmpi(FileExt,'.fig')
                set(hNewFig,'Visible','on')
                saveas(hNewFig,SaveFilePath);
            else
                if strcmpi(FileExt,'.png')
                    Option = '-dpng';
                elseif strcmpi(FileExt,'.eps')
                    Option = '-depsc';
                else
                    Option = '-dtiff';
                end
                print(hNewFig,Option,SaveFilePath,'-r300')
            end
            
            close(hNewFig)
        end %function
        
    end %methods
    
    
    
    %% Methods in separate files with custom permissions
    
    methods (Access=protected)
        create(app);
    end
    
    
    methods(Static)
        function singleObj = getInstance
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = PKPDViewer.AnalysisApp;
            end
            singleObj = localObj;
        end %function
        
        %% ------------------------------------------------------------------------
        function ColorOrderHTML = getHTMLColor(Colors)
            
            ColorOrderHTML = {};
            % Format the name with color using HTML color
            for index = 1:size(Colors,1)
                ThisColor = Colors(index,:);
                ThisColor8Bit = floor(255*ThisColor);
                FormatStr = '<html><body bgcolor="#%02X%02X%02X" font color="#%02X%02X%02X" align="right">%s%s';
                ColorOrderHTML{end+1} = sprintf(FormatStr,ThisColor8Bit,ThisColor8Bit,repmat('-',1,50)); %#ok<AGROW>
            end
        end %function

        function fixAxesInFigure(hFigure,hAxes)
            % Fixed pixels dimensions for axes
            AxesDestW = 434; % Desired axes width
            AxesDestH = 342; % Desired axes height
            Buffer = 20; % Buffer within figure
            
            % Update main axes
            hMainAxes = hAxes(~strcmpi(get(hAxes,'Tag'),'legend'));
            set(hMainAxes,'Units','pixels');
            set(hMainAxes,'ActivePositionProperty','outerposition')  % needed?
            Position = get(hMainAxes,'Position');            
            set(hMainAxes,'Position',[Position(1:2) AxesDestW AxesDestH]);
            set(hMainAxes,'Units','normalized');
%             OuterPosition = get(hMainAxes,'OuterPosition');
%             set(hMainAxes,'OuterPosition',[0 0 OuterPosition(3:4)]);
            
            % Set Units to be pixels
            MaxW = 0;
            MaxH = 0;
            for index = 1:numel(hAxes)
                hAxes(index).Units = 'pixels';
                ThisPos = get(hAxes(index),'Position');
                if (ThisPos(1)+ThisPos(3)) > MaxW
                    MaxW = ThisPos(1)+ThisPos(3);
                end
                if (ThisPos(2)+ThisPos(4)) > MaxH
                    MaxH = ThisPos(2)+ThisPos(4);
                end
            end
            % Check against OuterPosition
            OuterPosition = get(hMainAxes,'OuterPosition');
            MaxW = max(MaxW,OuterPosition(1)+OuterPosition(3));
            MaxH = max(MaxH,OuterPosition(2)+OuterPosition(4));
            
            % Update main figure            
            set(hFigure,'Position',[50 50 MaxW+Buffer MaxH+Buffer]);
            
            % Set units to normalized
            for index = 1:numel(hAxes)
                set(hAxes(index),'Units','normalized');
            end
            
        end %function
        
    end
    
    
    %% Callbacks
    methods
        
        function onClose(app)
            
            % Default
            StatusOk = true;
            
            % Is it dirty?
            if any(app.IsDirty)
                StatusOk = app.promptToSave();
            end
            
            % Should we still close the app?
            if StatusOk
                % Close the app
                app.delete();
            else
                % Refresh the entire view
                app.refresh();
            end
            
        end %function
        
        
        function onOpen(app,varargin)
            % Close the existing session and open a different one
            
            % varargin{1} may contain a recent file path
            StatusOk = app.open(varargin{:});
            
            % Did the user open a file or cancel?
            if StatusOk
                set(app.Figure,'pointer','watch');
                drawnow;
                
                % Update Analysis
                update(app.Analysis);
                
                % Set to null selection
                app.SelectedIdx = [];
                app.SelectedData = [];
                
                % Save default parameter values
                for index = 1:numel(app.Analysis.SelectedParams)                    
                    saveDefaultValue(app.Analysis.SelectedParams(index));
                end
                
                % Update selected variants
                updateSelectedVariants(app.Analysis);
                
                % Create sim variant only if it doesn't exist, otherwise
                % use as is
                if isempty(app.Analysis.SimVariant)
                    % Apply parameters to simulation variant
                    updateSimVariant(app.Analysis);
                end
                    
                % Update selected parameters props based on SimVariant
                for index = 1:numel(app.Analysis.SelectedParams)                    
                    restoreValueFromVariant(app.Analysis.SelectedParams(index),app.Analysis.ModelObj,app.Analysis.SimVariant);
                end
        
                % Propagate data
                app.h.SimulationPanel.Data = app.Analysis;
                app.h.FittingPanel.Data = app.Analysis;
                app.h.PopulationPanel.Data = app.Analysis;

                % Create
                createParametersLayout(app.h.SimulationPanel);
                createParametersLayout(app.h.PopulationPanel);
                
                % Create species table
                SpeciesNames = get(app.Analysis.SelectedSpecies,'Name');
                if ischar(SpeciesNames)
                    SpeciesNames = {SpeciesNames};
                end

                % Create species table only if empty
                if isempty(app.Analysis.PlotSpeciesTable)
                    app.Analysis.PlotSpeciesTable = cell(numel(SpeciesNames),1);
                    app.Analysis.PlotSpeciesTable(:,2) = SpeciesNames;
                    app.Analysis.PlotSpeciesTable(:,3) = SpeciesNames;
                elseif size(app.Analysis.PlotSpeciesTable,2) == 2
                    % Copy column 3 to column 2
                    app.Analysis.PlotSpeciesTable(:,3) = app.Analysis.PlotSpeciesTable(:,2);
                end
                
                % Update line styles
                updateSpeciesLineStyles(app.Analysis);
                
                % Need to set Task and call update for axes to be valid
                % before setting PlotSettings
                % Update plot settings using settings struct from Analysis
                app.Analysis.Task = 'Simulation';
                updateAxesLayout(app);
                for index = 1:numel(app.Analysis.SimulationPlotSettings)
                    % Copy SimulationPlotSettings into app.PlotSettings
                    Summary = app.Analysis.SimulationPlotSettings(index);
                    pIdx = app.SimulationPlotIdx(index);
                    set(app.PlotSettings(pIdx),fieldnames(Summary),struct2cell(Summary)');
                end
                app.Analysis.Task = 'Fitting';
                updateAxesLayout(app);
                for index = 1:numel(app.Analysis.FittingPlotSettings)
                    % Copy FittingPlotSettings into app.PlotSettings
                    Summary = app.Analysis.FittingPlotSettings(index);
                    pIdx = app.FittingPlotIdx(index);
                    set(app.PlotSettings(pIdx),fieldnames(Summary),struct2cell(Summary)');
                end
                app.Analysis.Task = 'Population';
                updateAxesLayout(app);
                for index = 1:numel(app.Analysis.PopulationPlotSettings)
                    % Copy PopulationPlotSettings into app.PlotSettings
                    Summary = app.Analysis.PopulationPlotSettings(index);
                    pIdx = app.PopulationPlotIdx(index);
                    set(app.PlotSettings(pIdx),fieldnames(Summary),struct2cell(Summary)');
                end                
                
                % Restore to default - Simulation view
                app.Analysis.Task = 'Simulation';
                switch app.Analysis.Task
                    case 'Simulation'
                        app.h.HLayout.Widths = [-1 -2 -1];
                    case 'Fitting'
                        app.h.HLayout.Widths = [-1 -2 0];
                    case 'Population'
                        app.h.HLayout.Widths = [-1 -2 -1];
                end
                
                % Refresh the entire viewer
                app.refresh();
                
                % Update plots and refresh panels
                plotHelper(app);
                
                % Update context menus
                updateContextMenus(app);
                
                % Invoke resize to adjust according to view
                onResize(app,[],[]);
                
                set(app.Figure,'pointer','arrow');
                drawnow;
                
            end
                
        end %function
        
        
        function onWindowButtonDown(app,~,~)
            
            switch get(app.Figure,'SelectionType')
                
                case 'open' % double-click
                    FlagOnPanel = isCursorOverObj(app.Figure,app.h.LeftMainPanel);
                    if FlagOnPanel
                        
                        % Toggle the minimization of this panel
                        app.h.TopLeftBoxPanel.Minimized = ~app.h.TopLeftBoxPanel.Minimized;
                        
                        % Update the display
                        updateLeftLayoutSizes(app);
                        
                        % Invoke resize to adjust according to view
                        onResize(app,[],[]);
                    end
            end
                
        end %function
        
        
        function onImportData(app)
            
            [StatusOk,DatasetTable,DefaultFolder,FlagComputeNCA] = ImportDataset(...
                'DatasetTable',app.Analysis.DatasetTable,...
                'DefaultFolder',app.DataPath,...
                'FlagComputeNCA',app.Analysis.FlagComputeNCA);                
            if StatusOk
                % Update DataPath
                app.DataPath = DefaultFolder;                
                
                % Import data
                importData(app.Analysis,DatasetTable,FlagComputeNCA);
                
                % Mark the app dirty
                app.IsDirty = true;
            
                % Refresh fitting viewer explicitly
                refresh(app.h.FittingPanel);
                
                % Refresh all
                app.refresh();
            end
            
        end %function        
        
        
        function onSave(app)
            
            % Save the analysis
            UseSaveAs = false;
            StatusOk = app.save(UseSaveAs);
            
            % Refresh the entire view
            if StatusOk
                app.refresh();
            end
            
        end %function
        
        
        function onSaveAs(app)
            
            % Save the analysis
            UseSaveAs = true;
            StatusOk = app.save(UseSaveAs);
            
            % Refresh the entire view
            if StatusOk
                app.refresh();
            end
            
        end %function
          
        
        function onExport(app,h,~)
            
            ThisTag = get(h,'Tag');
            
            Title = 'Save as';
            if strcmpi(ThisTag,'ExportFittingToPDF')
                Spec = {...
                    '*.pdf','PDF';...
                    '*.xlsx;*.xls','Excel'
                    };                
            else
                Spec = {...
                    '*.xlsx;*.xls','Excel'
                    };
            end
            
            SaveFilePath = app.LastPath;
            [SaveFileName,SavePathName] = uiputfile(Spec,Title,SaveFilePath);
            if ~isequal(SaveFileName,0)
                SaveFilePath = fullfile(SavePathName,SaveFileName);
                
                StatusOK = true;
                Message = '';
                switch ThisTag
                    
                    case 'ExportSimToExcel'
                        [StatusOK,Message] = export(app.Analysis,SaveFilePath,'Simulation');
                        
                    case 'ExportFittingToExcel'
                        [StatusOK,Message] = export(app.Analysis,SaveFilePath,'Fitting');
                    
                    case 'ExportFittingToPDF'
                        [StatusOK,Message] = export(app.Analysis,SaveFilePath,'FittingSummmary');
                        
                    case 'ExportPopToExcel'
                        [StatusOK,Message] = export(app.Analysis,SaveFilePath,'Population');
                        
                    case 'ExportNCAToExcel'
                        [StatusOK,Message] = export(app.Analysis,SaveFilePath,'NCA');
                end
                
                if ~StatusOK
                    Title = 'Export Failed';
                    hDlg = errordlg(Message,Title,'modal');
                    uiwait(hDlg);
                end
            end
        end %function
        
        
        function onEditPlotSettings(app)
            
            % Non-traditional: CustomizePlots updates handles directly, so removed
            % 'Cancel' option. StatusOk is always true, and use of
            % NewSettings is unnecessary.
            switch app.Analysis.Task
                
                case 'Simulation'
                    % TODO: Update app.PlotSettings? Set hLegend,
                    % hLegendChildren, hLines? Make dependent
                    
                    [StatusOk,NewSettings] = CustomizePlots(...
                        'Settings',app.PlotSettings(app.SimulationPlotIdx));                    
                    if StatusOk
                        % Mark the app dirty
                        app.IsDirty = true;
                        app.PlotSettings(app.SimulationPlotIdx) = NewSettings;                        
                    end
                    
                case 'Fitting'
                    
                    % Only first of the FittingPlotIdx is actually used
                    [StatusOk,NewSettings] = CustomizePlots(...
                        'Settings',app.PlotSettings(app.FittingPlotIdx(1)));
                    if StatusOk
                        % Mark the app dirty
                        app.IsDirty = true;
                        app.PlotSettings(app.FittingPlotIdx(1)) = NewSettings;
                    end
                    
                case 'Population'
                    
                    [StatusOk,NewSettings] = CustomizePlots(...
                        'Settings',app.PlotSettings(app.PopulationPlotIdx));   
                    if StatusOk
                        % Mark the app dirty
                        app.IsDirty = true;
                        app.PlotSettings(app.PopulationPlotIdx) = NewSettings;
                    end
            end
            
            % Update the display
            app.update();
            
        end %function
        
        
        function onEditAnalysis(app,h,~)
            
            set(app.Figure,'pointer','watch');
            drawnow;
            
            ThisTag = get(get(h,'SelectedObject'),'Tag');
            
            % Assign the task
            app.Analysis.Task = ThisTag;
            
            switch ThisTag
                case 'Simulation'
                    app.h.HLayout.Widths = [-1 -2 -1];
                case 'Fitting'
                    app.h.HLayout.Widths = [-1 -2 0];
                case 'Population'
                    app.h.HLayout.Widths = [-1 -2 -1];
            end
            
            % Update the display
            app.refresh();
            
            % Update plots and refresh panels
            plotHelper(app);
            switch ThisTag
                case 'Simulation'
                    app.h.HLayout.Widths = [-1 -2 -1];
                case 'Fitting'
                    app.h.HLayout.Widths = [-1 -2 0];
                case 'Population'
                    app.h.HLayout.Widths = [-1 -2 -1];
            end
            
            % Update context menus
            updateContextMenus(app);                
            
            set(app.Figure,'pointer','arrow');
            drawnow;
            
            
        end %function

        
        function onDataChanged(app,~,~)
            
            % Mark the app dirty
            app.IsDirty = true;
            
            % Update the display
            app.refresh();
            
        end %function
        
        
        function onRunAnalysis(app)
            
            set(app.Figure,'Pointer','watch');
            drawnow;
            
            % Run the analysis
            [StatusOk,Message] = app.Analysis.run();
                
            % Display error
            if ~StatusOk
                Title = 'Run Analysis Failed';
                hDlg = errordlg(Message,Title,'modal');
                uiwait(hDlg);
            end
            
            switch app.Analysis.Task
                case 'Simulation'
                    app.SelectedProfileRow = numel(app.Analysis.SimProfileNotes);
                case 'Population'
                    app.SelectedProfileRow = numel(app.Analysis.PopProfileNotes);
            end
            
            % Update plots and refresh panels
            plotHelper(app);   
            
            % Update the display
            app.update();
  
            set(app.Figure,'Pointer','arrow');
            drawnow;
            
        end %function
        
        
        function onGenerateReport(app)
            
            % Was an analysis selection given?
            
            % Generate the report
            try
                app.Analysis.genReport();
            catch err
                Message = sprintf('Generate Report Failed. Error:\n%s',err.message);
                Title = 'Generate Report';
                hDlg = errordlg(Message,Title,'modal');
                uiwait(hDlg);
            end
            
        end %function
        
        
        function onUserGuide(~)
            
            hDlg = msgbox('User Guide not currently available','WindowStyle','modal');
            uiwait(hDlg);
            
        end %function
        

        function onAbout(app)
            
            % Open the about dialog
            UIUtilities.AboutDialog(app.Name,app.Revision, app.RevisionDate,app.Logo,app.SupportInfo);
            
        end %function
        
        
        function onToggleTool(app,h,~)
            
            switch get(h,'Tag')
                case 'ToggleToolPan'
                    % Turn off zoom/explore
                    set(app.h.ZoomInToggleTool,'State','off');
                    set(app.h.ZoomOutToggleTool,'State','off'); 
                    
                    % Turn off zoom
                    set(app.ZoomObj,'Enable','off');
                    % Turn off datacursormode
                    set(app.DataCursorObj,'Enable','off');
                    
                    % Current value
                    if strcmpi(get(h,'State'),'on')
                        set(app.PanObj,'Enable','on');% Turn on
                    else
                        set(app.PanObj,'Enable','off'); % Turn off
                    end
                    
                case 'ToggleToolZoomIn'
                    % Turn off pan/explore/zoom out
                    set(app.h.PanToggleTool,'State','off');
                    set(app.h.ZoomOutToggleTool,'State','off');
                    
                    % Turn off pan
                    set(app.PanObj,'Enable','off');
                    % Turn off datacursormode
                    set(app.DataCursorObj,'Enable','off');
                    
                    % Current value
                    if strcmpi(get(h,'State'),'on')
                        set(app.ZoomObj,'Enable','on','Direction','in');
                    else
                        % Set blocking to be false before turning Enable off
                        set(app.ZoomObj,'Enable','off');
                    end
                    
                case 'ToggleToolZoomOut'
                    % Turn off pan/explore/zoom in
                    set(app.h.PanToggleTool,'State','off');
                    set(app.h.ZoomInToggleTool,'State','off');
                    
                    % Turn off pan
                    set(app.PanObj,'Enable','off');
                    % Turn off datacursormode
                    set(app.DataCursorObj,'Enable','off');
                    
                    % Current value
                    if strcmpi(get(h,'State'),'on')
                        set(app.ZoomObj,'Enable','on','Direction','out');
                    else
                        % Set blocking to be false before turning Enable off
                        set(app.ZoomObj,'Enable','off');
                    end
                    
                case 'ToggleToolExplore'
                    
                    % Turn off zoom
                    set(app.ZoomObj,'Enable','off'); % Turn off
                    % Turn off pan
                    set(app.PanObj,'Enable','off');
                    
                    % Current value
                    if strcmpi(get(h,'State'),'on')
                        set(app.DataCursorObj,'Enable','on');
                    else
                        set(app.DataCursorObj,'Enable','off');
                    end
                    
                    % Turn off pan/zoom in/zoom out
                    set(app.h.PanToggleTool,'State','off');
                    set(app.h.ZoomInToggleTool,'State','off');
                    set(app.h.ZoomOutToggleTool,'State','off');
            end
        end %function
        
        function onVariantTableSelection(app,~,e)            
            % On selection variant table (uitable only)
            
            if ~isempty(e) && (isfield(e,'Indices') || isprop(e,'Indices')) && numel(e.Indices) >= 1
                app.SelectedVariantRow = e.Indices(1); % Temporary
            end
        end
        
        function onVariantTableEdited(app,h,e)            
            % On editing variant table
            
            % Which control was changed
            TableData = get(h,'Data');
            
            Active = TableData(:,1);
            Order = cellfun(@str2double,TableData(:,2));
            
            % TODO: Finish - remove usage of 'Active' flag
            VariantNames = app.Analysis.SelectedVariantNames;
            if ~isempty(app.Analysis.ModelObj)
                % Set the variant characteristics
                
                % Update order
                if ~isempty(e) && (isfield(e,'Indices') || isprop(e,'Indices')) && numel(e.Indices) >= 1
                    % Replace the unassigned index
                    KeepElementIndex = e.Indices(1);
                    ReplaceElementIndex = find(Order == Order(KeepElementIndex));
                    ReplaceElementIndex = ReplaceElementIndex(ReplaceElementIndex ~= KeepElementIndex);
                    Elements = (1:numel(app.Analysis.SelectedVariantNames))';
                    MissingElement = Elements(~ismember(Elements,Order));
                    Order(ReplaceElementIndex) = MissingElement;
                end
                app.Analysis.SelectedVariantsOrder = Order;
                
                % Next, set active flag
                for index = 1:numel(VariantNames)
                    set(app.Analysis.SelectedVariants(index),'Active',Active{index});
                end      
                
                % Update selected parameters props based on selected model
                % and variants
                OrderedVariants = app.Analysis.SelectedVariants;
                OrderedVariants(app.Analysis.SelectedVariantsOrder) = app.Analysis.SelectedVariants;
                IsSelected = get(OrderedVariants,'Active');
                if iscell(IsSelected)
                    IsSelected = cell2mat(IsSelected);
                end                
                OrderedVariants = OrderedVariants(IsSelected);
                for index = 1:numel(app.Analysis.SelectedParams)
                    restoreValueFromVariant(app.Analysis.SelectedParams(index),app.Analysis.ModelObj,OrderedVariants);
                end
                
                % Apply parameters to simulation variant
                updateSimVariant(app.Analysis);
            end
            
            app.IsDirty = true;
            
            % Refresh the entire viewer
            app.refresh();
            
            refresh(app.h.SimulationPanel)
            refresh(app.h.FittingPanel)
            refresh(app.h.PopulationPanel)
            
        end %function
        
        
        function onVariantTableContextMenu(app,h,~)
            % On clicking context menu on variant table
            
            % Which control was changed
            ControlName = get(h,'Tag');
            
            switch ControlName
                
                case 'VariantDelete'
                    if isa(app.h.VariantTable,'uiextras.jTable.Table')
                        Row = get(app.h.VariantTable,'SelectedRows');
                    else
                        Row = app.SelectedVariantRow;
                    end
                    
                    % Only allow deletion of custom
                    if ~isempty(Row) && strcmpi(get(app.Analysis.SelectedVariants(Row),'Tag'),'custom')
                        % Remove variant
                        removeVariant(app.Analysis,Row);
                        
                        % Update selected parameters props based on selected model
                        % and variants
                        OrderedVariants = app.Analysis.SelectedVariants;
                        OrderedVariants(app.Analysis.SelectedVariantsOrder) = app.Analysis.SelectedVariants;
                        IsSelected = get(OrderedVariants,'Active');
                        if iscell(IsSelected)
                            IsSelected = cell2mat(IsSelected);
                        end                        
                        OrderedVariants = OrderedVariants(IsSelected);
                        for index = 1:numel(app.Analysis.SelectedParams)
                            restoreValueFromVariant(app.Analysis.SelectedParams(index),app.Analysis.ModelObj,OrderedVariants);
                        end
                        
                        % Apply parameters to simulation variant
                        updateSimVariant(app.Analysis);
                    else
                        Message = sprintf('Unable to delete variant %s. Variant must be of custom type.',app.Analysis.SelectedVariants(Row).Name);
                        Title = 'Delete Variant';
                        hDlg = errordlg(Message,Title,'modal');
                        uiwait(hDlg);
                    end
            end
            
            app.IsDirty = true;
            
            % Refresh the entire viewer
            app.refresh();
            
            refresh(app.h.SimulationPanel);
            refresh(app.h.FittingPanel);
            refresh(app.h.PopulationPanel);
            
        end %function
        
        
        function onDosingTableEdited(app,h,e)
            % On editing dosing table
            
            % Which control was changed
            TableData = get(h,'Data');
            
            FlagChanged = false;
            
            if ~isempty(e) && (isfield(e,'Indices') || isprop(e,'Indices')) && numel(e.Indices) > 1 % Need row AND column (2 indices)
                % Validate value
                Row = e.Indices(1);
                Col = e.Indices(2);
                
                try
                    switch Col
                        case 1
                            % Active
                            if ~isequal(TableData{Row,Col},app.Analysis.SelectedDoses(Row).Active)
                                FlagChanged = true;
                                app.Analysis.SelectedDoses(Row).Active = TableData{Row,Col};
                            end                            
                        case 5
                            % StartTime
                            if ~isequal(TableData{Row,Col},app.Analysis.SelectedDoses(Row).StartTime)
                                FlagChanged = true;
                                app.Analysis.SelectedDoses(Row).StartTime = TableData{Row,Col};
                            end
                        case 7
                            % Amount
                            if ~isequal(TableData{Row,Col},app.Analysis.SelectedDoses(Row).Amount)
                                FlagChanged = true;
                                app.Analysis.SelectedDoses(Row).Amount = TableData{Row,Col};
                            end
                        case 9
                            % Interval
                            if ~isequal(TableData{Row,Col},app.Analysis.SelectedDoses(Row).Interval)
                                FlagChanged = true;
                                app.Analysis.SelectedDoses(Row).Interval = TableData{Row,Col};
                            end                            
                        case 10
                            % Rate
                            if ~isequal(TableData{Row,Col},app.Analysis.SelectedDoses(Row).Rate)
                                FlagChanged = true;
                                app.Analysis.SelectedDoses(Row).Rate = TableData{Row,Col};
                            end                            
                        case 11
                            % RepeatCount
                            if ~isequal(TableData{Row,Col},app.Analysis.SelectedDoses(Row).RepeatCount)
                                FlagChanged = true;
                                app.Analysis.SelectedDoses(Row).RepeatCount = TableData{Row,Col};
                            end                            
                    end
                catch err
                    Message = sprintf('Unable to change %s table: \n%s','dosing',err.message);
                    Title = 'Dosing Table';
                    hDlg = errordlg(Message,Title,'modal');
                    uiwait(hDlg);
                    FlagChanged = true;
                end
            end
            
            if FlagChanged
                
                app.IsDirty = true;
                
                % Refresh the entire viewer
                app.refresh();
            end
            
        end %function
        
        
        function onProfileNotesTableEdited(app,h,e)
            
            app.IsDirty = true;
            
            % Get the selected row
            if isa(h,'uiextras.jTable.Table')
                SelectedRow = get(h,'SelectedRows');
            else
                SelectedRow = app.SelectedProfileRow;
            end
            
            % Get data
            ThisData = get(h,'Data');
            
            if ~isempty(e) && ~isempty(SelectedRow)
                switch app.Analysis.Task
                    case 'Simulation'
                        if e.Indices(2) == 3
                            ThisCell = ThisData{SelectedRow,3};
                            if isempty(ThisCell)
                                ThisCell = '';
                            end
                            app.Analysis.SimProfileNotes(SelectedRow).Description = ThisCell;                            
                        elseif e.Indices(2) == 4
                            % Temporarily disable ColumnEditable to prevent
                            % user from clicking 'Display' uncheckboxes
                            % repeatedly
                            hFigure = ancestor(h,'Figure');
                            set(hFigure,'pointer','watch');
                            drawnow;
                            
                            ColumnEditable = get(h,'ColumnEditable');
                            ColumnEditable(4) = false;
                            set(h,'ColumnEditable',ColumnEditable);
                            
                            app.Analysis.SimProfileNotes(SelectedRow).Show = ThisData{SelectedRow,4};
                            updateProfileNotes(app);
                            [app.h.SimulationSpeciesLine,app.h.SimulationDatasetLine,app.h.SimulationAxesLegend,app.h.SimulationAxesLegendChildren] = ...
                                plotSimulation(app.Analysis,app.h.MainAxes(app.SimulationPlotIdx),app.SelectedProfileRow,app.PlotSettings(app.SimulationPlotIdx));
                            refresh(app.h.SimulationPanel);

                            % Re-enable
                            ColumnEditable(4) = true;
                            set(h,'ColumnEditable',ColumnEditable);
                            
                            set(hFigure,'pointer','arrow');
                            drawnow;
                        elseif e.Indices(2) == 5
                            app.Analysis.SimProfileNotes(SelectedRow).Export = ThisData{SelectedRow,5};                        
                        end
                    case 'Population'
                        if e.Indices(2) == 3
                            ThisCell = ThisData{SelectedRow,3};
                            if isempty(ThisCell)
                                ThisCell = '';
                            end
                            app.Analysis.PopProfileNotes(SelectedRow).Description = ThisCell;                            
                        elseif e.Indices(2) == 5
                            % Temporarily disable ColumnEditable to prevent
                            % user from clicking 'Display' uncheckboxes
                            % repeatedly
                            hFigure = ancestor(h,'Figure');
                            set(hFigure,'pointer','watch');
                            drawnow;
                            
                            ColumnEditable = get(h,'ColumnEditable');
                            ColumnEditable(5) = false;
                            set(h,'ColumnEditable',ColumnEditable);
                            
                            app.Analysis.PopProfileNotes(SelectedRow).Show = ThisData{SelectedRow,5};
                            updateProfileNotes(app);
                            [app.h.PopulationSpeciesSummaryLine,app.h.PopulationSpeciesSummaryPatch,app.h.PopulationDatasetLine,app.h.PopulationAxesLegend,app.h.PopulationAxesLegendChildren] = ...
                                plotPopulation(app.Analysis,app.h.MainAxes(app.PopulationPlotIdx),app.SelectedProfileRow,app.PlotSettings(app.PopulationPlotIdx));
                            refresh(app.h.PopulationPanel);  

                            % Re-enable
                            ColumnEditable(5) = true;
                            set(h,'ColumnEditable',ColumnEditable);

                            set(hFigure,'pointer','arrow');
                            drawnow;
                        elseif e.Indices(2) == 6
                            app.Analysis.PopProfileNotes(SelectedRow).Export = ThisData{SelectedRow,6};                                                    
                        end
                end
            end
            
        end %function
        
        
        function onProfileNotesTableSelected(app,~,e)
            if ~isempty(e) && (isfield(e,'Indices') || isprop(e,'Indices')) 
                if numel(e.Indices) >= 1
                    app.SelectedProfileRow = e.Indices(1); % Temporary                
                else
                    app.SelectedProfileRow = [];
                end
            end
                
            % Update the display
            updateLines(app);
            updateProfileNotes(app);
            
        end %function
        
        
        function onProfileNotesTableContextMenu(app,h,~)
            
            % Get the selected row
            if isa(app.h.SpeciesDataTable,'uiextras.jTable.Table')
                SelectedRow = get(app.h.ProfileNotesTable,'SelectedRows');
            else
                SelectedRow = app.SelectedProfileRow;
            end

            if strcmpi(app.Analysis.Task,'Simulation')
                ThisProfileNotes = app.Analysis.SimProfileNotes;
            elseif strcmpi(app.Analysis.Task,'Population')
                ThisProfileNotes = app.Analysis.PopProfileNotes;
            else
                ThisProfileNotes = PKPD.Profile.empty(0,1);
            end
                
            switch get(h,'Tag')
                case 'SetColor'
                    if ~isempty(SelectedRow) && strcmpi(app.Analysis.Task,'Simulation') 
                        
                        ThisColor = ThisProfileNotes(SelectedRow).Color;                        
                        NewColor = uisetcolor(ThisColor);
                        
                        if ~isequal(NewColor,0)
                            ThisProfileNotes(SelectedRow).Color = NewColor;                            
                            [app.h.SimulationSpeciesLine,app.h.SimulationDatasetLine,app.h.SimulationAxesLegend,app.h.SimulationAxesLegendChildren] = ...
                                plotSimulation(app.Analysis,app.h.MainAxes(app.SimulationPlotIdx),app.SelectedProfileRow,app.PlotSettings(app.SimulationPlotIdx));
                            refresh(app.h.SimulationPanel);
                        end
                        
                    elseif ~isempty(SelectedRow) && strcmpi(app.Analysis.Task,'Population')
                        
                        ThisColor = ThisProfileNotes(SelectedRow).Color;                        
                        NewColor = uisetcolor(ThisColor);                     
                        
                        if ~isequal(NewColor,0)
                            ThisProfileNotes(SelectedRow).Color = NewColor;   
                            [app.h.PopulationSpeciesSummaryLine,app.h.PopulationSpeciesSummaryPatch,app.h.PopulationDatasetLine,app.h.PopulationAxesLegend,app.h.PopulationAxesLegendChildren] = ...
                                plotPopulation(app.Analysis,app.h.MainAxes(app.PopulationPlotIdx),app.SelectedProfileRow,app.PlotSettings(app.PopulationPlotIdx));
                            refresh(app.h.PopulationPanel);
                        end
                        
                    elseif isempty(SelectedRow)
                        Title = 'No row selected';
                        Message = 'A row must be selected in order to change species color.';
                        hDlg = warndlg(Message,Title,'modal');
                        uiwait(hDlg);
                    end
                    
                case 'DeleteSelectedRun'
                    
                    if ~isempty(SelectedRow)
                        if strcmpi(app.Analysis.Task,'Simulation')
                            if numel(app.Analysis.SimProfileNotes) > 1
                                delete(app.Analysis.SimProfileNotes(SelectedRow));
                                app.Analysis.SimProfileNotes(SelectedRow) = [];
                            else
                                delete(app.Analysis.SimProfileNotes(SelectedRow));
                                app.Analysis.SimProfileNotes = PKPD.Profile.empty(0,1);
                            end
                            app.Analysis.SimData(SelectedRow) = [];
                        elseif strcmpi(app.Analysis.Task,'Population')
                            if numel(app.Analysis.PopProfileNotes) > 1
                                delete(app.Analysis.PopProfileNotes(SelectedRow));                            
                                app.Analysis.PopProfileNotes(SelectedRow) = [];
                                app.Analysis.PopSummaryData(SelectedRow,:) = [];
                            else
                                delete(app.Analysis.PopProfileNotes(SelectedRow));                            
                                app.Analysis.PopProfileNotes = PKPD.Profile.empty(0,1);
                                app.Analysis.PopSummaryData = PKPD.PopulationSummary.empty(0,0);
                            end
                            
                        end    
                        app.SelectedProfileRow = app.SelectedProfileRow-1;
                        
                        % Update plots and refresh panels
                        plotHelper(app);
                    end
                    
                case 'DeleteAllRuns'
                    
                    % Prompt the user
                    Prompt = sprintf('Are you sure you want to delete all runs?');
                    Result = questdlg(Prompt,'Delete All','Yes','Cancel','Yes');
                    
                    % How did the user respond?
                    if strcmpi(Result,'Yes')                        
                        if strcmpi(app.Analysis.Task,'Simulation')
                            delete(app.Analysis.SimProfileNotes);
                            app.Analysis.SimProfileNotes = PKPD.Profile.empty(0,1);
                            app.Analysis.SimData = [];
                        elseif strcmpi(app.Analysis.Task,'Population')
                            delete(app.Analysis.PopProfileNotes);
                            app.Analysis.PopProfileNotes = PKPD.Profile.empty(0,1);
                            app.Analysis.PopSummaryData = PKPD.PopulationSummary.empty(0,0);
                        end
                        app.SelectedProfileRow = 0;
                        
                        % Update plots and refresh panels
                        plotHelper(app);
                    end
                    
                case 'ToggleShowOn'
                    [ThisProfileNotes.Show] = deal(true);
                    % Update plots and refresh panels
                    plotHelper(app);
                    
                case 'ToggleShowOff'
                    [ThisProfileNotes.Show] = deal(false);
                    % Update plots and refresh panels
                    plotHelper(app);
                    
                case 'ToggleExportOn'
                    [ThisProfileNotes.Export] = deal(true);
                case 'ToggleExportOff'
                    [ThisProfileNotes.Export] = deal(false);
                case 'ToggleNCAOn'
                    [ThisProfileNotes.NCA] = deal(true);
                case 'ToggleNCAOff'
                    [ThisProfileNotes.NCA] = deal(false);
            end
                
            % Update the display
            app.update();
            
        end %function
        
        
        function onSelectPlotOverlay(app,h,~)
            Value = get(h,'Value');
            
            if strcmpi(app.Analysis.Task,'Simulation')
                app.Analysis.FlagSimOverlay = logical(Value);
                
            elseif strcmpi(app.Analysis.Task,'Population')
                app.Analysis.FlagPopOverlay = logical(Value);
            end
            
            % Applied during next run - no need to update plots
        end %function
        
        
        function onSelectPlotLayout(app,h,~)
            Value = get(h,'Value');
            app.Analysis.SelectedPlotLayout = app.Analysis.PlotLayoutOptions{Value};
            
            % Update the display
            app.refresh();
            
        end %function
        
        
        function onAxesContextMenu(app,h,~,axIndex)
            
            ThisTag = get(h,'Tag');
            
            switch ThisTag
                case 'YScaleLinear'
                    set(app.h.MainAxes(axIndex),'YScale','linear');
                case 'YScaleLog'
                    set(app.h.MainAxes(axIndex),'YScale','log');
                case 'ExportSingleAxes'
                    % Prompt the user for a filename
                    Spec = {...
                        '*.png','PNG';
                        '*.tif;*.tiff','TIFF';...
                        '*.eps','EPS';...
                        '*.fig','MATLAB Figure';...
                        };
                    Title = 'Save as';
                    SaveFilePath = app.LastPath;
                    [SaveFileName,SavePathName] = uiputfile(Spec,Title,SaveFilePath);
                    if ~isequal(SaveFileName,0)
                        
                        SaveFilePath = fullfile(SavePathName,SaveFileName);
                        ThisAxes = get(app.h.MainAxesContainer(axIndex),'Children');
                        
                        % Temporarily disable selection for printing
                        SelectedRow = app.SelectedProfileRow;
                        app.SelectedProfileRow = [];
                        updateLines(app);
                        
                        % Call helper to copy axes, format, and print
                        printAxesHelper(app,ThisAxes,SaveFilePath,app.PlotSettings(axIndex))
                        
                        % Restore SelectedRow
                        app.SelectedProfileRow = SelectedRow;
                        updateLines(app);
                        
                    end %if
                    
                case 'ExportAllAxes'
                    % Prompt the user for a filename
                     Spec = {...
                        '*.png','PNG';
                        '*.tif;*.tiff','TIFF';...
                        '*.eps','EPS';...
                        '*.fig','MATLAB Figure'...
                        };
                    Title = 'Save as';
                    SaveFilePath = app.LastPath;
                    [SaveFileName,SavePathName] = uiputfile(Spec,Title,SaveFilePath);
                    if ~isequal(SaveFileName,0)
                        
                        % Print using option
                        [~,~,FileExt] = fileparts(SaveFileName);
                        
                        % Get children and remove not-shown axes
                        Ch = flip(get(app.h.PlotGrid,'Children'));                        
                        
                        if isequal(app.h.PlotGrid.Heights(:)',-1) && isequal(app.h.PlotGrid.Widths(:)',[-1 0 0 0 0 0])
                            % 1x1
                            Ch = Ch(1);                            
                        elseif isequal(app.h.PlotGrid.Heights(:)',[-1 -1]) && isequal(app.h.PlotGrid.Widths(:)',[-1 0 0])
                            % 2x1
                            Ch = Ch(1:2);                            
                        elseif isequal(app.h.PlotGrid.Heights(:)',[-1 -1]) && isequal(app.h.PlotGrid.Widths(:)',[-1 -1 0])
                            % 2x2
                            Ch = Ch(1:4);
                        elseif isequal(app.h.PlotGrid.Heights(:)',[-1 -1 -1]) && isequal(app.h.PlotGrid.Widths(:)',[-1 -1])
                            % 3x2
                            Ch = Ch(1:6);
                        end
                        
                        for index = 1:numel(Ch)
                        
                            % Append _# to file name
                            [~,BaseSaveFileName] = fileparts(SaveFileName);
                            SaveFilePath = fullfile(SavePathName,[BaseSaveFileName,'_',num2str(index),FileExt]);
                            
                            ThisAxes = get(Ch(index),'Children');
                        
                            % Temporarily disable selection for printing
                            SelectedRow = app.SelectedProfileRow;
                            app.SelectedProfileRow = [];
                            updateLines(app);
                            
                            % Call helper to copy axes and format
                            printAxesHelper(app,ThisAxes,SaveFilePath,app.PlotSettings(index))
                            
                            % Restore SelectedRow
                            app.SelectedProfileRow = SelectedRow;
                            updateLines(app);
                        end % for
                    end %if
            end %switch
            
            % Update the display
            app.refresh();
            
        end %function
        
        
        function onSpeciesTableSelection(app,~,e)            
            % On selection variant table (uitable only)
            
            if ~isempty(e) && (isfield(e,'Indices') || isprop(e,'Indices')) && numel(e.Indices) >= 1
                app.SelectedSpeciesRow = e.Indices(1); % Temporary
            end
        end
        
        
        function onSpeciesDataTableEdited(app,h,e)
            
            % Update species data
            Data = get(h,'Data');
            
            if ~isempty(e) && (isfield(e,'Indices') || isprop(e,'Indices')) && numel(e.Indices) >= 1
                Row = e.Indices(1);
                Col = e.Indices(2);
            else
                Row = app.SelectedSpeciesRow;
                Col = [];
            end
                
            
            % Only update if data has changed
            if ~isequal(app.Analysis.PlotSpeciesTable,[Data(:,1) Data(:,3) Data(:,4)]) || ...
                    Col == 2
                
                if ~isempty(Row) && Col == 2
                    NewLineStyle = Data{Row,2};
                    setSpeciesLineStyles(app.Analysis,Row,NewLineStyle);
                end
                app.Analysis.PlotSpeciesTable = [Data(:,1) Data(:,3) Data(:,4)];
                
                % Update plots and refresh panels
                plotHelper(app);
                
                % Update the display
                app.refresh();
            end
            
        end %function
        
                
        function onExperimentalDataTableEdited(app,h,~)
            
            % Update species data
            Data = get(h,'Data');
            app.Analysis.PlotDatasetTable = [Data(:,1) Data(:,3) Data(:,4)];
            
            % Update plots and refresh panels
            plotHelper(app);
            
            % Update the display
            app.refresh();
            
        end %function
        
        
        function onLegendContextMenu(app,h,~,axIndex)
            
            ThisTag = get(h,'Tag');
            
            switch ThisTag
                case 'HideLegend'
                    app.PlotSettings(axIndex).LegendVisibility = 'off';
                    
%                 case PKPD.PlotSettings.LegendLocationOptions
%                     % Else, assume it is for Legend Location
%                     app.PlotSettings(axIndex).LegendLocation = ThisTag;
            end
            
            % Update the display
            updateLegends(app);
            updateContextMenus(app);
            
        end %function
        
        
        function onGroupTableEdited(app,h,~)
            
            % Update species data
            Data = get(h,'Data');
            app.Analysis.SelectedGroups = cell2mat(Data(:,1));
            app.Analysis.PlotGroupNames = Data(:,4);
            
            % Update plots and refresh panels
            plotHelper(app);
            
            % Update the display
            app.refresh();
            
        end %function
        
        
        function onGroupTableSelection(app,~,e)            
            % On selection variant table (uitable only)
            
            if ~isempty(e) && (isfield(e,'Indices') || isprop(e,'Indices')) && numel(e.Indices) >= 1
                app.SelectedGroupRow = e.Indices(1); % Temporary
            end
        end %function
        
        
        function onGroupTableContextMenu(app,~,~)
            
            % Get the selected row
            if isa(app.h.GroupDataTable,'uiextras.jTable.Table')
                SelectedRow = get(app.h.GroupDataTable,'SelectedRows');
            else
                SelectedRow = app.SelectedGroupRow;
            end
            
            if ~isempty(app.Analysis.GroupColors) && ~isempty(SelectedRow)
                ThisColor = app.Analysis.GroupColors(SelectedRow,:);
                
                NewColor = uisetcolor(ThisColor);
                
                if ~isequal(NewColor,0)
                    setGroupColors(app.Analysis,SelectedRow,NewColor);
                    
                    % Update plots and refresh panels
                    plotHelper(app);
                    
                    % Update the display
                    app.refresh();
                end
            elseif isempty(SelectedRow)
                Title = 'No row selected';
                Message = 'A row must be selected in order to change group color.';
                hDlg = warndlg(Message,Title,'modal');
                uiwait(hDlg);
            end
            
        end %function
        
        
        function onMinimizeGeneralSettings(app,~,~)
            
            % Toggle the minimization of this panel
            app.h.TopLeftBoxPanel.Minimized = ~app.h.TopLeftBoxPanel.Minimized;
            
            % Update the display
            updateLeftLayoutSizes(app);  
            
            % Invoke resize to adjust according to view
            onResize(app,[],[]);
            
        end %function
        
        
        function onRefreshViewer(app,~,~)
            
            % Mark as dirty
            app.IsDirty = true;
            
            % Refresh the app
            refresh(app);
            
        end %function
        
        
        function onResize(app,~,~)
            
            figurePos = get(app.Figure, 'Position');
            
            % Get width
            leftMainPanelPos = get(app.h.LeftMainPanel,'Position');
            leftPanelPos = get(app.h.LeftPanel,'Position');
            leftPanelPos(3) = leftMainPanelPos(3);
            set(app.h.LeftPanel,'Position',leftPanelPos);
            
            % make the scroller the same height as the figure
            scrollerPos = get(app.h.LeftSlider, 'Position');
            scrollerPos(2) = 1;
            scrollerPos(4) = figurePos(4); % - 2;
            set(app.h.LeftSlider, 'Position', scrollerPos);
            
            % decide whether the scroller needs to be active or not
            inputsPos = get(app.h.LeftPanel, 'Position');
            if inputsPos(4) > (figurePos(4))% - 2)
                % calculate a scroll step based on pct not visible here
                set(app.h.LeftSlider,'Visible','on');
                set(app.h.LeftSlider,'Value', 1.0 ); % top of panel visible
                pctVisible = figurePos(4) / inputsPos(4);
                minorStep = min (0.20, pctVisible);
                majorStep = max (1.00, 2.0 * pctVisible);
                set(app.h.LeftSlider,'SliderStep', [minorStep, majorStep]);
                if inputsPos(3) > scrollerPos(3)
                    inputsPos(1) = scrollerPos(3) + 1;
                    inputsPos(3) = inputsPos(3) - scrollerPos(3);
                end
            else
                set(app.h.LeftSlider,'Visible','off');  
                inputsPos(1) = scrollerPos(1);
                inputsPos(3) = scrollerPos(3) + scrollerPos(1) + inputsPos(3);
                inputsPos(3) = inputsPos(3) - 20;
            end
            inputsPos(2) = figurePos(4) - (inputsPos(4));
            set(app.h.LeftPanel,'Position',inputsPos);
            
            % Check left-hand size
            if inputsPos(3) < 475
                minimizeParameterView(app.h.SimulationPanel);
                minimizeParameterView(app.h.PopulationPanel);
            else
                maximizeParameterView(app.h.SimulationPanel);
                maximizeParameterView(app.h.PopulationPanel);
            end
            
        end %function
        
        
        function onScroll(app,~,~)
            
            updateScrollPanelPosition(app);
            
        end %function
        
        
        function mouseWheelCallback(app,~,evt)
            
            % Calculate new slider position
            sliderStep = get(app.h.LeftSlider,'SliderStep');
            currVal = get(app.h.LeftSlider,'Value');
            
            newVal = currVal - evt.VerticalScrollCount*sliderStep(1);
            if newVal < 0
                newVal = 0;
            elseif newVal > 1
                newVal = 1;
            end
            
            % Update slider
            set(app.h.LeftSlider,'Value',newVal);
            
            % Update scroll panel
            updateScrollPanelPosition(app);
            
        end %function
        
        
        function updateScrollPanelPosition(app)
            if strcmpi(get(app.h.LeftSlider,'Visible'),'on')
                figurePos = get(ancestor(app.h.LeftSlider,'Figure'), 'Position');
                figureHeight = figurePos(4) - 4;
                pnlPos = get(app.h.LeftPanel, 'Position');
                pnlHeight = pnlPos(4);
                sliderPos = get(app.h.LeftSlider,'Value');
                
                pnlPos(2) = 1 - sliderPos * (pnlHeight - figureHeight);
                
                set(app.h.LeftPanel,'Position', pnlPos);
                drawnow
            end
        end %function
    end %methods
    
    
    %% Get methods
    methods

        function value = get.LastPath(app)
            % If the LastPath doesn't exist, update it
            if ~exist(app.LastPath,'dir')
                app.LastPath = pwd;
            end
            value = app.LastPath;
        end %function
        
        function value = get.FileName(app)
            if exist(app.FilePath,'file')
                [~,value,ext] = fileparts(app.FilePath);
                value = [value,ext];
            else
                value = 'untitled';
            end
        end
        
        function value = get.TitleStr(app)
            if app.IsDirty
                value = sprintf('%s %s - %s *', app.Name, ...
                    app.Revision, app.FileName);
            else
                value = sprintf('%s %s - %s', app.Name, ...
                    app.Revision, app.FileName);
            end
        end
        
        function value = get.Position(app)
            % Get the property from the figure
            value = get(app.Figure,'Position');
        end
        
    end %methods
    
    
    %% Set methods
    methods
        
        function set.Position(app,value)
            validateattributes(value,{'numeric'},...
                {'finite','nonnan','size',[1 4]});
            % Set the property in the HG panel
            set(app.Figure,'Position',value)
        end
        
    end %methods
    
    
end %classdef